import datetime
import os
import uuid
from typing import Optional, Tuple

import redis.asyncio as redis
from dotenv import load_dotenv
from google_maps import get_directions, get_full_trip_route
from models import (
    DriverAvailability,
    RideLocation,
    RideJoinRequest,
    RideStatus,
)
from motor.motor_asyncio import AsyncIOMotorClient

load_dotenv()

MONGO_URL = os.environ.get("MONGODB_URL")
REDIS_HOST = os.environ.get("REDIS_HOST")

# INICJALIZACJA KLIENTÓW
mongo_client = AsyncIOMotorClient(MONGO_URL)
db = mongo_client.rides_db
redis_client = redis.Redis(host=REDIS_HOST, port=6379, db=0, decode_responses=True)


async def check_database_health() -> bool:
    """Sprawdza status połączenia z Redis i MongoDB."""
    try:
        await redis_client.ping()
        await mongo_client.admin.command("ping")
        return True
    except Exception:
        return False


# FUNKCJE LOGIKI BIZNESOWEJ

async def join_ride(data: RideJoinRequest):
    driver_id = data.driver_id

    driver_coords = await _get_driver_coords(driver_id)
    status, ride_id = await _get_driver_status(driver_id)

    # 1. Kierowca dostępny - nowy przejazd
    if status == RideStatus.AVAILABLE:
        return await _handle_new_ride_creation(data, driver_coords)

    # 2. Kierowca w trasie - dosiadka
    if status == RideStatus.ACTIVE and ride_id:
        return await _handle_shared_ride_join(data, ride_id, driver_coords)

    # 3. Brak dostępności
    raise ValueError("Driver is not available.")


async def update_ride_location(ride_id: str, location: RideLocation) -> None:
    """
    Aktualizuje bieżącą pozycję GPS w Redis.
    """
    ride_key = f"ride:{ride_id}"
    driver_id = await redis_client.hget(ride_key, "driver_id")
    driver_key = f"driver_status:{driver_id}"
    current_time = datetime.datetime.now(datetime.timezone.utc)

    await redis_client.hset(
        ride_key,
        mapping={
            "lat": location.lat,
            "lng": location.lng,
            "last_update": int(current_time.timestamp()),
        }
    )

    await redis_client.hset(
        driver_key,
        mapping={
            "lat": location.lat,
            "lng": location.lng,
            "last_update": int(current_time.timestamp()),
        }
    )

    await redis_client.geoadd(
        "drivers_locations",
        [location.lng, location.lat, str(driver_id)]
    )


async def get_ride_location_and_polyline(ride_id: str):
    """
    Odczytuje bieżącą pozycję GPS oraz zapisaną polilinię trasy z Redis.
    """
    redis_key = f"ride:{ride_id}"

    # Pobieramy wszystkie interesujące nas pola
    data = await redis_client.hmget(
        redis_key,
        ["lat", "lng", "polyline"]
    )

    if not data or data[0] is None:
        return None

    print(data)
    lat, lng, polyline = float(data[0]), float(data[1]), data[2]

    return lat, lng, polyline


async def mark_passenger_as_picked_up(ride_id: str, passenger_id: str):
    """
    Aktualizuje status pasażera. Rzuca ValueError jeżeli przejazd nie istnieje albo dany pasażer nie jest w nim zawarty.
    """
    result = await db.rides.update_one(
        {"_id": ride_id, "passengers.passenger_id": passenger_id},
        {"$set": {
            "passengers.$.picked_up": True,
            "updated_at": datetime.datetime.now(datetime.timezone.utc)
        }}
    )

    if result.matched_count == 0:
        raise ValueError(
            f"Brak przejazdu {ride_id} z pasażerem {passenger_id}"
        )
    return True


async def mark_passenger_as_dropped_out(ride_id: str, passenger_id: str):
    """
    Aktualizuje status pasażera. Rzuca ValueError jeżeli przejazd nie istnieje albo dany pasażer nie jest w nim zawarty.
    """
    result = await db.rides.update_one(
        {"_id": ride_id, "passengers.passenger_id": passenger_id},
        {
            "$pull": {
                "passengers": {"passenger_id": passenger_id}
            },
            "$set": {
                "updated_at": datetime.datetime.now(datetime.timezone.utc)
            }
        }
    )

    if result.matched_count == 0:
        raise ValueError(
            f"Brak przejazdu {ride_id} z pasażerem {passenger_id}"
        )
    return True


async def set_driver_available(availability_data: DriverAvailability) -> None:
    """
    Ustawia status kierowcy na AVAILABLE.
    - Zapisuje pozycję do GeoSetu w Redis.
    - Utrzymuje status kierowcy w kluczu driver_status w Redis.
    """
    driver_id = availability_data.driver_id
    current_time = datetime.datetime.now(datetime.timezone.utc)

    # Inicjalizacja/Aktualizacja stanu w Redis GeoSet
    # Używamy GeoSet 'available_drivers' do szybkiego wyszukiwania w promieniu
    await redis_client.geoadd(
        "drivers_locations",
        [availability_data.lng, availability_data.lat, str(driver_id)]
    )

    # Utrzymanie stanu w Redisie (Status i czas ostatniej aktywności)
    redis_key = f"driver_status:{driver_id}"
    await redis_client.hset(
        redis_key,
        mapping={
            "status": RideStatus.AVAILABLE.value,
            "lat": availability_data.lat,
            "lng": availability_data.lng,
            "last_update": int(current_time.timestamp()),
        },
    )


async def remove_driver_availability(driver_id: str) -> None:
    """
    Usuwa kierowcę z puli dostępności, gdy się wylogowuje/kończy pracę.
    """

    # TODO: Weryfikacja zakonczenia wszystkich przejazdow

    # Usunięcie z GeoSetu 'drivers_locations'
    await redis_client.zrem("drivers_locations", str(driver_id))

    # Usunięcie klucza statusu/sesji dostępności
    await redis_client.delete(f"driver_status:{driver_id}")


async def get_driver_rides(driver_id: str, status: str | None = None):
    query: dict = {"driver_id": driver_id}

    if status:
        query.update({"status": status})

    cursor = db.rides.find(query)
    rides = await cursor.to_list(length=None)

    print(rides)

    return rides


async def update_ride_status(ride_id: str, driver_id: str, new_status: RideStatus) -> str:
    current_time = datetime.datetime.now(datetime.timezone.utc)

    # TODO: Weryfikacja w postaci state machine

    # Aktualizacja w MongoDB
    result = await db.rides.update_one(
        {"_id": ride_id},
        {"$set": {"status": new_status.value, "updated_at": current_time}},
    )
    if result.matched_count == 0:
        raise ValueError("Przejazd nie znaleziony w MongoDB.")

    # Aktualizacja w Redis
    redis_key = f"ride:{ride_id}"
    await redis_client.hset(
        redis_key,
        mapping={
            "status": new_status.value,
            "last_update": int(current_time.timestamp()),
        },
    )

    if new_status in [RideStatus.ACTIVE, RideStatus.PENDING]:
        # Aktualizacja statusu kierowcy
        await redis_client.hset(
            f"driver_status:{driver_id}",
            mapping={
                "status": new_status.value,
                "current_ride": ride_id,
                "last_update": int(current_time.timestamp()),
            },
        )

    # Czyszczenie klucza, można ewentualnie dodać zapis historiczny do MongoDB
    if new_status in [RideStatus.COMPLETED, RideStatus.CANCELLED]:
        # Usunięcie wpisu o trasie w Redis
        await redis_client.delete(redis_key)

        # Aktualizacja statusu kierowcy
        await redis_client.hset(
            f"driver_status:{driver_id}",
            mapping={
                "status": new_status.value,
                "last_update": int(current_time.timestamp()),
            },
        )

    return new_status.value


# FUNKCJE POMOCNICZE


async def _handle_new_ride_creation(data: RideJoinRequest, start_coords: Tuple[float, float]):
    """Tworzy dokument w Mongo i aktualizuje Redis, wykorzystując optymalizację trasy."""
    current_time = datetime.datetime.now(datetime.timezone.utc)

    driver_lat, driver_lng = start_coords
    deadline = data.dropoff_deadline

    passengers = [{
        "p_lat": data.pickup_lat,
        "p_lng": data.pickup_lng,
        "d_lat": data.dropoff_lat,
        "d_lng": data.dropoff_lng,
        "picked_up": False,
        "deadline": deadline
    }]

    # Obliczamy optymalną trasę (Kierowca -> Pickup -> Dropoff)
    route_data = await get_full_trip_route(
        driver_lat=driver_lat,
        driver_lng=driver_lng,
        active_passengers=passengers
    )

    if not route_data:
        raise RuntimeError("Błąd podczas wyznaczania trasy przez silnik optymalizacji.")

    # Pełny zapis do MongoDB
    ride_id = str(uuid.uuid4())
    new_ride = {
        "_id": ride_id,
        "driver_id": data.driver_id,
        "status": RideStatus.PENDING.value,
        "passengers": [{
            "passenger_id": data.passenger_id,
            "pickup": {"lat": data.pickup_lat, "lng": data.pickup_lng},
            "dropoff": {"lat": data.dropoff_lat, "lng": data.dropoff_lng},
            "picked_up": False,
            "deadline": deadline
        }],
        "route_data": route_data,
        "created_at": current_time,
        "updated_at": current_time,
    }

    await db.rides.insert_one(new_ride)

    # Zapis stanu do Redis
    redis_key = f"ride:{ride_id}"
    await redis_client.hset(
        redis_key,
        mapping={
            "status": RideStatus.PENDING.value,
            "lat": driver_lat,
            "lng": driver_lng,
            "driver_id": data.driver_id,
            "polyline": route_data["polyline"],
            "last_update": int(current_time.timestamp()),
        },
    )

    # Synchronizacja statusu w bazie
    await update_ride_status(ride_id, data.driver_id, RideStatus.PENDING)

    return {
        "ride_id": ride_id,
        "driver_id": data.driver_id,
        "status": RideStatus.PENDING.value
    }


async def _get_driver_coords(driver_id_str: str) -> Optional[Tuple[float, float]]:
    coords = await redis_client.geopos("drivers_locations", driver_id_str)

    if coords and coords[0]:
        lng, lat = coords[0]
        # Mapujemy kolejność Redisa na standardową
        return lat, lng
    return None


async def _get_driver_status(driver_id: str) -> Tuple[RideStatus, Optional[str]]:
    """Zwraca status kierowcy i id ewentualnego przejazdu."""
    status_data = await redis_client.hgetall(f"driver_status:{driver_id}")
    status_str = status_data.get("status")
    if status_str:
        try:
            status = RideStatus(status_str)
        except ValueError:
            return None, status_data.get("current_ride")
        return status, status_data.get("current_ride")
    return None, status_data.get("current_ride")


async def _handle_shared_ride_join(data: RideJoinRequest, ride_id: str, driver_coords: Optional[Tuple[float, float]]):
    """Dodaje pasażera do istniejącego przejazdu współdzielonego."""
    current_time = datetime.datetime.now(datetime.timezone.utc)
    
    # Pobierz istniejący przejazd
    existing_ride = await db.rides.find_one({"_id": ride_id})
    if not existing_ride:
        raise ValueError("Przejazd nie znaleziony w MongoDB.")
    
    # Sprawdź liczbę pasażerów (max 4)
    current_passengers = existing_ride.get("passengers", [])
    if len(current_passengers) >= 4:
        raise ValueError("Przejazd jest już pełny (maksymalnie 4 pasażerów).")
    
    # Sprawdź czy pasażer już nie jest w przejeździe
    for passenger in current_passengers:
        if passenger.get("passenger_id") == data.passenger_id:
            raise ValueError("Pasażer już jest w tym przejeździe.")
    
    # Pobierz aktualną pozycję kierowcy z Redis lub użyj driver_coords
    if not driver_coords:
        ride_redis = await redis_client.hgetall(f"ride:{ride_id}")
        if ride_redis:
            driver_coords = (float(ride_redis.get("lat", 0)), float(ride_redis.get("lng", 0)))
        else:
            raise ValueError("Nie można określić pozycji kierowcy.")
    
    driver_lat, driver_lng = driver_coords
    deadline = data.dropoff_deadline

    # Przygotuj listę wszystkich pasażerów (istniejących + nowy)
    all_passengers = current_passengers + [{
        "passenger_id": data.passenger_id,
        "pickup": {"lat": data.pickup_lat, "lng": data.pickup_lng},
        "dropoff": {"lat": data.dropoff_lat, "lng": data.dropoff_lng},
        "deadline": deadline,
        "picked_up": False
    }]
    
    # Przygotuj dane dla get_full_trip_route
    active_passengers = []
    for p in all_passengers:
        pickup = p.get("pickup", {})
        dropoff = p.get("dropoff", {})
        is_picked_up = p.get("picked_up", False)
        active_passengers.append({
            "p_lat": pickup.get("lat"),
            "p_lng": pickup.get("lng"),
            "d_lat": dropoff.get("lat"),
            "d_lng": dropoff.get("lng"),
            "picked_up": is_picked_up,
            "deadline": p.get("deadline")
        })
    
    # Oblicz nową trasę uwzględniającą wszystkich pasażerów
    new_route_data = await get_full_trip_route(
        driver_lat=driver_lat,
        driver_lng=driver_lng,
        active_passengers=active_passengers
    )

    if not new_route_data:
        raise RuntimeError("Błąd podczas wyznaczania trasy przez Google API.")
    
    # Zaktualizuj przejazd w MongoDB - dodaj nowego pasażera i zaktualizuj trasę
    await db.rides.update_one(
        {"_id": ride_id},
        {
            "$push": {"passengers": {
                "passenger_id": data.passenger_id,
                "pickup": {"lat": data.pickup_lat, "lng": data.pickup_lng},
                "dropoff": {"lat": data.dropoff_lat, "lng": data.dropoff_lng},
                "picked_up": False,
                "deadline": deadline
            }},
            "$set": {
                "route_data": new_route_data,
                "updated_at": current_time
            }
        }
    )

    # Zaktualizuj polyline w Redis
    await redis_client.hset(
        f"ride:{ride_id}",
        mapping={
            "polyline": new_route_data["polyline"],
            "last_update": int(current_time.timestamp())
        }
    )

    return {
        "ride_id": ride_id,
        "driver_id": data.driver_id,
        "status": existing_ride.get("status", RideStatus.ACTIVE.value)
    }


async def recalculate_and_update_route(ride_id: str = None):
    """
    Przelicza trasę dla trwającego przejazdu i aktualizuje Redis oraz MongoDB.
    """
    current_time = datetime.datetime.now(datetime.timezone.utc)

    ride = await db.rides.find_one({"_id": ride_id})
    driver_id = ride.get("driver_id")
    driver_lat, driver_lng = await _get_driver_coords(driver_id_str=driver_id)

    passengers = ride.get("passengers", [])

    # Sprawdzenie, czy są jeszcze jacyś pasażerowie do obsłużenia
    if not passengers:
        print(f"Przejazd {ride_id}: Brak pasażerów, czyszczenie trasy w Redis")

        # Zapis trasy jako ukończonej w MongoDB
        await db.rides.update_one(
            {"_id": ride_id},
            {
                "$set": {
                    "status": RideStatus.COMPLETED.value,
                    "route_data": None,
                    "updated_at": current_time
                }
            }
        )

        # Usunięcie trasy z Redis
        await redis_client.delete(f"ride:{ride_id}")

        # Zaktualizowanie statusu kierowcy
        if driver_id:
            await redis_client.hset(
                f"driver_status:{driver_id}",
                mapping={
                    "status": RideStatus.COMPLETED.value,
                    "lat": driver_lat,
                    "lng": driver_lng,
                    "last_update": int(current_time.timestamp()),
                }
            )
        return


    # Przygotowanie danych pasażerów dla OR-Tools
    active_passengers_for_optimizer = []

    for p in passengers:
        # Mapowanie struktury z Mongo na strukturę dla solve_optimal_order
        active_passengers_for_optimizer.append({
            "passenger_id": p["passenger_id"],
            "p_lat": p["pickup"]["lat"],
            "p_lng": p["pickup"]["lng"],
            "d_lat": p["dropoff"]["lat"],
            "d_lng": p["dropoff"]["lng"],
            "picked_up": p.get("picked_up", False),
            "deadline": p["deadline"]
        })

    # Rekalkulacja trasy
    new_route_data = await get_full_trip_route(
        driver_lat=driver_lat,
        driver_lng=driver_lng,
        active_passengers=active_passengers_for_optimizer,
        recalculation=True
    )

    if not new_route_data:
        print(f"Nie udało się przeliczyć trasy dla {ride_id}")
        return

    # Aktualizacja MongoDB
    await db.rides.update_one(
        {"_id": ride_id},
        {
            "$set": {
                "route_data": new_route_data,
                "updated_at": current_time
            }
        }
    )

    # Aktualizacja Redis
    await redis_client.hset(
        f"ride:{ride_id}",
        mapping={
            "polyline": new_route_data["polyline"],
            "last_update": int(current_time.timestamp())
        }
    )

    print(f"Trasa przejazdu {ride_id} została zaktualizowana.")
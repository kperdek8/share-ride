import datetime
import os
import uuid
from typing import Optional, Tuple

import redis.asyncio as redis
from dotenv import load_dotenv
from google_maps import get_directions
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


# FUNKCJE LOGIKI BIZNESOWEJ
async def check_database_health() -> bool:
    """Sprawdza status połączenia z Redis i MongoDB."""
    try:
        await redis_client.ping()
        await mongo_client.admin.command("ping")
        return True
    except Exception:
        return False


async def join_ride(data: RideJoinRequest):
    driver_id_str = str(data.driver_id)

    # 1. Próba rezerwacji (Nowy Przejazd)
    driver_coords = await _reserve_available_driver(driver_id_str)
    if driver_coords:
        return await _handle_new_ride_creation(data, driver_coords)

    # 2. Sprawdzenie istniejącego przejazdu (Shared Ride)
    active_ride_id = await _get_active_ride_id(data.driver_id)
    if active_ride_id:
        # Rzucamy standardowy błąd, który endpoint wyłapie
        raise NotImplementedError("Shared rides are not supported yet.")

    # 3. Brak dostępności
    raise ValueError("Driver is not available.")


async def update_ride_location(ride_id: str, location: RideLocation) -> None:
    """
    Aktualizuje bieżącą pozycję GPS w Redis.
    """
    redis_key = f"ride:{ride_id}"
    current_time = datetime.datetime.now(datetime.timezone.utc)

    await redis_client.hset(
        redis_key,
        mapping={
            "lat": location.lat,
            "lng": location.lng,
            "last_update": int(current_time.timestamp()),
        },
    )


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
        "available_drivers",
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

    # Usunięcie z GeoSetu 'available_drivers'
    await redis_client.zrem("available_drivers", str(driver_id))

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

# FUNKCJE POMOCNICZE


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

    # TODO: Rozdzielic ACTIVE (akceptacja przez kierowce) i PENDING (wybranie kierowcy przez pasażera)
    if new_status in [RideStatus.ACTIVE, RideStatus.PENDING]:
        # Usunięcie kierowcy z GeoSetu 'available_drivers'
        await redis_client.zrem("available_drivers", driver_id)

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


async def _handle_new_ride_creation(data: RideJoinRequest, start_coords):
    """Tworzy dokument w Mongo i aktualizuje Redis."""
    current_time = datetime.datetime.now(datetime.timezone.utc)

    driver_lat = start_coords[0]
    driver_lng = start_coords[1]

    route_data = await get_directions(
        origin_lat=driver_lat,
        origin_lng=driver_lng,
        dest_lat=data.dropoff_lat,
        dest_lng=data.dropoff_lng,
        waypoints=[(data.pickup_lat, data.pickup_lng)]
    )

    if not route_data:
        # Rollback
        await redis_client.geoadd("available_drivers", [start_coords[0], start_coords[1], data.driver_id])
        raise RuntimeError("Błąd podczas wyznaczania trasy przez Google API.")

    # Pełny zapis do MongoDB
    ride_id = str(uuid.uuid4())
    new_ride = {
        "_id": ride_id,
        "driver_id": data.driver_id,
        "status": RideStatus.PENDING.value,
        "passengers": [{
            "passenger_id": data.passenger_id,
            "pickup": {"lat": data.pickup_lat, "lng": data.pickup_lng},
            "dropoff": {"lat": data.dropoff_lat, "lng": data.dropoff_lng}
        }],
        "route_data": route_data,
        "created_at": current_time,
        "updated_at": current_time,
    }

    await db.rides.insert_one(new_ride)

    # Zapis obecnej pozycji przejazdu do Redis
    redis_key = f"ride:{ride_id}"
    await redis_client.hset(
        redis_key,
        mapping={
            "status": RideStatus.PENDING.value,
            "lat": start_coords[0],
            "lng": start_coords[1],
            "driver_id": data.driver_id,
            "last_update": int(current_time.timestamp()),
        },
    )

    # Synchronizacja wpisow w bazie
    await update_ride_status(ride_id, data.driver_id, RideStatus.PENDING)

    return {
        "ride_id": ride_id,
        "driver_id": data.driver_id,
        "status": RideStatus.PENDING.value
    }


async def _reserve_available_driver(driver_id_str: str) -> Optional[Tuple[float, float]]:
    """Próbuje zarezerwować kierowcę. Zwraca współrzędne lub None."""
    coords = await redis_client.geopos("available_drivers", driver_id_str)
    removed = await redis_client.zrem("available_drivers", driver_id_str)

    if removed and coords and coords[0]:
        lng, lat = coords[0]
        # Mapujemy kolejność Redisa na naszą standardową
        return lat, lng
    return None


async def _get_active_ride_id(driver_id: str) -> Optional[str]:
    """Sprawdza, czy kierowca ma już aktywny przejazd."""
    status_data = await redis_client.hgetall(f"driver_status:{driver_id}")
    if status_data.get("status") in [RideStatus.PENDING.value, RideStatus.ACTIVE.value]:
        return status_data.get("current_ride")
    return None

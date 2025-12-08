import datetime
import os
import uuid

import redis.asyncio as redis
from dotenv import load_dotenv
from models import (
    DriverAvailability,
    RideCreate,
    RideLocation,
    RideRouteUpdate,
    RideStatus,
    RideStatusUpdate,
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


async def create_new_ride(ride_data: RideCreate) -> str:
    ride_id = str(uuid.uuid4())
    current_time = datetime.datetime.now(datetime.timezone.utc)

    # Zapis do MongoDB
    ride_document = ride_data.model_dump()
    ride_document["_id"] = ride_id
    ride_document["current_status"] = "pending"
    ride_document["waypoints"] = []
    ride_document["created_at"] = current_time
    ride_document["updated_at"] = current_time

    await db.rides.insert_one(ride_document)

    # Inicjalizacja w Redis
    redis_key = f"ride:{ride_id}"
    await redis_client.hset(
        redis_key,
        mapping={
            "status": "pending",
            "lat": ride_data.start_lat,
            "lng": ride_data.start_lng,
            "driver_id": ride_data.driver_id,
            "last_update": int(current_time.timestamp()),
        },
    )

    return ride_id


async def update_ride_status(ride_id: str, status_update: RideStatusUpdate) -> str:
    new_status = status_update.new_status
    driver_id = status_update.driver_id
    current_time = datetime.datetime.now(datetime.timezone.utc)

    # TODO: Weryfikacja w postaci state machine weryfikujaca

    # Aktualizacja w MongoDB
    result = await db.rides.update_one(
        {"_id": ride_id},
        {"$set": {"current_status": new_status.value, "updated_at": current_time}},
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

    if new_status == RideStatus.ACTIVE:
        # Usunięcie kierowcy z GeoSetu 'available_drivers'
        await redis_client.zrem("available_drivers", str(driver_id))

        # Aktualizacja statusu kierowcy
        await redis_client.hset(
            f"driver_status:{driver_id}",
            mapping={
                "status": new_status.value,
                "last_update": int(current_time.timestamp()),
            },
        )

    # Czyszczenie klucza, można ewentualnie dodać zapis historiczny do MongoDB
    if new_status in [RideStatus.COMPLETED, RideStatus.CANCELLED]:
        await redis_client.delete(redis_key)

    return new_status.value


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


async def update_ride_route(data: RideRouteUpdate) -> None:
    """
    Aktualizuje polyline istniejącego przejazdu w MongoDB.
    """
    current_time = datetime.datetime.now(datetime.timezone.utc)

    result = await db.rides.update_one(
        {"_id": data.ride_id},
        {
            "$set": {
                "polyline": data.polyline,
                "updated_at": current_time,
            }
        },
    )

    if result.matched_count == 0:
        raise ValueError("Przejazd nie znaleziony.")


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
        availability_data.current_lng,
        availability_data.current_lat,
        str(driver_id),
    )

    # Utrzymanie stanu w Redisie (Status i czas ostatniej aktywności)
    redis_key = f"driver_status:{driver_id}"
    await redis_client.hset(
        redis_key,
        mapping={
            "status": RideStatus.AVAILABLE.value,
            "lat": availability_data.current_lat,
            "lng": availability_data.current_lng,
            "last_update": int(current_time.timestamp()),
        },
    )


async def remove_driver_availability(driver_id: int) -> None:
    """
    Usuwa kierowcę z puli dostępności, gdy się wylogowuje/kończy pracę.
    """

    # TODO: Weryfikacja zakonczenia wszystkich przejazdow

    # Usunięcie z GeoSetu 'available_drivers'
    await redis_client.zrem("available_drivers", str(driver_id))

    # Usunięcie klucza statusu/sesji dostępności
    await redis_client.delete(f"driver_status:{driver_id}")


async def get_driver_rides(driver_id: int, status: str | None = None):
    query: dict = {"driver_id": driver_id}

    if status:
        query.update({"current_status": status})

    cursor = db.rides.find(query)
    rides = await cursor.to_list(length=None)

    return rides

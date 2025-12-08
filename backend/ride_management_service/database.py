import datetime
import os
from motor.motor_asyncio import AsyncIOMotorClient
import redis.asyncio as redis
import uuid
from models import RideCreate, RideStatusUpdate, RideLocation
from dotenv import load_dotenv

load_dotenv()

MONGO_URL = os.environ.get("MONGODB_URL")
REDIS_HOST = os.environ.get("REDIS_HOST")

# INICJALIZACJA KLIENTÓW
mongo_client = AsyncIOMotorClient(MONGO_URL)
db = mongo_client.rides_db
redis_client = redis.Redis(host=REDIS_HOST, port=6379, db=0)

# FUNKCJE LOGIKI BIZNESOWEJ
async def check_database_health() -> bool:
    """Sprawdza status połączenia z Redis i MongoDB."""
    try:
        await redis_client.ping()
        await mongo_client.admin.command('ping')
        return True
    except Exception:
        return False


async def create_new_ride(ride_data: RideCreate) -> str:
    ride_id = str(uuid.uuid4())
    current_time = datetime.datetime.now(datetime.timezone.utc)

    # Zapis do MongoDB (Używaj obiektu datetime!)
    ride_document = ride_data.model_dump()
    ride_document["_id"] = ride_id
    ride_document["current_status"] = "pending"
    ride_document["waypoints"] = []
    ride_document["created_at"] = current_time  # Używaj obiektu datetime
    ride_document["updated_at"] = current_time  # Używaj obiektu datetime

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
            "last_update": int(current_time.timestamp())
        }
    )

    return ride_id


async def update_ride_status(ride_id: str, status_update: RideStatusUpdate) -> str:
    new_status = status_update.new_status
    current_time = datetime.datetime.now(datetime.timezone.utc)

    # Aktualizacja w MongoDB
    result = await db.rides.update_one(
        {"_id": ride_id},
        # POPRAWKA: Używaj obiektu datetime
        {"$set": {"current_status": new_status, "updated_at": current_time}}
    )
    if result.matched_count == 0:
        raise ValueError("Przejazd nie znaleziony w MongoDB.")

    # Aktualizacja w Redis
    redis_key = f"ride:{ride_id}"
    await redis_client.hset(
        redis_key,
        mapping={
            "status": new_status,
            "last_update": int(current_time.timestamp())
        }
    )

    return new_status


async def update_ride_location(ride_id: str, location: RideLocation) -> None:
    """
    Aktualizuje bieżącą pozycję GPS w Redis.
    """
    redis_key = f"ride:{ride_id}"

    await redis_client.hset(
        redis_key,
        mapping={
            "lat": location.lat,
            "lng": location.lng,
            "last_update": location.timestamp
        }
    )

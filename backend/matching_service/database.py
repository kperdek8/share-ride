import os
import redis.asyncio as redis
from dotenv import load_dotenv
from typing import List, Tuple, Optional
from models import RideStatus
from motor.motor_asyncio import AsyncIOMotorClient


load_dotenv()
REDIS_HOST = os.environ.get("REDIS_HOST")
MONGO_URL = os.environ.get("MONGODB_URL")

# INICJALIZACJA KLIENTÓW
redis_client = redis.Redis(host=REDIS_HOST, port=6379, db=0, decode_responses=True)
mongo_client = AsyncIOMotorClient(MONGO_URL) if MONGO_URL else None
if mongo_client:
    db = mongo_client.rides_db
    print(f"MongoDB połączone: {MONGO_URL}, baza: rides_db")
else:
    db = None
    print(f"Brak połączenia z MongoDB - MONGO_URL: {MONGO_URL}")


async def check_database_health() -> bool:
    """Sprawdza status połączenia z Redis i MongoDB."""
    try:
        await redis_client.ping()
        if mongo_client is not None:
            await mongo_client.admin.command('ping')
        return True
    except Exception:
        return False


async def get_ride_passenger_count(ride_id: str) -> int:
    """Zwraca liczbę pasażerów w przejeździe."""
    if db is None:
        print(f"Brak połączenia z MongoDB - nie można pobrać liczby pasażerów dla {ride_id}")
        return 0
    try:
        print(f"Pobieranie liczby pasażerów dla ride_id: {ride_id}")
        ride = await db.rides.find_one({"_id": ride_id})
        if ride:
            passengers = ride.get("passengers", [])
            count = len(passengers)
            print(f"Znaleziono przejazd {ride_id} z {count} pasażerami")
            return count
        else:
            print(f"Przejazd {ride_id} nie znaleziony w MongoDB")
            return 0
    except Exception as e:
        print(f"Błąd pobierania liczby pasażerów dla {ride_id}: {e}")
        import traceback
        traceback.print_exc()
        return 0


# FUNKCJE LOGIKI BIZNESOWEJ


async def get_nearby_drivers_from_redis(lat: float, lng: float, radius: float) -> List[Tuple[str, Tuple[float, float]]]:
    """
    Pobiera kierowców z GeoSetu 'drivers_locations' w zadanym promieniu.
    Zwraca listę krotek: (driver_id, (longitude, latitude))
    """
    try:
        # geosearch z withcoord=True zwraca listę list: [[member, (lng, lat)], ...]
        results = await redis_client.geosearch(
            "drivers_locations",
            longitude=lng,
            latitude=lat,
            radius=radius,
            unit="km",
            withcoord=True
        )
        # Konwertujemy na listę krotek dla łatwiejszego użycia
        drivers = []
        for result in results:
            if isinstance(result, list) and len(result) >= 2:
                driver_id = str(result[0])
                coords = result[1]
                if isinstance(coords, (list, tuple)) and len(coords) >= 2:
                    drivers.append((driver_id, (float(coords[0]), float(coords[1]))))
        return drivers
    except Exception as e:
        print(f"Błąd odczytu z Redis GeoSet: {e}")
        import traceback
        traceback.print_exc()
        return []


async def get_driver_status(driver_id: str) -> Tuple[Optional[RideStatus], Optional[str]]:
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
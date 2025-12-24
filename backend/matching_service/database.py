import os
import redis.asyncio as redis
from dotenv import load_dotenv
from typing import List, Tuple, Optional
from models import RideStatus


load_dotenv()
REDIS_HOST = os.environ.get("REDIS_HOST")

# INICJALIZACJA KLIENTÓW
redis_client = redis.Redis(host=REDIS_HOST, port=6379, db=0, decode_responses=True)


async def check_database_health() -> bool:
    """Sprawdza status połączenia z Redis i MongoDB."""
    try:
        await redis_client.ping()
        return True
    except Exception:
        return False


# FUNKCJE LOGIKI BIZNESOWEJ


async def get_nearby_drivers_from_redis(lat: float, lng: float, radius: float) -> List[Tuple[str, Tuple[float, float]]]:
    """
    Pobiera kierowców z GeoSetu 'available_drivers' w zadanym promieniu.
    Zwraca listę krotek: (driver_id, (longitude, latitude))
    """
    try:
        # Zwraca: [['driver_1', (lng, lat)], ['driver_2', (lng, lat)]]
        return await redis_client.geosearch(
            "drivers_locations",
            longitude=lng,
            latitude=lat,
            radius=radius,
            unit="km",
            withcoord=True
        )
    except Exception as e:
        print(f"Błąd odczytu z Redis GeoSet: {e}")
        return []


async def get_driver_status(driver_id: str) -> Tuple[RideStatus, Optional[str]]:
    """Zwraca status kierowcy i id ewentualnego przejazdu."""
    status_data = await redis_client.hgetall(f"driver_status:{driver_id}")
    return status_data.get("status"), status_data.get("current_ride")
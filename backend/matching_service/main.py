from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from typing import List

from models import RideSearchRequest, MatchingOffer, MessageResponse, RideStatus
from google_maps import get_directions
from database import check_database_health, redis_client, get_nearby_drivers_from_redis, get_driver_status, mongo_client, get_ride_passenger_count

app = FastAPI(
    title="ShareRide Matching Service",
    description="Usluga dopasowywania pasazerow z kierowcami",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DEFAULT_RADIUS_KM = 5.0  # Do dostosowania


@app.on_event("shutdown")
async def shutdown_event():
    await redis_client.aclose()
    if mongo_client:
        mongo_client.close()


@app.get("/", response_model=MessageResponse)
async def root():
    return {"message": "ShareRide Matching Service", "status": "running"}


@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    if await check_database_health():
        return {"status": "healthy", "database_status": "ok"}
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Usługa niedostępna. Bazy danych nie odpowiadają.",
    )


@app.post("/api/matching/offers", response_model=List[MatchingOffer])
async def find_ride_offers(request: RideSearchRequest):
    """
    Szuka dostępnych kierowców w stałym promieniu i sprawdza dojazd przez Google API.
    """
    try:
        # 1. Pobieramy kierowców z Redis GeoSet (pula 'available_drivers')
        # Szukamy wokół punktu odbioru pasażera
        nearby_drivers = await get_nearby_drivers_from_redis(
            request.pickup_lat,
            request.pickup_lng,
            DEFAULT_RADIUS_KM
        )

        if not nearby_drivers:
            return []

        offers = []

        # 2. Dla każdego kandydata sprawdzamy realny dojazd przez Google Routes API
        for driver_data in nearby_drivers:
            try:
                # geosearch zwraca tuple: (driver_id, (lng, lat))
                if isinstance(driver_data, tuple) and len(driver_data) >= 2:
                    driver_id = str(driver_data[0])
                    coords = driver_data[1]
                    if isinstance(coords, (list, tuple)) and len(coords) >= 2:
                        lng, lat = float(coords[0]), float(coords[1])
                    else:
                        print(f"Nieprawidłowa struktura współrzędnych: {coords}")
                        continue
                elif isinstance(driver_data, list) and len(driver_data) >= 2:
                    # Fallback dla przypadku gdy Redis zwraca listę
                    driver_id = str(driver_data[0])
                    coords = driver_data[1]
                    if isinstance(coords, (list, tuple)) and len(coords) >= 2:
                        lng, lat = float(coords[0]), float(coords[1])
                    else:
                        print(f"Nieprawidłowa struktura współrzędnych: {coords}")
                        continue
                else:
                    print(f"Nieprawidłowa struktura danych kierowcy: {driver_data}")
                    continue

                status, ride_id = await get_driver_status(driver_id)

                # Kierowca nie jest dostępny lub brak statusu
                if status is None or status not in [RideStatus.AVAILABLE, RideStatus.ACTIVE]:
                    continue

                # Kierowca dostępny - nowy przejazd (solo)
                if status == RideStatus.AVAILABLE:
                    directions = await get_directions(
                        origin_lat=lat, origin_lng=lng,
                        dest_lat=request.dropoff_lat, dest_lng=request.dropoff_lng,
                        waypoints=[(request.pickup_lat, request.pickup_lng)]
                    )

                    if directions and "pickup_eta_min" in directions:
                        offers.append(MatchingOffer(
                            driver_id=driver_id,
                            pickup_eta_minutes=directions.get("pickup_eta_min", 0),
                            total_eta_minutes=directions["duration_min"],
                            distance_km=directions["distance_km"],
                            polyline=directions["polyline"],
                            is_shared=False,
                            shared_passengers=0
                        ))
                
                # Kierowca w trasie - przejazd współdzielony
                elif status == RideStatus.ACTIVE and ride_id:
                    try:
                        passenger_count = await get_ride_passenger_count(ride_id)
                        
                        # Sprawdzamy czy kierowca może przyjąć kolejnego pasażera (max 4 pasażerów)
                        if passenger_count < 4:
                            directions = await get_directions(
                                origin_lat=lat, origin_lng=lng,
                                dest_lat=request.dropoff_lat, dest_lng=request.dropoff_lng,
                                waypoints=[(request.pickup_lat, request.pickup_lng)]
                            )

                            if directions and "pickup_eta_min" in directions:
                                # Dla przejazdów współdzielonych dodajemy 10% czasu na dodatkowe przystanki
                                extra_time = max(2, int(directions["duration_min"] * 0.1))
                                
                                offers.append(MatchingOffer(
                                    driver_id=driver_id,
                                    pickup_eta_minutes=directions.get("pickup_eta_min", 0),
                                    total_eta_minutes=directions["duration_min"] + extra_time,
                                    distance_km=directions["distance_km"],
                                    polyline=directions["polyline"],
                                    is_shared=True,
                                    shared_passengers=passenger_count + 1  # +1 dla nowego pasażera
                                ))
                    except Exception as e:
                        print(f"Błąd podczas przetwarzania przejazdu współdzielonego dla {driver_id}: {e}")
                        continue
            except Exception as e:
                print(f"Błąd podczas przetwarzania kierowcy: {e}")
                import traceback
                traceback.print_exc()
                continue

        # 3. Sortujemy od najbliższego (najniższy czas dojazdu)
        offers.sort(key=lambda x: x.total_eta_minutes)

        return offers[:5]
    except Exception as e:
        print(f"Błąd w find_ride_offers: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Błąd podczas wyszukiwania przejazdów: {str(e)}")

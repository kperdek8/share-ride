from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from typing import List

from models import RideSearchRequest, MatchingOffer, MessageResponse, RideStatus
from google_maps import get_directions
from database import check_database_health, redis_client, get_nearby_drivers_from_redis, get_driver_status

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
        driver_id, coords = driver_data
        lng, lat = coords

        status, ride_id = await get_driver_status(driver_id)

        # Kierowca nie jest dostępny
        if status not in [RideStatus.AVAILABLE, RideStatus.ACTIVE]:
            continue

        # Kierowca nie ma aktywnego przejazdu
        if status == RideStatus.AVAILABLE:
            directions = await get_directions(
                origin_lat=lat, origin_lng=lng,
                dest_lat=request.dropoff_lat, dest_lng=request.dropoff_lng,
                waypoints=[(request.pickup_lat, request.pickup_lng)]
            )

            if directions:
                offers.append(MatchingOffer(
                    driver_id=driver_id,
                    pickup_eta_minutes=directions["pickup_eta_min"],
                    total_eta_minutes=directions["duration_min"],
                    distance_km=directions["distance_km"],
                    polyline=directions["polyline"]
                ))

    # 3. Sortujemy od najbliższego (najniższy czas dojazdu)
    offers.sort(key=lambda x: x.total_eta_minutes)

    return offers[:5]

from database import (
    check_database_health,
    join_ride,
    get_driver_rides,
    mongo_client,  # Potrzebne do zamknięcia połączenia
    redis_client,  # Potrzebne do zamknięcia połączenia
    remove_driver_availability,
    set_driver_available,
    update_ride_location,
    update_ride_status, mark_passenger_as_picked_up, get_ride_location_and_polyline, mark_passenger_as_dropped_out, recalculate_and_update_route
)
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from models import (
    DriverAvailability,
    DriverRidesQuery,
    DriverRidesResponse,
    MessageResponse,
    RideDropoutUpdate,
    RideGetPositionResponse,
    RidePickupUpdate,
    RideJoinRequest,
    RideJoinResponse,
    RideLocation,
    RideStatusUpdate,

)

app = FastAPI(
    title="ShareRide Ride Management Service",
    description="Usluga zarzadzania przejazdami",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("shutdown")
async def shutdown_event():
    mongo_client.close()
    await redis_client.aclose()


@app.get("/", response_model=MessageResponse)
async def root():
    return {"message": "ShareRide Ride Management Service", "status": "running"}


@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    if await check_database_health():
        return {"status": "healthy", "database_status": "ok"}
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Usługa niedostępna. Bazy danych nie odpowiadają.",
    )


@app.post("/api/rides/join", response_model=RideJoinResponse)
async def join_ride_endpoint(request: RideJoinRequest):
    try:
        result = await join_ride(request)

        return RideJoinResponse(
            ride_id=result["ride_id"],
            driver_id=result["driver_id"],
            status=result["status"]
        )

    except ValueError as e:
        # Kierowca niedostępny
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

    except NotImplementedError as e:
        # Shared ride - jeszcze nie ma
        raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=str(e))

    except RuntimeError as e:
        # Błąd Google Maps / Bazy
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

    except Exception as e:
        # Wszystko inne
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="An unexpected error occurred.")


@app.patch("/api/rides/{ride_id}/status", response_model=MessageResponse)
async def update_ride_status_endpoint(ride_id: str, status_update: RideStatusUpdate):
    """Aktualizuje status przejazdu (np. active, completed, cancelled)."""
    try:
        new_status = await update_ride_status(ride_id, status_update.driver_id, status_update.new_status)
        return {
            "ride_id": ride_id,
            "message": f"Status zaktualizowany na: {new_status}",
        }
    except ValueError as e:
        # Przejazd nie znaleziony
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd aktualizacji statusu: {e}",
        )


@app.patch("/api/rides/{ride_id}/pickup", response_model=MessageResponse)
async def pickup_update_endpoint(ride_id: str, pickup_update: RidePickupUpdate):
    """Potwierdza odbiór pasażera"""
    try:
        await mark_passenger_as_picked_up(ride_id, pickup_update.passenger_id)
        await recalculate_and_update_route(ride_id)
        return {
            "ride_id": ride_id,
            "message": f"Potwierdzono odbiór pasażera: {pickup_update.passenger_id}",
        }
    except ValueError as e:
        # Przejazd nie znaleziony
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd przy potwierdzeniu odbioru pasażera: {e}",
        )


@app.patch("/api/rides/{ride_id}/drop", response_model=MessageResponse)
async def dropout_update_endpoint(ride_id: str, pickup_update: RideDropoutUpdate):
    """Potwierdza odbiór pasażera"""
    try:
        await mark_passenger_as_dropped_out(ride_id, pickup_update.passenger_id)
        await recalculate_and_update_route(ride_id)
        return {
            "ride_id": ride_id,
            "message": f"Potwierdzono wysadzenie pasażera: {pickup_update.passenger_id}",
        }
    except ValueError as e:
        # Przejazd nie znaleziony
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd przy potwierdzeniu wysadzenia pasażera: {e}",
        )


@app.get("/api/rides/{ride_id}/location", response_model=RideGetPositionResponse)
async def get_ride_location_endpoint(ride_id: str):
    """Pobiera bieżącą pozycję GPS i trasę z Redis."""
    try:
        lat, lng, polyline = await get_ride_location_and_polyline(ride_id)
        location = {
            "lat": lat,
            "lng": lng
        }
        return {"ride_id": ride_id, "location": location, "polyline": polyline}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd serwera: {e}",
        )


@app.patch("/api/rides/{ride_id}/location", response_model=MessageResponse)
async def update_ride_location_endpoint(ride_id: str, location: RideLocation):
    """Aktualizuje bieżącą pozycję GPS w Redis (wysoki wolumen zapisu)."""
    try:
        await update_ride_location(ride_id, location)
        return {"ride_id": ride_id, "message": "Lokalizacja zaktualizowana w Redis."}
    except Exception as e:
        # Błędy Redis są krytyczne dla tego endpointu
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd zapisu lokalizacji do Redis: {e}",
        )


@app.delete("/api/drivers/{driver_id}/available", response_model=MessageResponse)
async def remove_driver_availability_endpoint(driver_id: str):
    """
    Usuwa kierowcę z puli dostępności (wylogowanie, koniec pracy).
    """
    try:
        await remove_driver_availability(driver_id)
        return {"message": f"Kierowca {driver_id} usunięty z puli dostępnych."}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd usuwania dostępności: {e}",
        )


@app.post("/api/drivers/available", response_model=MessageResponse)
async def set_driver_available_endpoint(availability_data: DriverAvailability):
    """
    Pozwala nowemu kierowcy zgłosić gotowość do przyjęcia pierwszego zlecenia.
    Ustawia status na AVAILABLE i zapisuje pozycję do GeoSetu w Redis.
    """
    try:
        await set_driver_available(availability_data)
        return {"message": f"Kierowca {availability_data.driver_id} ustawiony jako dostepny."}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd ustawiania dostępności kierowcy: {e}",
        )


@app.get(
    "/api/drivers/rides",
    response_model=DriverRidesResponse,
    status_code=status.HTTP_200_OK,
)
async def get_driver_rides_endpoint(
    query: DriverRidesQuery = Depends(),
):
    """
    Pobiera przejazdy dla wskazanego kierowcy, z opcjonalnym filtrowaniem po statusie.
    """

    try:
        rides = await get_driver_rides(
            driver_id=query.driver_id,
            status=query.status.value if query.status else None,
        )

        return {
            "driver_id": query.driver_id,
            "rides": rides,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd pobierania przejazdów: {str(e)}",
        )

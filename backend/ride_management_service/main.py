from database import (
    check_database_health,
    create_new_ride,
    get_driver_rides,
    mongo_client,  # Potrzebne do zamknięcia połączenia
    redis_client,  # Potrzebne do zamknięcia połączenia
    remove_driver_availability,
    set_driver_available,
    update_ride_location,
    update_ride_route,
    update_ride_status,
)
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from models import (
    DriverAvailability,
    DriverRidesQuery,
    DriverRidesResponse,
    MessageResponse,
    RideCreate,
    RideLocation,
    RideRouteUpdate,
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
    return {"message": "ShareRide Matching Service", "status": "running"}


@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    if await check_database_health():
        return {"status": "healthy", "database_status": "ok"}
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Usługa niedostępna. Bazy danych nie odpowiadają.",
    )


@app.post(
    "/api/rides", response_model=MessageResponse, status_code=status.HTTP_201_CREATED
)
async def create_ride_endpoint(ride_data: RideCreate):
    """Tworzy nowy przejazd, inicjując go w MongoDB."""
    try:
        ride_id = await create_new_ride(ride_data)
        return {"ride_id": ride_id, "message": "Przejazd utworzony pomyślnie."}
    except Exception as e:
        # Wewnętrzne błędy serwera/baz danych
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd tworzenia przejazdu: {e}",
        )


@app.patch("/api/rides/{ride_id}/route", response_model=MessageResponse)
async def update_route_endpoint(ride_id: str, route_data: RideRouteUpdate):
    """Aktualizuje trase przejazdu."""
    try:
        await update_ride_route(route_data)
        return {
            "ride_id": ride_id,
            "message": "Trasa została zaktualizowana pomyślnie.",
        }
    except ValueError as e:
        # Przejazd nieznaleziony
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd aktualizacji trasy: {e}",
        )


@app.patch("/api/rides/{ride_id}/status", response_model=MessageResponse)
async def update_ride_status_endpoint(ride_id: str, status_update: RideStatusUpdate):
    """Aktualizuje status przejazdu (np. active, completed)."""
    try:
        new_status = await update_ride_status(ride_id, status_update)
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
async def remove_driver_availability_endpoint(driver_id: int):
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
        message = await set_driver_available(availability_data)
        return {"message": message}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd ustawiania dostępności kierowcy: {e}",
        )


@app.post(
    "/api/drivers/rides",
    response_model=DriverRidesResponse,
    status_code=status.HTTP_200_OK,
)
async def get_driver_rides_endpoint(data: DriverRidesQuery):
    """
    Pobiera przejazdy dla wskazanego kierowcy, z opcjonalnym filtrowaniem po statusie.
    """

    try:
        rides = await get_driver_rides(
            driver_id=data.driver_id, status=data.status.value if data.status else None
        )

        return {
            "driver_id": data.driver_id,
            "rides": rides,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Błąd pobierania przejazdów: {str(e)}",
        )

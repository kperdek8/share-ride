from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from database import (
    check_database_health,
    create_new_ride,
    update_ride_status,
    update_ride_location,
    redis_client # Potrzebne do zamknięcia połączenia
)
from models import RideCreate, RideStatusUpdate, RideLocation, MessageResponse

app = FastAPI(
    title="ShareRide Ride Management Service",
    description="Usluga zarzadzania przejazdami",
    version="1.0.0"
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
    # Zalecane jest zamknięcie połączenia z Redis
    await redis_client.close()


@app.get("/", response_model=MessageResponse)
async def root():
    return {"message": "ShareRide Matching Service", "status": "running"}


@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    if await check_database_health():
        return {"status": "healthy", "database_status": "ok"}
    raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                        detail="Usługa niedostępna. Bazy danych nie odpowiadają.")


@app.post("/api/rides", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_ride(ride_data: RideCreate):
    """Tworzy nowy przejazd, inicjując go w MongoDB."""
    try:
        ride_id = await create_new_ride(ride_data)
        return {"ride_id": ride_id, "message": "Przejazd utworzony pomyślnie."}
    except Exception as e:
        # Wewnętrzne błędy serwera/baz danych
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Błąd tworzenia przejazdu: {e}")


@app.patch("/api/rides/{ride_id}/status", response_model=MessageResponse)
async def patch_ride_status(ride_id: str, status_update: RideStatusUpdate):
    """Aktualizuje status przejazdu (np. active, completed)."""
    try:
        new_status = await update_ride_status(ride_id, status_update)
        return {"ride_id": ride_id, "message": f"Status zaktualizowany na: {new_status}"}
    except ValueError as e:
        # Przejazd nie znaleziony
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Błąd aktualizacji statusu: {e}")


@app.patch("/api/rides/{ride_id}/location", response_model=MessageResponse)
async def patch_ride_location(ride_id: str, location: RideLocation):
    """Aktualizuje bieżącą pozycję GPS w Redis (wysoki wolumen zapisu)."""
    try:
        await update_ride_location(ride_id, location)
        return {"ride_id": ride_id, "message": "Lokalizacja zaktualizowana w Redis."}
    except Exception as e:
        # Błędy Redis są krytyczne dla tego endpointu
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Błąd zapisu lokalizacji do Redis: {e}")

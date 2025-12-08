from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class RideStatus(str, Enum):
    """Dozwolone statusy przejazdu."""

    PENDING = "pending"  # Utworzony, czeka na aktywację przez kierowcę
    AVAILABLE = (
        "available"  # Kierowca jest gotowy do przyjęcia pierwszego zlecenia (NOWY STAN)
    )
    ACTIVE = "active"  # W trakcie jazdy z pasażerem/pasażerami
    ON_ROUTE = "on_route"  # W drodze do konkretnego celu (klient/przystanek)
    COMPLETED = "completed"
    CANCELLED = "cancelled"


# --- MODELE PYDANTIC DLA DANYCH WEJŚCIOWYCH ---


class RideCreate(BaseModel):
    """Model danych wejściowych dla tworzenia nowego przejazdu."""

    driver_id: int = Field(..., description="ID kierowcy.")
    start_lat: float = Field(..., ge=-90, le=90)
    start_lng: float = Field(..., ge=-180, le=180)
    end_lat: float = Field(..., ge=-90, le=90)
    end_lng: float = Field(..., ge=-180, le=180)
    polyline: str = Field(..., description="Zakodowany Polyline trasy.")


class RideLocation(BaseModel):
    """Model danych wejściowych dla aktualizacji lokalizacji (GPS)."""

    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)


class RideStatusUpdate(BaseModel):
    """Model danych wejściowych dla aktualizacji statusu z użyciem."""

    new_status: RideStatus = Field(..., description="Nowy, dozwolony status przejazdu.")
    driver_id: int = Field(..., description="ID kierowcy, który wykonuje aktualizację.")


class DriverAvailability(BaseModel):
    """Model zgłaszania gotowości do przyjęcia pierwszego zlecenia."""

    driver_id: int = Field(..., description="ID kierowcy.")
    current_lat: float = Field(..., ge=-90, le=90)
    current_lng: float = Field(..., ge=-180, le=180)


# --- MODEL DANYCH WYJŚCIOWYCH ---


class MessageResponse(BaseModel):
    """Standardowa struktura odpowiedzi."""

    message: str
    ride_id: Optional[str] = None

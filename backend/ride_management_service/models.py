from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class RideStatus(str, Enum):
    """Dozwolone statusy przejazdu."""

    PENDING = "pending"  # Utworzony, czeka na aktywację przez kierowcę
    AVAILABLE = "available"  # Kierowca jest gotowy do przyjęcia pierwszego zlecenia
    ACTIVE = "active"  # W trakcie jazdy z pasażerem/pasażerami
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class RideItem(BaseModel):
    ride_id: str = Field(..., alias="_id")
    driver_id: int
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float
    polyline: str
    current_status: str


# --- MODELE PYDANTIC DLA DANYCH WEJŚCIOWYCH ---


class RideCreate(BaseModel):
    """Model danych wejściowych dla tworzenia nowego przejazdu."""

    driver_id: int = Field(..., description="ID kierowcy.")
    start_lat: float = Field(..., ge=-90, le=90)
    start_lng: float = Field(..., ge=-180, le=180)
    end_lat: float = Field(..., ge=-90, le=90)
    end_lng: float = Field(..., ge=-180, le=180)
    polyline: str = Field(..., description="Zakodowany Polyline trasy.")


class RideRouteUpdate(BaseModel):
    """Model danych wejściowych dla aktualizacji przejazdu."""

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


class DriverRidesQuery(BaseModel):
    """
    Dane wejściowe dla pobierania przejazdów kierowcy.
    """

    driver_id: int = Field(..., description="ID kierowcy")
    status: Optional[RideStatus] = Field(
        None, description="Opcjonalny filtr statusu przejazdu"
    )


# --- MODEL DANYCH WYJŚCIOWYCH ---


class DriverRidesResponse(BaseModel):
    driver_id: int
    rides: List[RideItem]


class MessageResponse(BaseModel):
    """Standardowa struktura odpowiedzi."""

    message: str
    ride_id: Optional[str] = None

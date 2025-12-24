from enum import Enum

from pydantic import BaseModel, Field
from typing import List


class RideStatus(str, Enum):
    """Dozwolone statusy przejazdu."""

    PENDING = "pending"  # Utworzony, czeka na aktywację przez kierowcę
    AVAILABLE = "available"  # Kierowca jest gotowy do przyjęcia pierwszego zlecenia
    ACTIVE = "active"  # W trakcie jazdy z pasażerem/pasażerami
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class RideSearchRequest(BaseModel):
    """Żądanie pasażera - tylko punkty trasy."""
    pickup_lat: float = Field(..., ge=-90, le=90)
    pickup_lng: float = Field(..., ge=-180, le=180)
    dropoff_lat: float = Field(..., ge=-90, le=90)
    dropoff_lng: float = Field(..., ge=-180, le=180)


class MatchingOffer(BaseModel):
    """Uproszczona oferta dojazdu."""
    driver_id: str
    pickup_eta_minutes: int = Field(..., description="Czas do odbioru pasażera")
    total_eta_minutes: int = Field(..., description="Czas całej trasy od odbioru do celu.")
    distance_km: float
    polyline: str  # Trasa dojazdu od kierowcy do pasażera


class MessageResponse(BaseModel):
    """Standardowa struktura odpowiedzi."""

    message: str

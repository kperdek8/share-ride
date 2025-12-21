from pydantic import BaseModel, Field
from typing import List


class RideSearchRequest(BaseModel):
    """Żądanie pasażera - tylko punkty trasy."""
    pickup_lat: float = Field(..., ge=-90, le=90)
    pickup_lng: float = Field(..., ge=-180, le=180)
    dropoff_lat: float = Field(..., ge=-90, le=90)
    dropoff_lng: float = Field(..., ge=-180, le=180)


class MatchingOffer(BaseModel):
    """Uproszczona oferta dojazdu."""
    driver_id: str
    eta_minutes: int
    distance_km: float
    polyline: str  # Trasa dojazdu od kierowcy do pasażera


class MessageResponse(BaseModel):
    """Standardowa struktura odpowiedzi."""

    message: str

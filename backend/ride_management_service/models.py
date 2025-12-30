from enum import Enum
from typing import List, Optional
from datetime import datetime, UTC
from pydantic import BaseModel, Field, ConfigDict


class RideStatus(str, Enum):
    """Dozwolone statusy przejazdu."""

    PENDING = "pending"  # Utworzony, czeka na aktywację przez kierowcę
    AVAILABLE = "available"  # Kierowca jest gotowy do przyjęcia pierwszego zlecenia
    ACTIVE = "active"  # W trakcie jazdy z pasażerem/pasażerami
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Location(BaseModel):
    lat: float
    lng: float


class PassengerItem(BaseModel):
    passenger_id: str
    pickup: Location
    dropoff: Location
    picked_up: bool


class RouteData(BaseModel):
    polyline: str
    distance_km: float
    duration_min: int


class RideItem(BaseModel):
    """
    Model reprezentujący pełny dokument przejazdu w MongoDB.
    """
    id: str = Field(alias="_id") # Mapowanie MongoDB _id na pole id w Pydantic
    driver_id: str
    status: RideStatus
    passengers: List[PassengerItem]
    route_data: RouteData


# --- MODELE PYDANTIC DLA DANYCH WEJŚCIOWYCH ---


class RideJoinRequest(BaseModel):
    """Żądanie dołączenia do przejazdu lub zaakceptowania oferty kierowcy."""
    driver_id: str = Field(..., description="ID wybranego kierowcy.")
    passenger_id: str = Field(..., description="ID pasażera.")
    pickup_lat: float
    pickup_lng: float
    dropoff_lat: float
    dropoff_lng: float


class RideLocation(BaseModel):
    """Model danych wejściowych dla aktualizacji lokalizacji (GPS)."""

    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)


class RideStatusUpdate(BaseModel):
    """Model danych wejściowych dla aktualizacji statusu z użyciem."""

    new_status: RideStatus = Field(..., description="Nowy, dozwolony status przejazdu.")
    driver_id: str = Field(..., description="ID kierowcy, który wykonuje aktualizację (będzie zamienione na odczyt id z tokenu dostępu).")


class RidePickupUpdate(BaseModel):
    """Model danych wejściowych dla potwierdzenia odbioru pasażera."""

    passenger_id: str = Field(..., description="ID pasażera, który został odebrany")
    driver_id: str = Field(..., description="ID kierowcy, który wykonuje aktualizację (będzie zamienione na odczyt id z tokenu dostępu).")


class DriverAvailability(BaseModel):
    """Model zgłaszania gotowości do przyjęcia pierwszego zlecenia."""

    driver_id: str = Field(..., description="ID kierowcy.")
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)


class DriverRidesQuery(BaseModel):
    """
    Dane wejściowe dla pobierania przejazdów kierowcy.
    """

    driver_id: str = Field(..., description="ID kierowcy")
    status: Optional[RideStatus] = Field(
        None, description="Opcjonalny filtr statusu przejazdu"
    )


# --- MODEL DANYCH WYJŚCIOWYCH ---


class DriverRidesResponse(BaseModel):
    driver_id: str
    rides: List[RideItem]


class RideJoinResponse(BaseModel):
    """Standardowa struktura odpowiedzi."""
    ride_id: str
    driver_id: str
    status: RideStatus


class MessageResponse(BaseModel):
    """Standardowa struktura odpowiedzi."""

    message: str

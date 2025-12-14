from pydantic import BaseModel, Field
from typing import List, Optional


class RideOption(BaseModel):
    ride_id: str = Field(..., description="Identyfikator przejazdu")
    is_shared: bool = Field(..., description="Czy przejazd jest współdzielony")
    shared_passengers: Optional[int] = Field(
        None, description="Liczba pasażerów w przejeździe współdzielonym (łącznie)"
    )
    driver_first_name: str
    driver_last_name: str
    driver_rating: float = Field(..., ge=1.0, le=5.0, description="Ocena kierowcy 1–5")
    duration_minutes: int = Field(..., description="Czas przejazdu w minutach")
    shared_extra_duration_minutes: int = Field(
        ..., description="O ile dłuższy jest przejazd współdzielony (w minutach)"
    )
    price_pln: float = Field(..., description="Cena przejazdu w PLN")
    shared_discount_pln: float = Field(
        ..., description="O ile tańsza jest opcja współdzielona (w PLN)"
    )


class RouteRequest(BaseModel):
    """Model żądania dla symulacji trasy"""
    from_address: str = Field(..., description="Adres początkowy (skąd)")
    to_address: str = Field(..., description="Adres docelowy (dokąd)")


class Location(BaseModel):
    """Model lokalizacji z współrzędnymi"""
    lat: float = Field(..., ge=-90, le=90, description="Szerokość geograficzna")
    lng: float = Field(..., ge=-180, le=180, description="Długość geograficzna")
    address: Optional[str] = Field(None, description="Adres tekstowy (opcjonalny)")


class Driver(BaseModel):
    """Model kierowcy w symulacji"""
    driver_id: str = Field(..., description="Identyfikator kierowcy")
    first_name: str = Field(..., description="Imię kierowcy")
    last_name: str = Field(..., description="Nazwisko kierowcy")
    rating: float = Field(..., ge=1.0, le=5.0, description="Ocena kierowcy")
    location: Location = Field(..., description="Aktualne położenie kierowcy")
    vehicle_model: Optional[str] = Field(None, description="Model pojazdu")
    vehicle_plate: Optional[str] = Field(None, description="Numer rejestracyjny")


class Passenger(BaseModel):
    """Model pasażera w symulacji"""
    passenger_id: str = Field(..., description="Identyfikator pasażera")
    first_name: str = Field(..., description="Imię pasażera")
    last_name: str = Field(..., description="Nazwisko pasażera")
    pickup_location: Location = Field(..., description="Miejsce odbioru pasażera")
    dropoff_location: Optional[Location] = Field(None, description="Miejsce wysadzenia pasażera")


class RouteSimulationResponse(BaseModel):
    """Model odpowiedzi dla symulacji trasy"""
    route_id: str = Field(..., description="Identyfikator trasy")
    from_location: Location = Field(..., description="Lokalizacja początkowa")
    to_location: Location = Field(..., description="Lokalizacja docelowa")
    drivers: List[Driver] = Field(..., description="Lista dostępnych kierowców")
    passengers: List[Passenger] = Field(..., description="Lista pasażerów na trasie")



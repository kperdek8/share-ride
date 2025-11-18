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



from pydantic import BaseModel, Field
from typing import Optional

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
    timestamp: Optional[int] = Field(None, description="Timestamp aktualizacji.")

class RideStatusUpdate(BaseModel):
    """Model danych wejściowych dla aktualizacji statusu."""
    new_status: str = Field(..., description="Nowy status (np. 'active', 'on_route', 'completed').")

# --- MODEL DANYCH WYJŚCIOWYCH (PRZYKŁAD) ---

class MessageResponse(BaseModel):
    """Standardowa struktura odpowiedzi."""
    message: str
    ride_id: Optional[str] = None
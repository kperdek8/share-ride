from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any, List
from simulation_service.sim_service import RideOption

app = FastAPI(
    title="ShareRide API",
    description="API dla aplikacji ShareRide - wspólne przejazdy",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"message": "ShareRide API", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.get("/api/test")
async def test_endpoint():
    return {
        "message": "Test endpoint działa!",
        "data": {
            "timestamp": "2025-11-14 12:00:00",
            "version": "1.0.0"
        }
    }


@app.post("/api/test")
async def test_post(data: Dict[str, Any]):
    return {
        "message": "Dane otrzymane!",
        "received_data": data,
        "status": "success"
    }

@app.get("/rides/short-term", response_model=List[RideOption])
def get_short_term_rides():
    """
    Zwraca listę zasymulowanych krótkoterminowych przejazdów.
    W realnym systemie to miejsce byłoby podłączone do bazy danych / silnika wyceny.
    """

    # Przykładowe dane symulacyjne.
    # Możesz je później zastąpić generowaniem dynamicznym lub zapytaniem do bazy.
    rides = [
        RideOption(
            ride_id="RIDE-001",
            is_shared=False,
            shared_passengers=None,
            driver_first_name="Jan",
            driver_last_name="Kowalski",
            driver_rating=4.8,
            duration_minutes=15,
            shared_extra_duration_minutes=0,   # brak współdzielenia – brak różnicy
            price_pln=28.50,
            shared_discount_pln=0.0           # brak współdzielenia – brak zniżki
        ),
        RideOption(
            ride_id="RIDE-002",
            is_shared=True,
            shared_passengers=2,
            driver_first_name="Anna",
            driver_last_name="Nowak",
            driver_rating=4.9,
            duration_minutes=18,              # 3 min dłużej niż wariant indywidualny
            shared_extra_duration_minutes=3,
            price_pln=22.00,                  # np. 6 zł taniej niż indywidualnie
            shared_discount_pln=6.00
        ),
        RideOption(
            ride_id="RIDE-003",
            is_shared=True,
            shared_passengers=3,
            driver_first_name="Piotr",
            driver_last_name="Wiśniewski",
            driver_rating=4.6,
            duration_minutes=25,              # 5 min dłużej
            shared_extra_duration_minutes=5,
            price_pln=30.00,                  # np. 8 zł taniej
            shared_discount_pln=8.00
        ),
        RideOption(
            ride_id="RIDE-004",
            is_shared=False,
            shared_passengers=None,
            driver_first_name="Katarzyna",
            driver_last_name="Zielińska",
            driver_rating=4.7,
            duration_minutes=10,
            shared_extra_duration_minutes=0,
            price_pln=18.00,
            shared_discount_pln=0.0
        ),
    ]

    return rides

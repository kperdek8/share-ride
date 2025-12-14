from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Any, List, Optional, Tuple
import random
import uuid
import requests
from simulation_service.sim_service import (
    RideOption,
    RouteRequest,
    RouteSimulationResponse,
    Location,
    Driver,
    Passenger,
)

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


# Klucz API Google Maps (używany również dla Geocoding API)
GOOGLE_MAPS_API_KEY = "AIzaSyAjlnq9NTmxr4O0lwDbfxNdMDkBFZuzcxw"


def geocode_address(address: str) -> Optional[Tuple[float, float]]:
    """
    Konwertuje adres na współrzędne geograficzne używając Google Geocoding API.
    Zwraca tuple (lat, lng) lub None w przypadku błędu.
    """
    try:
        url = "https://maps.googleapis.com/maps/api/geocode/json"
        params = {
            "address": address,
            "key": GOOGLE_MAPS_API_KEY,
        }
        
        print(f"Geocoding address: {address}")
        response = requests.get(url, params=params, timeout=15)
        response.raise_for_status()
        data = response.json()
        
        if data["status"] == "OK" and data["results"]:
            location = data["results"][0]["geometry"]["location"]
            coords = (location["lat"], location["lng"])
            print(f"Geocoding success: {address} -> {coords}")
            return coords
        else:
            print(f"Geocoding failed for address '{address}': {data.get('status')}")
            return None
    except requests.exceptions.Timeout:
        print(f"Geocoding timeout for address '{address}'")
        return None
    except Exception as e:
        print(f"Error geocoding address '{address}': {e}")
        return None


@app.post("/api/simulation/route", response_model=RouteSimulationResponse)
async def simulate_route(route_request: RouteRequest):
    """
    Symuluje trasę na podstawie adresów skąd-dokąd.
    Zwraca listę kierowców i pasażerów z ich położeniami wzdłuż trasy.
    """
    try:
        print(f"Received route request: from={route_request.from_address}, to={route_request.to_address}")
        
        # Konwertujemy adresy na współrzędne używając Google Geocoding API
        from_coords = geocode_address(route_request.from_address)
        to_coords = geocode_address(route_request.to_address)
        
        # Jeśli geocoding się nie powiódł, używamy domyślnych współrzędnych (Wrocław)
        if from_coords is None:
            from_coords = (51.1079, 17.0385)  # Wrocław - centrum
            print(f"Using default coordinates for 'from' address: {route_request.from_address}")
        
        if to_coords is None:
            to_coords = (51.1079, 17.0385)  # Wrocław - centrum
            print(f"Using default coordinates for 'to' address: {route_request.to_address}")
        
        from_lat, from_lng = from_coords
        to_lat, to_lng = to_coords
        
        from_location = Location(
            lat=from_lat,
            lng=from_lng,
            address=route_request.from_address
        )
        
        to_location = Location(
            lat=to_lat,
            lng=to_lng,
            address=route_request.to_address
        )
        
        # Generujemy kierowców - położeni wzdłuż trasy lub w okolicy
        drivers = []
        driver_names = [
            ("Jan", "Kowalski"),
            ("Anna", "Nowak"),
            ("Piotr", "Wiśniewski"),
            ("Katarzyna", "Zielińska"),
            ("Marek", "Szymański"),
        ]
        vehicle_models = ["Toyota Corolla", "Volkswagen Golf", "Ford Focus", "Opel Astra", "Skoda Octavia"]
        
        for i in range(3):  # Generujemy 3 kierowców
            # Położenie kierowcy wzdłuż trasy (między startem a końcem)
            progress = random.uniform(0.0, 1.0)  # 0 = start, 1 = koniec
            driver_lat = from_lat + (to_lat - from_lat) * progress + random.uniform(-0.01, 0.01)
            driver_lng = from_lng + (to_lng - from_lng) * progress + random.uniform(-0.01, 0.01)
            
            first_name, last_name = driver_names[i % len(driver_names)]
            drivers.append(Driver(
                driver_id=f"DRIVER-{uuid.uuid4().hex[:8].upper()}",
                first_name=first_name,
                last_name=last_name,
                rating=round(random.uniform(4.0, 5.0), 1),
                location=Location(
                    lat=round(driver_lat, 6),
                    lng=round(driver_lng, 6),
                    address=f"Okolica trasy {i+1}"
                ),
                vehicle_model=vehicle_models[i % len(vehicle_models)],
                vehicle_plate=f"W{random.randint(1000, 9999)}{chr(random.randint(65, 90))}{chr(random.randint(65, 90))}"
            ))
        
        # Generujemy pasażerów - położeni wzdłuż trasy
        passengers = []
        passenger_names = [
            ("Maria", "Kowalczyk"),
            ("Tomasz", "Lewandowski"),
            ("Agnieszka", "Wójcik"),
            ("Paweł", "Kamiński"),
        ]
        
        for i in range(2):  # Generujemy 2 pasażerów
            # Położenie odbioru pasażera wzdłuż trasy
            pickup_progress = random.uniform(0.1, 0.7)  # Nie na samym początku ani końcu
            pickup_lat = from_lat + (to_lat - from_lat) * pickup_progress + random.uniform(-0.01, 0.01)
            pickup_lng = from_lng + (to_lng - from_lng) * pickup_progress + random.uniform(-0.01, 0.01)
            
            # Położenie wysadzenia - dalej wzdłuż trasy
            dropoff_progress = min(pickup_progress + random.uniform(0.2, 0.5), 0.9)
            dropoff_lat = from_lat + (to_lat - from_lat) * dropoff_progress + random.uniform(-0.01, 0.01)
            dropoff_lng = from_lng + (to_lng - from_lng) * dropoff_progress + random.uniform(-0.01, 0.01)
            
            first_name, last_name = passenger_names[i % len(passenger_names)]
            passengers.append(Passenger(
                passenger_id=f"PASSENGER-{uuid.uuid4().hex[:8].upper()}",
                first_name=first_name,
                last_name=last_name,
                pickup_location=Location(
                    lat=round(pickup_lat, 6),
                    lng=round(pickup_lng, 6),
                    address=f"Punkt odbioru {i+1}"
                ),
                dropoff_location=Location(
                    lat=round(dropoff_lat, 6),
                    lng=round(dropoff_lng, 6),
                    address=f"Punkt wysadzenia {i+1}"
                )
            ))
        
        result = RouteSimulationResponse(
            route_id=f"ROUTE-{uuid.uuid4().hex[:8].upper()}",
            from_location=from_location,
            to_location=to_location,
            drivers=drivers,
            passengers=passengers
        )
        
        print(f"Route simulation completed: route_id={result.route_id}, drivers={len(drivers)}, passengers={len(passengers)}")
        return result
    except Exception as e:
        print(f"Error in simulate_route: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Błąd podczas symulacji trasy: {str(e)}")

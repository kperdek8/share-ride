# Przykładowe curl do testowania nowych funkcji

## Geocoding (konwersja adresu na współrzędne)

### Konwersja adresu na współrzędne
```bash
curl -X POST "http://localhost:8000/api/geocode" \
     -H "Content-Type: application/json" \
     -d '{
         "address": "Rynek, Wrocław"
     }'
```

**Odpowiedź:**
```json
{
  "lat": 51.1097,
  "lng": 17.0327
}
```

---

## Matching Service - Wyszukiwanie przejazdów

### Wyszukiwanie przejazdów (z współrzędnymi)
```bash
curl -X POST "http://localhost:8001/api/matching/offers" \
     -H "Content-Type: application/json" \
     -d '{
         "pickup_lat": 51.1079,
         "pickup_lng": 17.0385,
         "dropoff_lat": 51.075150,
         "dropoff_lng": 17.032672
     }'
```

**Odpowiedź (przykład):**
```json
[
  {
    "driver_id": "driver1",
    "pickup_eta_minutes": 5,
    "total_eta_minutes": 15,
    "distance_km": 12.3,
    "polyline": "encoded_polyline_string",
    "is_shared": false,
    "shared_passengers": 0
  },
  {
    "driver_id": "driver2",
    "pickup_eta_minutes": 8,
    "total_eta_minutes": 20,
    "distance_km": 15.7,
    "polyline": "encoded_polyline_string",
    "is_shared": true,
    "shared_passengers": 2
  }
]
```

---

## Scenariusz testowy: Przejazdy współdzielone

### Krok 1: Dodaj kierowców do systemu
```bash
# Dodaj pierwszego kierowcę
curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
         "lat": 51.1079,
         "lng": 17.0385,
         "driver_id": "driver1"
     }'

# Dodaj drugiego kierowcę
curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
         "lat": 51.1049,
         "lng": 17.0119,
         "driver_id": "driver2"
     }'
```

### Krok 2: Utwórz pierwszy przejazd (dla driver1)
```bash
curl -X POST "http://localhost:8002/api/rides/join" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "driver1",
         "passenger_id": "passenger1",
         "pickup_lat": 51.1079,
         "pickup_lng": 17.0385,
         "dropoff_lat": 51.075150,
         "dropoff_lng": 17.032672
     }'
```

**Odpowiedź (zapisz ride_id!):**
```json
{
  "ride_id": "8308418b-d2d3-404b-9717-f9dfae65abb1",
  "driver_id": "driver1",
  "status": "pending"
}
```

**WAŻNE:** Skopiuj `ride_id` z odpowiedzi - będziesz go potrzebować w następnym kroku!

### Krok 3: Aktywuj przejazd (zmień status na ACTIVE)
```bash
# ZAMIEŃ RIDE_ID na ride_id z poprzedniego kroku!
curl -X PATCH "http://localhost:8002/api/rides/RIDE_ID/status" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "driver1",
         "new_status": "active"
     }'
```

**Przykład z konkretnym ID:**
```bash
curl -X PATCH "http://localhost:8002/api/rides/8308418b-d2d3-404b-9717-f9dfae65abb1/status" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "driver1",
         "new_status": "active"
     }'
```

**Odpowiedź:**
```json
{
  "message": "Status zaktualizowany na: active"
}
```

### Krok 4: Wyszukaj przejazdy (powinny pokazać się przejazdy solo i współdzielone)
```bash
curl -X POST "http://localhost:8001/api/matching/offers" \
     -H "Content-Type: application/json" \
     -d '{
         "pickup_lat": 51.1079,
         "pickup_lng": 17.0385,
         "dropoff_lat": 51.075150,
         "dropoff_lng": 17.032672
     }'
```

**Odpowiedź (przykład):**
```json
[
  {
    "driver_id": "driver2",
    "pickup_eta_minutes": 3,
    "total_eta_minutes": 12,
    "distance_km": 10.5,
    "polyline": "...",
    "is_shared": false,
    "shared_passengers": 0
  },
  {
    "driver_id": "driver1",
    "pickup_eta_minutes": 2,
    "total_eta_minutes": 14,
    "distance_km": 11.2,
    "polyline": "...",
    "is_shared": true,
    "shared_passengers": 1
  }
]
```

---

## Pełny scenariusz testowy (end-to-end)

### 1. Geocoding - konwersja adresów na współrzędne
```bash
# Adres początkowy
curl -X POST "http://localhost:8000/api/geocode" \
     -H "Content-Type: application/json" \
     -d '{"address": "Rynek, Wrocław"}'

# Adres docelowy
curl -X POST "http://localhost:8000/api/geocode" \
     -H "Content-Type: application/json" \
     -d '{"address": "Plac Grunwaldzki, Wrocław"}'
```

### 2. Dodaj kierowców
```bash
./populate_drivers.sh
```

### 3. Wyszukaj przejazdy (używając współrzędnych z geocoding)
```bash
curl -X POST "http://localhost:8001/api/matching/offers" \
     -H "Content-Type: application/json" \
     -d '{
         "pickup_lat": 51.1097,
         "pickup_lng": 17.0327,
         "dropoff_lat": 51.1125,
         "dropoff_lng": 17.0612
     }'
```

### 4. Utwórz przejazd
```bash
# Utwórz przejazd i zapisz ride_id z odpowiedzi
RIDE_ID=$(curl -s -X POST "http://localhost:8002/api/rides/join" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "driver1",
         "passenger_id": "passenger1",
         "pickup_lat": 51.1097,
         "pickup_lng": 17.0327,
         "dropoff_lat": 51.1125,
         "dropoff_lng": 17.0612
     }' | python3 -c "import sys, json; print(json.load(sys.stdin)['ride_id'])")

echo "Utworzono przejazd: $RIDE_ID"
```

**Lub ręcznie - skopiuj ride_id z odpowiedzi:**
```bash
curl -X POST "http://localhost:8002/api/rides/join" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "driver1",
         "passenger_id": "passenger1",
         "pickup_lat": 51.1097,
         "pickup_lng": 17.0327,
         "dropoff_lat": 51.1125,
         "dropoff_lng": 17.0612
     }'
```

### 5. Aktywuj przejazd
```bash
# Jeśli użyłeś zmiennej RIDE_ID:
curl -X PATCH "http://localhost:8002/api/rides/$RIDE_ID/status" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "driver1",
         "new_status": "active"
     }'

# Lub ręcznie - wstaw ride_id z poprzedniego kroku:
curl -X PATCH "http://localhost:8002/api/rides/TWOJE_RIDE_ID/status" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "driver1",
         "new_status": "active"
     }'
```

### 6. Wyszukaj ponownie (powinny pokazać się przejazdy współdzielone)
```bash
curl -X POST "http://localhost:8001/api/matching/offers" \
     -H "Content-Type: application/json" \
     -d '{
         "pickup_lat": 51.1097,
         "pickup_lng": 17.0327,
         "dropoff_lat": 51.1125,
         "dropoff_lng": 17.0612
     }'
```

---

## Health check

### Matching Service
```bash
curl -X GET "http://localhost:8001/health"
```

### Ride Management Service
```bash
curl -X GET "http://localhost:8002/health"
```

### Main API
```bash
curl -X GET "http://localhost:8000/health"
```

---

## Uwagi

- **Porty:**
  - Main API: `8000`
  - Matching Service: `8001`
  - Ride Management Service: `8002`

- **Przejazdy współdzielone:**
  - Pojawiają się tylko gdy kierowca ma status `ACTIVE`
  - Maksymalnie 4 pasażerów w jednym przejeździe
  - Automatycznie dodawane jest 10% czasu na dodatkowe przystanki

- **Geocoding:**
  - Używa Google Geocoding API
  - Zwraca współrzędne (lat, lng) dla podanego adresu
  - Można używać polskich adresów

- **WAŻNE - Rozwiązywanie problemów:**
  - **"Przejazd nie znaleziony w MongoDB"** - używasz starego/niewłaściwego `ride_id`. Najpierw utwórz przejazd przez `/api/rides/join` i użyj `ride_id` z odpowiedzi.
  - **"Driver is not available"** - kierowca nie jest dostępny. Uruchom `./populate_drivers.sh` aby dodać kierowców do systemu.
  - **Brak przejazdów współdzielonych** - upewnij się, że:
    1. Masz kierowców w systemie (`./populate_drivers.sh`)
    2. Utworzyłeś przejazd dla kierowcy (`/api/rides/join`)
    3. Aktywowałeś przejazd (`/api/rides/{ride_id}/status` z `"new_status": "active"`)
    4. Wyszukujesz przejazdy w podobnej lokalizacji


**Ride Management Service**

Ustawienie statusu dostepnego (kierowca):
```
curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.1079,
		"lng": 17.0385,
		"driver_id": "driver1"
     }'
```

Aktualizacja statusu (zamień ID przejazdu)
```
curl -X PATCH "http://localhost:8002/api/rides/8308418b-d2d3-404b-9717-f9dfae65abb1/status" \
     -H "Content-Type: application/json" \
     -d '{
		"driver_id": "driver1",
		"new_status": "active"
     }'
```
Aktualizacja lokalizacji (zamień ID przejazdu)
```
curl -X PATCH "http://localhost:8002/api/rides/98f4b377-7010-420e-b3f3-fbe08122d696/location" \
     -H "Content-Type: application/json" \
     -d '{
         "lat": 51.1079,
         "lng": 17.0385,
         "timestamp": 1700000001
     }'
```

Odczytanie lokalizacji (zamień ID przejazdu)
```
curl -X GET "http://localhost:8002/api/rides/98f4b377-7010-420e-b3f3-fbe08122d696/location" \
```

Podgląd przejazdów kierowcy
```
curl -X GET "http://localhost:8002/api/drivers/rides?driver_id=driver1"
```

Podgląd przejazdów kierowcy w filtrem (active, pending, completed, cancelled)
```
curl -X GET "http://localhost:8002/api/drivers/rides?driver_id=driver1&status=pending"
```

Wylaczenie dostepnosci
```
curl -X DELETE "http://localhost:8002/api/drivers/driver1/available"
```

Wyszukanie przejazdu
```
curl -X 'POST' \
  'http://localhost:8001/api/matching/offers' \
  -H 'Content-Type: application/json' \
  -d '{
  "pickup_lat": 51.077582,
  "pickup_lng": 17.019205,
  "dropoff_lat": 51.075150,
  "dropoff_lng": 17.032672
}'
```

Dołączenie do przejazdu
```
curl -X 'POST' \
  'http://localhost:8002/api/rides/join' \
  -H 'Content-Type: application/json' \
  -d '{
  "driver_id": "driver1",
  "passenger_id": "passenger1",
  "pickup_lat": 51.077582,
  "pickup_lng": 17.019205,
  "dropoff_lat": 51.075150,
  "dropoff_lng": 17.032672
}'
```


DO MANUALNYCH TESTÓW // ZIGNORUJ

Odbiór pasażera
```
curl -X PATCH "http://localhost:8002/api/rides/534fa238-ae3e-4a2c-bef7-92730d7174fc/pickup" \
     -H "Content-Type: application/json" \
     -d '{
		"driver_id": "driver1",
		"passenger_id": "passenger1"
     }'
```

Wyszukanie przejazdu (drugi pasażer)
```
curl -X 'POST' \
  'http://localhost:8001/api/matching/offers' \
  -H 'Content-Type: application/json' \
  -d '{
  "pickup_lat": 51.101967,
  "pickup_lng": 17.029438,
  "dropoff_lat": 51.084134,
  "dropoff_lng": 17.015837
}'
```

Dołączenie drugiego pasażera, pickup + dropoff po drodze
```
curl -X 'POST' \
  'http://localhost:8002/api/rides/join' \
  -H 'Content-Type: application/json' \
  -d '{
  "driver_id": "driver1",
  "passenger_id": "passenger2",
  "pickup_lat": 51.101967,
  "pickup_lng": 17.029438,
  "dropoff_lat": 51.084134,
  "dropoff_lng": 17.015837
}'
```

**Ride Management Service**

Ustawienie statusu dostepnego (kierowca):
```
curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.1079,
		"lng": 17.0385,
		"driver_id": "abcd1234"
     }'
```

Tworzenie przejazdu
```
curl -X POST "http://localhost:8002/api/rides" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": "abcd1234",
         "start_lat": 51.1079,
         "start_lng": 17.0385,
         "end_lat": 51.0900,
         "end_lng": 17.0600,
         "polyline": "encoded_polyline_string_goes_here"
     }'
```
Aktualizacja statusu (zamień ID przejazdu)
```
curl -X PATCH "http://localhost:8002/api/rides/8308418b-d2d3-404b-9717-f9dfae65abb1/status" \
     -H "Content-Type: application/json" \
     -d '{
		"driver_id": "abcd1234",
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

Aktualizacja trasy (zamień ID przejazdu) + polyline jako placeholder 
```
curl -X PATCH "http://localhost:8002/api/rides/8308418b-d2d3-404b-9717-f9dfae65abb1/route" \
     -H "Content-Type: application/json" \
     -d '{
         "polyline": "some_new_encoded_polyline"
     }'
```

Wylaczenie dostepnosci
```
curl -X DELETE "http://localhost:8002/api/drivers/abcd1234/available"
```
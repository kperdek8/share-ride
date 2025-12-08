**Ride Management Service**

Tworzenie przejazdu
```
curl -X POST "http://localhost:8002/api/rides" \
     -H "Content-Type: application/json" \
     -d '{
         "driver_id": 101,
         "start_lat": 51.1079,
         "start_lng": 17.0385,
         "end_lat": 51.0900,
         "end_lng": 17.0600,
         "polyline": "encoded_polyline_string_goes_here"
     }'
```
Aktualizacja statusu (zamień ID przejazdu)
```
curl -X PATCH "http://localhost:8002/api/rides/98f4b377-7010-420e-b3f3-fbe08122d696/status" \
     -H "Content-Type: application/json" \
     -d '{
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
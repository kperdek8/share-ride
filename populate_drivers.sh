#!/bin/bash

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.084758,
		"lng": 17.018270,
		"driver_id": "driver1"
     }'

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.104948,
		"lng": 17.011909,
		"driver_id": "driver2"
     }'

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.075257,
		"lng": 16.993047,
		"driver_id": "driver3"
     }'

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.103921,
		"lng": 17.089528,
		"driver_id": "driver4"
     }'

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.124733,
		"lng": 16.996917,
		"driver_id": "driver5"
     }'

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.123526,
		"lng": 17.053164,
		"driver_id": "driver6"
     }'

# Przejazd wspoldzielony

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.101633,
		"lng": 17.092386,
		"driver_id": "driver7"
     }'

response=$(curl -s -X 'POST' \
  'http://localhost:8002/api/rides/join' \
  -H 'Content-Type: application/json' \
  -d '{
  "driver_id": "driver7",
  "passenger_id": "passenger1",
  "pickup_lat": 51.105690,
  "pickup_lng": 17.090425,
  "dropoff_lat": 51.116886,
  "dropoff_lng": 17.050283
}')

ride_id=$(echo $response | jq -r '.ride_id')

# Jesli jq nie dziala
# ride_id=$(echo $response | grep -oP '"ride_id":"\K[^"]+')

curl -X PATCH "http://localhost:8002/api/rides/$ride_id/status" \
     -H "Content-Type: application/json" \
     -d '{
		"driver_id": "driver7",
		"new_status": "active"
     }'
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

curl -X POST "http://localhost:8002/api/drivers/available" \
     -H "Content-Type: application/json" \
     -d '{
		"lat": 51.113082,
		"lng": 17.034578,
		"driver_id": "driver7"
     }'
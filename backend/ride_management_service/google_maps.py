import httpx
import os

GOOGLE_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "KLUCZ_API")
ROUTES_API_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"


async def get_directions(
        origin_lat: float,
        origin_lng: float,
        dest_lat: float,
        dest_lng: float,
        waypoints: list[tuple[float, float]] = None
):
    """
    Wykorzystuje Routes API do wyznaczenia trasy.
    """

    # Budowa punktów pośrednich dla nowego API
    intermediates = []
    if waypoints:
        for lat, lng in waypoints:
            intermediates.append({
                "location": {"latLng": {"latitude": lat, "longitude": lng}}
            })

    # Body zapytania (JSON)
    payload = {
        "origin": {
            "location": {"latLng": {"latitude": origin_lat, "longitude": origin_lng}}
        },
        "destination": {
            "location": {"latLng": {"latitude": dest_lat, "longitude": dest_lng}}
        },
        "intermediates": intermediates,
        "travelMode": "DRIVE",
        "routingPreference": "ROUTING_PREFERENCE_UNSPECIFIED",
        "polylineQuality": "HIGH_QUALITY",
        "polylineEncoding": "ENCODED_POLYLINE",
    }

    # Kluczowy element Routes API: FieldMask
    # Określamy dokładnie co chcemy dostać w odpowiedzi
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_API_KEY,
        "X-Goog-Fieldmask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline"
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(ROUTES_API_URL, json=payload, headers=headers)
            response.raise_for_status()
            data = response.json()

            if "routes" in data and len(data["routes"]) > 0:
                route = data["routes"][0]

                # Routes API zwraca dystans w metrach, a czas jako string np. "450s"
                duration_seconds = int(route["duration"].rstrip('s'))
                distance_meters = route["distanceMeters"]

                return {
                    "duration_min": round(duration_seconds / 60),
                    "distance_km": round(distance_meters / 1000, 2),
                    "polyline": route["polyline"]["encodedPolyline"]
                }
        except Exception as e:
            print(f"Routes API Error: {e}")
            return None
    print(f"DEBUG: No routes found. Response: {data}")
    return None


async def get_full_trip_route(
        driver_lat: float,
        driver_lng: float,
        active_passengers: list[dict]
):
    """
    Tworzy trasę uwzględniającą obecną pozycję kierowcy oraz wszystkich pasażerów.
    active_passengers: lista słowników z danymi pasażerów i ich punktami GPS.
    """

    if not active_passengers:
        return None

    # Logika punktów:
    # 1. Start (Origin) to ZAWSZE obecna pozycja kierowcy
    # 2. Destination to ZAWSZE cel ostatniego pasażera na liście (lub najbardziej oddalony)
    # 3. Wszystko pomiędzy to Waypoints

    all_points = []
    for p in active_passengers:
        # TODO: Uwzględnij czy pasażer już wsiadł czy nie
        #if p.get("status") == "waiting":
        all_points.append((p["pickup_lat"], p["pickup_lng"]))

        # Zawsze dodajemy punkt docelowy pasażera
        all_points.append((p["dropoff_lat"], p["dropoff_lng"]))

    if not all_points:
        return None

    # Ostatni punkt z listy staje się celem (destination)
    final_dest_lat, final_dest_lng = all_points.pop()

    # Reszta punktów to waypoints
    return await get_directions(
        origin_lat=driver_lat,
        origin_lng=driver_lng,
        dest_lat=final_dest_lat,
        dest_lng=final_dest_lng,
        waypoints=all_points
    )
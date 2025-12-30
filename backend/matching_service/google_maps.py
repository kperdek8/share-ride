import httpx
import os
from ortools.constraint_solver import pywrapcp, routing_enums_pb2

GOOGLE_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "KLUCZ_API")
ROUTES_API_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"
ROUTE_MATRIX_API_URL = "https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix"

async def get_directions(
        origin_lat: float,
        origin_lng: float,
        dest_lat: float,
        dest_lng: float,
        waypoints: list[tuple[float, float]] = None,
        pickup_index: int = None
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
        "routingPreference": "TRAFFIC_AWARE",  # Uwzględnia korki w czasie rzeczywistym
        "polylineEncoding": "ENCODED_POLYLINE",
    }

    # Kluczowy element Routes API: FieldMask
    # Określamy dokładnie co chcemy dostać w odpowiedzi
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_API_KEY,
        "X-Goog-Fieldmask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs"
    }

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(ROUTES_API_URL, json=payload, headers=headers)
            response.raise_for_status()
            data = response.json()

            if "routes" in data and len(data["routes"]) > 0:
                route = data["routes"][0]
                legs = route.get("legs", [])

                # Routes API zwraca dystans w metrach, a czas jako string np. "450s"

                eta_to_pickup_sec = 0

                if pickup_index is not None and legs:
                    # Jeśli pickup_index_in_waypoints == len(waypoints),
                    # oznacza to, że pickup jest celem końcowym (final_dest)
                    # W innym wypadku sumujemy legs do wskazanego indeksu.
                    limit = min(pickup_index + 1, len(legs))
                    for i in range(limit):
                        eta_to_pickup_sec += int(legs[i]["duration"].rstrip('s'))
                else:
                    # Zachowanie domyślne (np. dla pierwszego pasażera w zwykłym kursie)
                    eta_to_pickup_sec = int(legs[0]["duration"].rstrip('s')) if legs else 0
                
                # Całość trasy kierowca -> pasażer -> cel
                total_duration_sec = int(route["duration"].rstrip('s'))
                distance_meters = route["distanceMeters"]

                return {
                    "pickup_eta_min": round(eta_to_pickup_sec / 60),
                    "duration_min": round(total_duration_sec / 60),
                    "distance_km": round(distance_meters / 1000, 2),
                    "polyline": route["polyline"]["encodedPolyline"]
                }
        except Exception as e:
            print(f"Routes API Error: {e}")
            return None
    return None

async def get_distance_matrix(locations: list[tuple[float, float]]):
    """
    Pobiera macierz czasów przejazdu (w sekundach) przy użyciu Routes API v2.
    """
    # Budujemy listę origin i destination (te same punkty, by uzyskać macierz NxN)
    waypoints = []
    for lat, lng in locations:
        waypoints.append({
            "waypoint": {
                "location": {"latLng": {"latitude": lat, "longitude": lng}}
            }
        })

    payload = {
        "origins": waypoints,
        "destinations": waypoints,
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE"
    }

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_API_KEY,
        "X-Goog-Fieldmask": "originIndex,destinationIndex,duration,status"
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(ROUTE_MATRIX_API_URL, json=payload, headers=headers)
        response.raise_for_status()
        results = response.json()

        # Inicjalizujemy pustą macierz kwadratową NxN
        n = len(locations)
        matrix = [[0 for _ in range(n)] for _ in range(n)]

        # Mapujemy wyniki do macierzy
        for entry in results:
            # Niektóre wpisy mogą zawierać błędy (np. brak drogi)
            if entry.get("status", {}).get("code"):
                duration = 999999  # "Infinity" dla OR-Tools
            else:
                # Czas jest zwracany jako string "123s"
                duration = int(entry["duration"].rstrip('s'))

            i = entry["originIndex"]
            j = entry["destinationIndex"]
            matrix[i][j] = duration

        return matrix


async def solve_optimal_order(driver_coords, passengers, new_passenger=None):
    """
    driver_coords: (lat, lng)
    passengers: list[dict] -> [{"p_lat":..., "p_lng":..., "d_lat":..., "d_lng":..., "picked_up": bool}]
    new_passenger: dict -> {"p_lat":..., "p_lng":..., "d_lat":..., "d_lng":..., "picked_up": bool}

    Zwraca: (lista_wspolrzednych, indeks_pickup_nowego_pasazera)
    """
    # 1. Tworzymy listę wszystkich fizycznych lokalizacji
    # Punkt 0: Kierowca (Start)
    locations = [driver_coords]
    pickup_delivery_pairs = []
    new_passenger_node_idx = None

    current_idx = 1
    all_passengers = passengers + ([new_passenger] if new_passenger else [])

    for p in all_passengers:
        p_idx = None
        # Jeśli pasażer nie jest w aucie, musi mieć Pickup
        if not p["picked_up"]:
            locations.append((p["p_lat"], p["p_lng"]))
            p_idx = current_idx
            # Zapamiętujemy, który węzeł w OR-Tools należy do nowego pasażera
            if p == new_passenger:
                new_passenger_node_idx = p_idx
            current_idx += 1

        # Każdy pasażer musi mieć Dropoff
        locations.append((p["d_lat"], p["d_lng"]))
        d_idx = current_idx
        current_idx += 1

        if p_idx is not None:
            pickup_delivery_pairs.append((p_idx, d_idx))

    # 2. Pobieramy macierz odległości (Distance Matrix API)
    dist_matrix = await get_distance_matrix(locations)

    # 3. Konfiguracja OR-Tools
    manager = pywrapcp.RoutingIndexManager(len(locations), 1, 0)
    routing = pywrapcp.RoutingModel(manager)

    def distance_callback(from_index, to_index):
        from_node = manager.IndexToNode(from_index)
        to_node = manager.IndexToNode(to_index)
        return dist_matrix[from_node][to_node]

    transit_callback_index = routing.RegisterTransitCallback(distance_callback)
    routing.SetArcCostEvaluatorOfAllVehicles(transit_callback_index)

    # Dodanie wymiaru odległości/czasu dla restrykcji
    routing.AddDimension(transit_callback_index, 0, 100000, True, "Distance")
    distance_dimension = routing.GetDimensionOrDie("Distance")

    # KLUCZ: Wymuszenie Pickup -> Delivery
    for p_idx, d_idx in pickup_delivery_pairs:
        pickup_index = manager.NodeToIndex(p_idx)
        delivery_index = manager.NodeToIndex(d_idx)
        routing.AddPickupAndDelivery(pickup_index, delivery_index)
        routing.solver().Add(
            distance_dimension.CumulVar(pickup_index) <=
            distance_dimension.CumulVar(delivery_index)
        )

    # 4. Rozwiązanie
    search_parameters = pywrapcp.DefaultRoutingSearchParameters()
    search_parameters.first_solution_strategy = (
        routing_enums_pb2.FirstSolutionStrategy.PARALLEL_CHEAPEST_INSERTION
    )

    solution = routing.SolveWithParameters(search_parameters)

    if solution:
        # Wyciągamy ułożoną listę współrzędnych (bez startu)
        ordered_points = []
        new_passenger_ordered_node_index = None
        index = routing.Start(0)
        while not routing.IsEnd(index):
            node_index = manager.IndexToNode(index)
            if node_index != 0:  # pomijamy pozycję kierowcy, bo to 'origin' w Routes API
                if node_index == new_passenger_node_idx:
                    new_passenger_ordered_node_index = len(ordered_points)
                ordered_points.append(locations[node_index])
            index = solution.Value(routing.NextVar(index))

        return ordered_points, new_passenger_ordered_node_index

    return None, None


async def get_full_trip_route(driver_lat: float, driver_lng: float, active_passengers: list[dict], new_passenger: dict = None):
    # 1. Oblicz optymalną kolejność punktów (OR-Tools)
    ordered_coords, pickup_idx = await solve_optimal_order((driver_lat, driver_lng), active_passengers, new_passenger)

    print(f"Ordered coords: {ordered_coords}")
    print(f"Pickup index: {pickup_idx}")

    if not ordered_coords:
        return None

    # 2. Ostatni punkt to cel, reszta to waypoints
    final_dest = ordered_coords.pop()

    # 3. Pobierz jedną, finalną polilinię z Routes API
    return await get_directions(
        origin_lat=driver_lat,
        origin_lng=driver_lng,
        dest_lat=final_dest[0],
        dest_lng=final_dest[1],
        waypoints=ordered_coords,
        pickup_index=pickup_idx
    )

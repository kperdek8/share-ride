from datetime import datetime, timezone

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
        # "polylineQuality": "HIGH_QUALITY", # Na razie wyłączę, zwykła precyzja chyba wystarczy
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
            status = entry.get("status", {})
            if status and status.get("code") is not None and status.get("code") != 0:
                duration = 999999  # "Infinity" dla OR-Tools
            else:
                # Czas jest zwracany jako string "123s"
                duration = int(entry["duration"].rstrip('s'))

            i = entry["originIndex"]
            j = entry["destinationIndex"]
            matrix[i][j] = duration

        print("MACIERZ")
        print(matrix)
        return matrix


async def solve_optimal_order(driver_coords, passengers, use_soft_deadlines=False):
    """
    driver_coords: (lat, lng)
    passengers: list[dict] -> [{"p_lat":..., "p_lng":..., "d_lat":..., "d_lng":..., "picked_up": bool, "deadline": datetime}]
    use_soft_deadlines: bool - czy użyć miękkich deadline'ów (używane przy rekalkulacji trasy, która musi zwrócić trasę)
    """
    # 1. Tworzymy listę wszystkich fizycznych lokalizacji
    # Punkt 0: Kierowca (Start)
    now = datetime.now(timezone.utc)
    locations = [driver_coords]
    pickup_delivery_pairs = []
    dropoff_constraints = []  # Lista krotek: (dropoff_node_idx, deadline_delta_seconds)

    current_idx = 1

    for p in passengers:
        p_idx = None

        # Sprawdzenie deadline'u
        deadline = p["deadline"].replace(tzinfo=timezone.utc) if p["deadline"].tzinfo is None else p["deadline"]
        time_left_seconds = (deadline - now).total_seconds()
        # Jeśli deadline już minął, trasa jest niemożliwa
        if time_left_seconds < 0:
            print(f"Deadline pasażera {p.get('passenger_id')} już minął ({time_left_seconds}s).")
            return None

        # Jeśli pasażer nie jest w aucie, musi mieć Pickup
        if not p["picked_up"]:
            locations.append((p["p_lat"], p["p_lng"]))
            p_idx = current_idx
            current_idx += 1

        # Każdy pasażer musi mieć Dropoff
        locations.append((p["d_lat"], p["d_lng"]))
        d_idx = current_idx

        # Zapisujemy, że ten węzeł (d_idx) ma konkretny limit czasu
        dropoff_constraints.append((d_idx, int(time_left_seconds)))

        current_idx += 1

        if p_idx is not None:
            pickup_delivery_pairs.append((p_idx, d_idx))

    # 2. Pobieramy macierz odległości (Distance Matrix API)
    dist_matrix = await get_distance_matrix(locations)

    # 3. Konfiguracja OR-Tools
    manager = pywrapcp.RoutingIndexManager(len(locations), 1, 0)
    routing = pywrapcp.RoutingModel(manager)

    def time_callback(from_index, to_index):
        from_node = manager.IndexToNode(from_index)
        to_node = manager.IndexToNode(to_index)
        return dist_matrix[from_node][to_node]

    transit_callback_index = routing.RegisterTransitCallback(time_callback)
    routing.SetArcCostEvaluatorOfAllVehicles(transit_callback_index)

    # Dodanie wymiaru odległości/czasu dla restrykcji
    routing.AddDimension(
        transit_callback_index,
        180,
        86400,
        True,
        "Time"
    )
    time_dimension = routing.GetDimensionOrDie("Time")

    # Ograniczenia czasowe
    for node_idx, deadline_sec in dropoff_constraints:
        index = manager.NodeToIndex(node_idx)
        if use_soft_deadlines:
            time_dimension.CumulVar(index).SetRange(0, 86400)
            time_dimension.SetCumulVarSoftUpperBound(
                index,
                deadline_sec,
                100
            )
        else:
            # Jeśli nie zdążymy, nie chcemy dołączać pasażera.
            try:
                time_dimension.CumulVar(index).SetRange(0, deadline_sec)
            except Exception as e:
                print(f"Błąd ustawiania deadline'u: {e}")
                return None

    # Wymuszenie Pickup -> Delivery
    for p_idx, d_idx in pickup_delivery_pairs:
        pickup_index = manager.NodeToIndex(p_idx)
        delivery_index = manager.NodeToIndex(d_idx)
        routing.AddPickupAndDelivery(pickup_index, delivery_index)
        routing.solver().Add(
            time_dimension.CumulVar(pickup_index) <=
            time_dimension.CumulVar(delivery_index)
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
        index = routing.Start(0)
        while not routing.IsEnd(index):
            node_index = manager.IndexToNode(index)
            if node_index != 0:  # pomijamy pozycję kierowcy, bo to 'origin' w Routes API
                ordered_points.append(locations[node_index])
            index = solution.Value(routing.NextVar(index))

        print("PUNKTY")
        print(ordered_points)
        return ordered_points

    print("Nie znaleziono rozwiązania spełniającego deadline'y.")
    return None


async def get_full_trip_route(driver_lat: float, driver_lng: float, active_passengers: list[dict], recalculation: bool = False):
    # 1. Oblicz optymalną kolejność punktów (OR-Tools)
    ordered_coords = await solve_optimal_order((driver_lat, driver_lng), active_passengers, recalculation)

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
        waypoints=ordered_coords
    )
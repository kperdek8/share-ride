import math
from typing import List, Tuple, Dict
from pyproj import Transformer

# Funkcje pomocnicze


def dms_to_decimal(degrees: int, minutes: int, seconds: float) -> float:
    """
    Konwersja stopnie, minuty, sekundy do stopni dziesiętnych
    """
    return degrees + minutes/60 + seconds/3600


def gps_to_xy(lat: float, lon: float) -> Tuple[float, float]:
    """
    Konwersja współrzędnych geograficznych do płaszczyzny XY (w metrach)
    """
    transformer = Transformer.from_crs("epsg:4326", "epsg:3857", always_xy=True)
    x, y = transformer.transform(lon, lat)
    return x, y


def rectangle_from_segment(p1: Tuple[float, float], p2: Tuple[float, float], width: float) -> Tuple[Tuple[float, float], float, float, float]:
    """
    Tworzy prostokąt na podstawie odcinka P1-P2
    """
    cx = (p1[0] + p2[0]) / 2
    cy = (p1[1] + p2[1]) / 2
    length = math.hypot(p2[0] - p1[0], p2[1] - p1[1])
    angle_rad = math.atan2(p2[1] - p1[1], p2[0] - p1[0])
    return (cx, cy), length, width, angle_rad


def point_in_rectangle(px: float, py: float, rect_center: Tuple[float, float], length: float, width: float, angle_rad: float) -> bool:
    """
    Sprawdza czy punkt (px, py) znajduje się w prostokącie o danym środku, długości i szerokości, obróconym o kąt angle_rad.
    Prostokąt definiowany względem środka.
    """
    cx, cy = rect_center
    # Translacja punktu względem środka prostokąta
    tx = px - cx
    ty = py - cy
    # Rotacja punktu o -angle_rad, zastepuje rotacje prostokata
    rx = tx * math.cos(-angle_rad) - ty * math.sin(-angle_rad)
    ry = tx * math.sin(-angle_rad) + ty * math.cos(-angle_rad)
    return abs(rx) <= length / 2 and abs(ry) <= width / 2


def vector_angle(a: Tuple[float, float], b: Tuple[float, float]) -> float:
    """
    Oblicza kąt między wektorami a i b w stopniach
    """
    ax, ay = a
    bx, by = b
    dot = ax * bx + ay * by
    norm_a = math.sqrt(ax**2 + ay**2)
    norm_b = math.sqrt(bx**2 + by**2)

    if norm_a == 0 or norm_b == 0:
        return 0.0

    # Ze wzoru na kat miedzy wektorami
    # Funkcje min i max zapewniaja wartosc w przedziale [-1, 1], zapobiegajac bledom wynikajacych z obliczeniach zmiennoprzecinkowych
    cos_theta = max(min(dot / (norm_a * norm_b), 1.0), -1.0)
    return math.degrees(math.acos(cos_theta))


# Algorytm

def recommend_passengers(
        car_route: List[Tuple[float, float]],  # lista punktów GPS samochodu [(lat, lon), ...]
        passengers: List[Dict],  # lista {id, pickup, dropoff}
        car_capacity: int,
        current_passengers: int,
        X: float,
        alpha: float
) -> List[Dict]:
    """
    Zwraca liste potencjalnych pasażerów pasujacych do trasy z zadanymi parametrami
    """
    if current_passengers >= car_capacity:
        return []  # brak miejsc

    # Konwersja punktów trasy do XY
    route_xy = [gps_to_xy(lat, lon) for lat, lon in car_route]

    # Tworzenie prostokątów akceptowalnych odbiorów
    rectangles = []
    for i in range(len(route_xy) - 1):
        rect = rectangle_from_segment(route_xy[i], route_xy[i + 1], width=2 * X)
        rectangles.append(rect)

    recommended = []

    for passenger in passengers:
        # Konwersja punktów pasażera
        pickup = gps_to_xy(*passenger["pickup"])
        dropoff = gps_to_xy(*passenger["dropoff"])

        # Sprawdzenie czy pickup mieści się w którymkolwiek prostokącie
        in_rectangle = any(point_in_rectangle(pickup[0], pickup[1], rect[0], rect[1], rect[2], rect[3]) for rect in rectangles)
        if not in_rectangle:
            continue

        # Wektor pasażera i wektor do końcowego celu
        vec_passenger = (dropoff[0] - pickup[0], dropoff[1] - pickup[1])
        vec_route = (route_xy[-1][0] - pickup[0], route_xy[-1][1] - pickup[1])

        # Kąt między wektorami
        angle = vector_angle(vec_passenger, vec_route)
        if angle > alpha:
            continue

        # Jeśli przeszedł wszystkie filtry, dodaj do rekomendowanych
        recommended.append(passenger)

    return recommended

# Przykład


def example():
    # trasa samochodu
    car_route = [
        (51.076975, 17.018590),  # Weigla szpital
        (51.083763, 17.025022),  # Skrzyżowanie ślężna, armii krajowej
        (51.083117, 17.034614)   # Skrzyżowanie armii krajowej, borowska
    ]

    # potencjalni pasażerowie (pickup, dropoff)
    passengers = [
        {"id": "Passenger_A", "pickup": (51.084061, 17.023542), "dropoff": (51.083240, 17.031150)},  # al. Wiśniowa w stronę Borowskiej (powinno byc ok)
        {"id": "Passenger_B", "pickup": (51.084337, 17.025337), "dropoff": (51.089606, 17.028815)},  # Przystanek Wiśniowa, w stronę centrum (nie powinno byc ok)
        {"id": "Passenger_C", "pickup": (51.095192, 17.032845), "dropoff": (51.083240, 17.031150)},  # Wroclavia, w stronę Armii Krajowej (powinno być zależne od odległości maksymalnej)
        {"id": "Passenger_D", "pickup": (51.069050, 17.032286), "dropoff": (51.062502, 17.032432)}   # Wrocław Wojszyce w zupełnie inną stronę (za daleko i w złą stronę)
    ]

    recommended = recommend_passengers(
        car_route, passengers,
        car_capacity=3,
        current_passengers=1,
        X=1000,  # w metrach
        alpha=30  # w stopniach
    )

    return recommended


if __name__ == "__main__":
    recommended_passagers = example()
    print("Rekomendowani pasażerowie:")
    for p in recommended_passagers:
        print(p)



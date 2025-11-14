# mobilne_systemy_informatyczne
Aplikacja do przejazdów współdzielonych - ShareRide

## Struktura projektu

```
.
├── backend/          # FastAPI backend
├── frontend/         # Flutter frontend
└── docker-compose.yml
```

## Wymagania

- Docker
- Docker Compose

## Uruchomienie

Aby uruchomić całe środowisko:

```bash
docker-compose up --build
```

Serwisy będą dostępne pod adresami:
- Backend API: http://localhost:8000
- Frontend: http://localhost:3000
- PostgreSQL: localhost:5432
- MongoDB: localhost:27017

## Dokumentacja API

Po uruchomieniu backendu, dokumentacja API dostępna jest pod:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Zatrzymanie

```bash
docker-compose down
```



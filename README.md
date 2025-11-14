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

### Backend i bazy danych:
- Docker
- Docker Compose

### Frontend (Android):
- Flutter SDK (3.16.0 lub nowszy)
- Android Studio
- Android SDK (API 33)
- Java JDK 17

## Uruchomienie

### Backend i bazy danych

Aby uruchomić backend i bazy danych:

```bash
docker-compose up --build
```

Serwisy będą dostępne pod adresami:
- Backend API: http://localhost:8000
- PostgreSQL: localhost:5432
- MongoDB: localhost:27017

### Frontend (Android)

Aplikacja Flutter jest przeznaczona dla Androida. Aby uruchomić lokalnie:

1. Upewnij się, że masz zainstalowany Flutter:
```bash
flutter doctor
```

2. Przejdź do katalogu frontend:
```bash
cd frontend
```

3. Zainstaluj zależności:
```bash
flutter pub get
```

4. **Uruchom emulator Android lub podłącz urządzenie:**

   **Opcja A: Uruchomienie emulatora przez Android Studio**
   - Utwórz nowe urządzenie wirtualne (AVD) lub uruchom istniejące
   - Upewnij się, że emulator jest uruchomiony

 

   **Opcja B: Podłączenie urządzenia fizycznego**
   - Włącz opcje deweloperskie na urządzeniu Android
   - Włącz USB debugging
   - Podłącz urządzenie przez USB
   - Sprawdź połączenie:
   ```bash
   adb devices
   ```

5. Sprawdź dostępne urządzenia:
```bash
flutter devices
```

6. Uruchom aplikację:
```bash
flutter run
```

   Lub uruchom na konkretnym urządzeniu:
```bash
flutter run -d <device_id>
```

7. Aby zbudować APK:
```bash
flutter build apk --release
```

Zbudowany APK znajdziesz w: `frontend/build/app/outputs/flutter-apk/app-release.apk`

## Dokumentacja API

Po uruchomieniu backendu, dokumentacja API dostępna jest pod:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Zatrzymanie

Aby zatrzymać backend i bazy danych:

```bash
docker-compose down
```



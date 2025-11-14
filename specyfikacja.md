
# Mobilne systemy informatyczne

## Aplikacja do wspólnych przejazdów “ShareRide”

[**Opis rzeczywistości	2**](#opis-systemu)

[Środowisko działania	2](#środowisko-działania)

[Uczestnicy i ich cele	2](#uczestnicy-i-ich-cele)

[Procesy w systemie	2](#procesy-w-systemie)

[**Wymagania funkcjonalne i niefunkcjonalne	2**](#wymagania-funkcjonalne-i-niefunkcjonalne)

[Wymagania funkcjonalne	2](#wymagania-funkcjonalne)

[Wymagania niefunkcjonalne	3](#wymagania-niefunkcjonalne)

[**Architektura systemu	3**](#architektura-systemu)

[Architektura wysokopoziomowa	3](#architektura-wysokopoziomowa)

[Mikrousługi	3](#mikrousługi)

[Stos technologiczny	4](#stos-technologiczny)

[**Mockupy	5**](#mockupy)

[**Instrukcje dla użytkownika	5**](#instrukcje-dla-użytkownika)

[Pasażer	5](#pasażer)

[Kierowca	5](#kierowca)

# Opis systemu {#opis-systemu}

## Środowisko działania {#środowisko-działania}

* Aplikacja działa w środowisku mobilnym, wykorzystując dane GPS z urządzeń użytkowników.  
* System na bieżąco przetwarza duże ilości informacji o lokalizacjach, trasach, statusach przejazdów i płatnościach.  
* Wszystkie operacje takie jak wyszukiwanie, dopasowywanie tras czy aktualizacja pozycji pojazdów, muszą być wykonywane **n**a bieżąco i z zachowaniem wysokiej responsywności.

## Uczestnicy i ich cele {#uczestnicy-i-ich-cele}

* **Pasażerowie** dążą do taniego i szybkiego przejazdu, akceptując współdzielenie trasy.  
* **Kierowcy** chcą maksymalizować zysk, przewożąc kilku pasażerów w ramach jednego kursu.  
* **Administratorzy** dbają o poprawne działanie systemu, nadzorują przejazdy i rozstrzygają ewentualne spory.

## Procesy w systemie {#procesy-w-systemie}

* **Zamówienie przejazdu:** pasażer podaje punkt początkowy i końcowy, a system proponuje połączenia z innymi pasażerami.  
* **Dopasowanie tras:** algorytm łączy użytkowników o zbliżonych kierunkach i szacuje optymalną trasę.  
* **Akceptacja przejazdu:** pasażer może zaakceptować lub odrzucić wspólny kurs.  
* **Realizacja kursu:** kierowca otrzymuje trasę z kolejnością odbiorów i wysadzeń pasażerów.  
* **Monitorowanie:** pozycja pojazdu jest aktualizowana co kilka sekund, a pasażerowie mogą śledzić przejazd na mapie.  
* **Płatność:** po zakończeniu przejazdu system rozlicza płatności i nalicza prowizje.  
* **Oceny i opinie:** po kursie pasażerowie mogą wystawić ocenę.

# Wymagania funkcjonalne i niefunkcjonalne {#wymagania-funkcjonalne-i-niefunkcjonalne}

## Wymagania funkcjonalne {#wymagania-funkcjonalne}

**Funkcje dla pasażera:**

* Rejestracja i logowanie  
* Wybór między przejazdem solo a współdzielonym  
* Podgląd szacowanej ceny i czasu  
* Śledzenie lokalizacji kierowcy na mapie  
* Historia przejazdów  
* System ocen i opinii  
* Płatności (karta, BLIK, portfel w aplikacji)

**Funkcje dla kierowcy:**

* Rejestracja z weryfikacją (prawo jazdy, dane pojazdu)  
* Przyjmowanie zleceń  
* Nawigacja z kolejnością punktów odbioru/wysadzenia  
* Podgląd zarobków w czasie rzeczywistym  
* Ustawienia dostępności i preferencji

**Dla administratora:**

* Panel zarządzania użytkownikami  
* Monitoring aktywnych przejazdów  
* Rozwiązywanie sporów  
* Analityka i raporty  
* Zarządzanie cenami i prowizjami

## Wymagania niefunkcjonalne {#wymagania-niefunkcjonalne}

* **Wydajność:** Czas odpowiedzi systemu \< 2s dla wyszukiwania przejazdów  
* **Skalowalność:** Obsługa wielu użytkowników jednocześnie   
* **Dostępność:** 99.9% uptime  
* **Bezpieczeństwo:** Szyfrowanie danych, bezpieczne płatności, weryfikacja kierowców  
* **Lokalizacja:** GPS z dokładnością \< 10m

# Architektura systemu {#architektura-systemu}

## Architektura wysokopoziomowa {#architektura-wysokopoziomowa}

![][image1]  
Rys 1\. Architektura systemu

## Mikrousługi {#mikrousługi}

**User Service**

* Zarządzanie kontami użytkowników  
* Autentykacja i autoryzacja (JWT)  
* Profile pasażerów i kierowców

**Ride Matching Service**

* Algorytm dopasowywania tras  
* Optymalizacja wielopunktowych przejazdów  
* Obliczanie detali czasowych

**Location Service**

* Śledzenie lokalizacji w czasie rzeczywistym  
* Integracja z mapami

**Pricing Service**

* Dynamiczne kalkulacje cen  
* Rabaty za współdzielenie

**Payment Service**

* Integracja z bramkami płatności  
* Rozliczenia kierowców  
* Historia transakcji

**Notification Service**

* Powiadomienia push  
* SMS/Email

**Trip Service**

* Zarządzanie aktywnymi przejazdami  
* Historia przejazdów  
* Statusy realizacji

**Review Service**

* System ocen  
* Opinie i komentarze  
* Reputacja użytkowników

## Stos technologiczny {#stos-technologiczny}

**Backend**

* Python (FastAPI)

**Frontend**

* Flutter

**Mapy i geolokalizacja**

* Google Maps SDK \- wizualizacja tras, obliczanie odległości, szacowanie czasu przejazdu 

**API Gateway**

* Kong \- routing, uwierzytelnianie, kontrola dostępu

**Message broker**

* Kafka \- Strumienie zdarzeń: aktualizacje lokalizacji pojazdów, statusy przejazdów, komunikaty o dopasowaniu tras.  
* RabbitMQ \- Zadania asynchroniczne: wysyłka powiadomień, rozliczenia płatności, generowanie raportów.

**Bazy danych**

* PostgreSQL  
* MongoDB

# Mockupy {#mockupy}

Link do figmy (prototyp) [https://www.figma.com/proto/qV9fpVxzTayCUlbJ0UufMp/Share\_ride\_mobilne\_systemy?node-id=0-1\&t=ttg0yuQ96bns4VxV-1](https://www.figma.com/proto/qV9fpVxzTayCUlbJ0UufMp/Share_ride_mobilne_systemy?node-id=0-1&t=ttg0yuQ96bns4VxV-1)   
Mockupy jako załącznik do dokumentacji

# Instrukcje dla użytkownika {#instrukcje-dla-użytkownika}

## Pasażer {#pasażer}

1. Uruchom aplikację ShareRide.  
2. Wybierz opcję „Zarejestruj się” lub „Zaloguj się”.  
3. Uzupełnij dane profilu (imię, nazwisko, e-mail, numer telefonu).  
4. Dodaj metodę płatności (karta, BLIK lub portfel aplikacji).  
5. Na ekranie głównym wprowadź:  
   * punkt początkowy.  
   * punkt docelowy.  
6. Wybierz typ przejazdu:  
   * Solo \- klasyczny przejazd bez innych pasażerów.  
   * Współdzielony \- system dobierze innych pasażerów o zbliżonej trasie.  
7. Potwierdź zamówienie.  
8. Poczekaj na dopasowanie kierowcy.  
9. Otrzymasz powiadomienie z:  
   * nazwą kierowcy.  
   * numerem rejestracyjnym pojazdu.  
   * szacowanym czasem przyjazdu.  
10. Śledź pozycję kierowcy na mapie.  
11. Wsiądź do pojazdu po potwierdzeniu tożsamości kierowcy.  
12. Po zakończeniu kursu:  
    * płatność zostanie pobrana automatycznie.  
    * możesz wystawić ocenę i opinię.

## Kierowca {#kierowca}

1. Uruchom aplikację ShareRide – Kierowca.  
2. Wybierz „Zarejestruj się” lub „Zaloguj się”.  
3. Wprowadź dane (imię i nazwisko, dane pojazdu, numer prawa jazdy)  
4. Poczekaj na weryfikację konta przez administratora.  
5. Ustal swoją dostępność (status „Online” / „Offline”).  
6. Po otrzymaniu propozycji kursu:  
   * sprawdź trasę i pasażerów.  
   * zaakceptuj zlecenie.  
7. Postępuj zgodnie z nawigacją w aplikacji.  
8. Odbierz pasażerów według kolejności wskazanej przez system.  
9. Po zakończeniu przejazdu:  
   * kurs zostanie automatycznie rozliczony.  
   * możesz sprawdzić zarobek w zakładce „Moje kursy”.

[image1]: <data:image/png;base64,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>
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

/// Serwis do komunikacji z Matching Service
class MatchingService {
  /// Konwertuje adres na współrzędne geograficzne używając backendu
  static Future<Map<String, double>?> _geocodeAddress(String address) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/geocode');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'address': address,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout podczas geocoding');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final coords = {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
        };
        print('Geocoding sukces: $address -> (${coords['lat']}, ${coords['lng']})');
        return coords;
      } else {
        print('Geocoding błąd: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Błąd geocoding adresu "$address": $e');
      return null;
    }
  }

  /// Wyszukuje dostępne przejazdy na podstawie adresów
  /// 
  /// [fromAddress] - adres początkowy
  /// [toAddress] - adres docelowy
  /// 
  /// Zwraca listę ofert przejazdów w formacie zgodnym z UI
  static Future<List<Map<String, dynamic>>> searchRides({
    required String fromAddress,
    required String toAddress,
  }) async {
    try {
      // 1. Konwersja adresów na współrzędne
      print('Geocoding adresu początkowego: $fromAddress');
      final fromCoords = await _geocodeAddress(fromAddress);
      print('Geocoding adresu docelowego: $toAddress');
      final toCoords = await _geocodeAddress(toAddress);

      if (fromCoords == null || toCoords == null) {
        print('Błąd: Nie udało się znaleźć współrzędnych');
        print('From coords: $fromCoords, To coords: $toCoords');
        throw Exception('Nie udało się znaleźć współrzędnych dla adresów. Sprawdź czy adresy są poprawne.');
      }
      
      print('Współrzędne: from=(${fromCoords['lat']}, ${fromCoords['lng']}), to=(${toCoords['lat']}, ${toCoords['lng']})');

      // 2. Wywołanie Matching Service
      final url = Uri.parse('${ApiConfig.matchingServiceBaseUrl}/api/matching/offers');
      print('Wywołanie Matching Service: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pickup_lat': fromCoords['lat'],
          'pickup_lng': fromCoords['lng'],
          'dropoff_lat': toCoords['lat'],
          'dropoff_lng': toCoords['lng'],
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout podczas wyszukiwania przejazdów');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> offers = jsonDecode(response.body);
        
        print('Matching Service zwrócił ${offers.length} ofert');
        print('Response body: ${response.body}');
        
        // Jeśli brak ofert, zwracamy pustą listę (nie rzucamy błędu)
        if (offers.isEmpty) {
          print('Brak dostępnych kierowców w okolicy');
          print('Możliwe przyczyny:');
          print('1. Brak kierowców w Redis (uruchom ./populate_drivers.sh)');
          print('2. Kierowcy są zbyt daleko (promień wyszukiwania: 5km)');
          print('3. Wszyscy kierowcy mają status inny niż AVAILABLE');
          return [];
        }
        
        // 3. Mapowanie odpowiedzi na format oczekiwany przez UI
        return offers.map((offer) {
          final driverId = offer['driver_id'] as String;
          
          // Mock danych kierowcy na podstawie driver_id
          final mockDriverData = _getMockDriverData(driverId);
          
          // Bezpieczne wycięcie substring - użyj całego driver_id jeśli jest krótszy niż 8 znaków
          final rideIdSuffix = driverId.length >= 8 
              ? driverId.substring(0, 8).toUpperCase()
              : driverId.toUpperCase();
          
          // Sprawdź czy przejazd jest współdzielony
          final isShared = offer['is_shared'] as bool? ?? false;
          final sharedPassengers = offer['shared_passengers'] as int? ?? 0;
          
          return {
            'ride_id': 'RIDE-$rideIdSuffix',
            'is_shared': isShared,
            'shared_passengers': isShared ? sharedPassengers : null,
            'driver_first_name': mockDriverData['first_name'],
            'driver_last_name': mockDriverData['last_name'],
            'driver_rating': mockDriverData['rating'],
            'duration_minutes': offer['total_eta_minutes'] as int,
            'pickup_eta_minutes': offer['pickup_eta_minutes'] as int,
            'total_eta_minutes': offer['total_eta_minutes'] as int,
            'shared_extra_duration_minutes': isShared ? (offer['total_eta_minutes'] as int) ~/ 10 : 0,
            'distance_km': offer['distance_km'] as double,
            'price_pln': _calculatePrice(offer['distance_km'] as double, isShared: isShared),
            'shared_discount_pln': isShared ? _calculateDiscount(offer['distance_km'] as double) : 0.0,
            'polyline': offer['polyline'] as String?,
          };
        }).toList();
      } else {
        print('Błąd Matching Service: ${response.statusCode} - ${response.body}');
        throw Exception('Błąd podczas wyszukiwania przejazdów: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Błąd w MatchingService.searchRides: $e');
      rethrow;
    }
  }

  /// Zwraca mock dane kierowcy na podstawie driver_id
  static Map<String, dynamic> _getMockDriverData(String driverId) {
    // Prosta funkcja hash do generowania spójnych danych
    final hash = driverId.hashCode.abs();
    final names = [
      {'first': 'Jan', 'last': 'Kowalski'},
      {'first': 'Anna', 'last': 'Nowak'},
      {'first': 'Piotr', 'last': 'Wiśniewski'},
      {'first': 'Katarzyna', 'last': 'Zielińska'},
      {'first': 'Marek', 'last': 'Szymański'},
      {'first': 'Agnieszka', 'last': 'Wójcik'},
      {'first': 'Tomasz', 'last': 'Lewandowski'},
      {'first': 'Maria', 'last': 'Kowalczyk'},
    ];
    
    final nameIndex = hash % names.length;
    final rating = 4.0 + (hash % 10) / 10.0; // 4.0 - 4.9
    
    return {
      'first_name': names[nameIndex]['first']!,
      'last_name': names[nameIndex]['last']!,
      'rating': rating,
    };
  }

  /// Oblicza cenę przejazdu na podstawie dystansu
  static double _calculatePrice(double distanceKm, {bool isShared = false}) {
    // Prosta kalkulacja: 2.5 zł/km + 5 zł bazowej opłaty
    final basePrice = (distanceKm * 2.5) + 5.0;
    // Dla przejazdów współdzielonych obniżamy cenę o 20%
    return isShared ? basePrice * 0.8 : basePrice;
  }

  /// Oblicza zniżkę dla przejazdu współdzielonego
  static double _calculateDiscount(double distanceKm) {
    final basePrice = (distanceKm * 2.5) + 5.0;
    return basePrice * 0.2; // 20% zniżki
  }
}


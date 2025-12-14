import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

/// Serwis do komunikacji z Simulation Service
class SimulationService {
  /// Wysyła żądanie symulacji trasy
  /// 
  /// [fromAddress] - adres początkowy
  /// [toAddress] - adres docelowy
  /// 
  /// Zwraca odpowiedź z API lub null w przypadku błędu
  static Future<Map<String, dynamic>?> simulateRoute({
    required String fromAddress,
    required String toAddress,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/simulation/route');
      
      print('Wysyłanie żądania do: $url');
      print('Dane: from=$fromAddress, to=$toAddress');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from_address': fromAddress,
          'to_address': toAddress,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout - żądanie trwało zbyt długo');
        },
      );

      print('Odpowiedź: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Dane symulacji otrzymane pomyślnie');
        return data;
      } else {
        print('Błąd symulacji trasy: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Wyjątek podczas symulacji trasy: $e');
      rethrow; // Rzuć wyjątek dalej, aby frontend mógł go obsłużyć
    }
  }
}


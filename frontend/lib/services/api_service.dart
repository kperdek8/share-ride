import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Adres backendu - dla emulatora Android użyj 10.0.2.2 zamiast localhost
  // Dla urządzenia fizycznego użyj IP komputera (np. 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:8000'; // Emulator Android
  // static const String baseUrl = 'http://localhost:8000'; // Dla web/desktop
  // static const String baseUrl = 'http://192.168.1.100:8000'; // Urządzenie fizyczne

  // GET request - pobranie danych
  static Future<Map<String, dynamic>> getHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Błąd: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd połączenia: $e');
    }
  }

  // GET request - pobranie wiadomości
  static Future<Map<String, dynamic>> getRoot() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Błąd: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd połączenia: $e');
    }
  }

  // POST request - przykład wysłania danych
  static Future<Map<String, dynamic>> postData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/test'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Błąd: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd połączenia: $e');
    }
  }
}


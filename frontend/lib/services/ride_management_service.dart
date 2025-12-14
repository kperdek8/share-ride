import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

/// Serwis do komunikacji z Ride Management Service
class RideManagementService {
  /// Ustawia kierowcę jako dostępnego (przejście na online)
  /// 
  /// [driverId] - ID kierowcy
  /// [lat] - szerokość geograficzna
  /// [lng] - długość geograficzna
  /// 
  /// Zwraca true jeśli operacja się powiodła, false w przeciwnym razie
  static Future<bool> setDriverAvailable({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.rideManagementBaseUrl}/api/drivers/available');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'driver_id': driverId,
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Błąd ustawiania dostępności: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Wyjątek podczas ustawiania dostępności: $e');
      return false;
    }
  }

  /// Usuwa kierowcę z puli dostępnych (przejście na offline)
  /// 
  /// [driverId] - ID kierowcy
  /// 
  /// Zwraca true jeśli operacja się powiodła, false w przeciwnym razie
  static Future<bool> removeDriverAvailability(String driverId) async {
    try {
      final url = Uri.parse('${ApiConfig.rideManagementBaseUrl}/api/drivers/$driverId/available');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Błąd usuwania dostępności: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Wyjątek podczas usuwania dostępności: $e');
      return false;
    }
  }

  /// Aktualizuje status przejazdu
  /// 
  /// [rideId] - ID przejazdu
  /// [driverId] - ID kierowcy
  /// [newStatus] - nowy status (np. "active", "completed", "cancelled")
  /// 
  /// Zwraca true jeśli operacja się powiodła, false w przeciwnym razie
  static Future<bool> updateRideStatus({
    required String rideId,
    required String driverId,
    required String newStatus,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.rideManagementBaseUrl}/api/rides/$rideId/status');
      
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'driver_id': driverId,
          'new_status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Błąd aktualizacji statusu: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Wyjątek podczas aktualizacji statusu: $e');
      return false;
    }
  }
}


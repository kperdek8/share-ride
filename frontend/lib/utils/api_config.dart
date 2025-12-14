import 'dart:io';

/// Konfiguracja API - automatycznie wykrywa platformę i zwraca odpowiedni adres
class ApiConfig {
  /// Zwraca bazowy URL API w zależności od platformy
  /// 
  /// - Android emulator: używa `10.0.2.2` (alias dla localhost hosta)
  /// - iOS simulator: używa `localhost` (działa bezpośrednio)
  /// - Fizyczne urządzenia: używa IP komputera w sieci lokalnej
  /// 
  /// Możesz zmienić `baseUrl` na IP swojego komputera, jeśli używasz fizycznego urządzenia.
  static String get baseUrl {
    // Dla fizycznych urządzeń, zmień to na IP swojego komputera w sieci lokalnej
    // Np. 'http://192.168.1.100:8000'
    const String localNetworkIp = 'localhost'; // Zmień na IP komputera dla fizycznych urządzeń
    
    if (Platform.isAndroid) {
      // Emulator Android używa 10.0.2.2 jako alias dla localhost hosta
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS Simulator może używać localhost bezpośrednio
      return 'http://localhost:8000';
    } else {
      // Dla innych platform (web, desktop) używaj localhost
      return 'http://localhost:8000';
    }
  }
  
  /// Zwraca pełny URL do endpointu rides/short-term
  static String get ridesShortTermUrl => '$baseUrl/rides/short-term';
  
  /// Zwraca bazowy URL dla Ride Management Service (port 8002)
  static String get rideManagementBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8002';
    } else if (Platform.isIOS) {
      return 'http://localhost:8002';
    } else {
      return 'http://localhost:8002';
    }
  }
}


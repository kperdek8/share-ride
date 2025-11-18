import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../widgets/bottom_navigation_bar.dart';

class ActiveRideScreen extends StatefulWidget {
  final String driverName;
  final double driverRating;
  final String carModel;
  final String carPlate;
  final String estimatedTime;
  final String distance;
  final String cost;
  final String fromAddress;
  final String toAddress;

  const ActiveRideScreen({
    super.key,
    required this.driverName,
    required this.driverRating,
    required this.carModel,
    required this.carPlate,
    required this.estimatedTime,
    required this.distance,
    required this.cost,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

// Model danych trasy z Google Directions API
class RouteInfo {
  final List<LatLng> polylinePoints;
  final int durationSeconds; // Czas przejazdu w sekundach
  final int? durationInTrafficSeconds; // Czas przejazdu z korkami w sekundach
  final int distanceMeters; // Dystans w metrach
  final String summary; // Podsumowanie trasy (np. "A2, E30")
  final List<String> warnings; // Ostrzeżenia (korki, utrudnienia)
  final bool hasTolls; // Czy trasa zawiera opłaty drogowe

  RouteInfo({
    required this.polylinePoints,
    required this.durationSeconds,
    this.durationInTrafficSeconds,
    required this.distanceMeters,
    required this.summary,
    required this.warnings,
    required this.hasTolls,
  });
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _fromLocation;
  LatLng? _toLocation;
  RouteInfo? _routeInfo;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  // Klucz API Google Maps (używany również dla Directions API)
  static const String _googleMapsApiKey = 'PRZYKLADOWY_KLUCZ';

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _geocodeAddresses();
  }

  /// Dekoduje encoded polyline z Google Directions API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// Pobiera rzeczywistą trasę drogową z Google Directions API wraz z dodatkowymi informacjami
  Future<RouteInfo?> _getRouteInfo(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_googleMapsApiKey'
        '&language=pl'
        '&region=pl'
        '&departure_time=now' // Wymagane dla duration_in_traffic
        '&traffic_model=best_guess', // Model korków
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Dekoduj polyline
          final polyline = route['overview_polyline']['points'];
          final polylinePoints = _decodePolyline(polyline);
          
          // Pobierz czas przejazdu
          final duration = leg['duration']['value'] as int;
          final durationInTraffic = leg['duration_in_traffic']?['value'] as int?;
          
          // Pobierz dystans
          final distance = leg['distance']['value'] as int;
          
          // Pobierz podsumowanie trasy
          final summary = route['summary'] as String? ?? '';
          
          // Pobierz ostrzeżenia
          final warnings = <String>[];
          if (route['warnings'] != null) {
            warnings.addAll((route['warnings'] as List).cast<String>());
          }
          
          // Sprawdź czy trasa zawiera opłaty drogowe
          // Google Directions API może zwracać hasTolls w leg lub w steps
          bool hasTolls = false;
          if (leg['hasTolls'] != null) {
            hasTolls = leg['hasTolls'] as bool;
          } else if (leg['steps'] != null) {
            // Fallback: sprawdź w instrukcjach
            for (var step in leg['steps']) {
              if (step['html_instructions'] != null) {
                final instructions = step['html_instructions'].toString().toLowerCase();
                if (instructions.contains('opłata') || 
                    instructions.contains('toll') ||
                    instructions.contains('płatna')) {
                  hasTolls = true;
                  break;
                }
              }
            }
          }
          
          return RouteInfo(
            polylinePoints: polylinePoints,
            durationSeconds: duration,
            durationInTrafficSeconds: durationInTraffic,
            distanceMeters: distance,
            summary: summary,
            warnings: warnings,
            hasTolls: hasTolls,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    // Sprawdź uprawnienia
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingLocation = false;
      });
      return;
    }

    // Pobierz aktualną lokalizację
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Błąd pobierania lokalizacji - kontynuuj z geocodingiem adresów
    }
  }

  Future<void> _geocodeAddresses() async {
    try {
      // Geocoding adresu startowego
      List<Location> fromLocations = await locationFromAddress(widget.fromAddress);
      if (fromLocations.isNotEmpty) {
        _fromLocation = LatLng(
          fromLocations.first.latitude,
          fromLocations.first.longitude,
        );
      }

      // Geocoding adresu docelowego
      List<Location> toLocations = await locationFromAddress(widget.toAddress);
      if (toLocations.isNotEmpty) {
        _toLocation = LatLng(
          toLocations.first.latitude,
          toLocations.first.longitude,
        );
      }

      // Jeśli mamy oba adresy, pobierz rzeczywistą trasę drogową
      if (_fromLocation != null && _toLocation != null) {
        // Pobierz rzeczywistą trasę drogową z Google Directions API wraz z informacjami
        _routeInfo = await _getRouteInfo(_fromLocation!, _toLocation!);
        
        setState(() {
          // Marker punktu startowego (zielony)
          _markers.add(
            Marker(
              markerId: const MarkerId('from_location'),
              position: _fromLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: 'Skąd', snippet: widget.fromAddress),
            ),
          );

          // Marker punktu docelowego (czerwony)
          _markers.add(
            Marker(
              markerId: const MarkerId('to_location'),
              position: _toLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(title: 'Dokąd', snippet: widget.toAddress),
            ),
          );

          // Rzeczywista trasa drogowa lub prosta linia jako fallback
          if (_routeInfo != null && _routeInfo!.polylinePoints.isNotEmpty) {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routeInfo!.polylinePoints,
                color: const Color(0xFF155DFC),
                width: 5,
                patterns: [],
                geodesic: true,
              ),
            );
          } else {
            // Fallback: prosta linia jeśli nie udało się pobrać trasy
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: [_fromLocation!, _toLocation!],
                color: const Color(0xFF155DFC),
                width: 4,
              ),
            );
          }

          _isLoadingLocation = false;
        });

        // Wyśrodkuj mapę tak, aby pokazywała oba punkty
        _fitBounds();
      } else {
        // Jeśli nie udało się zgeocodować adresów, użyj aktualnej lokalizacji
        if (_currentPosition != null) {
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId('current_location'),
                position: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: const InfoWindow(title: 'Twoja lokalizacja'),
              ),
            );
            _isLoadingLocation = false;
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              15.0,
            ),
          );
        } else {
          setState(() {
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      // Błąd geocodingu - użyj aktualnej lokalizacji jako fallback
      if (_currentPosition != null) {
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'Twoja lokalizacja'),
            ),
          );
          _isLoadingLocation = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            15.0,
          ),
        );
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _fitBounds() {
    if (_fromLocation != null && _toLocation != null && _mapController != null) {
      // Oblicz granice zawierające oba punkty
      double minLat = _fromLocation!.latitude < _toLocation!.latitude
          ? _fromLocation!.latitude
          : _toLocation!.latitude;
      double maxLat = _fromLocation!.latitude > _toLocation!.latitude
          ? _fromLocation!.latitude
          : _toLocation!.latitude;
      double minLng = _fromLocation!.longitude < _toLocation!.longitude
          ? _fromLocation!.longitude
          : _toLocation!.longitude;
      double maxLng = _fromLocation!.longitude > _toLocation!.longitude
          ? _fromLocation!.longitude
          : _toLocation!.longitude;

      // Dodaj padding
      double latPadding = (maxLat - minLat) * 0.3;
      double lngPadding = (maxLng - minLng) * 0.3;

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat - latPadding, minLng - lngPadding),
        northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Mapa z trasą
          _buildMapSection(),
          // Karty z informacjami
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Karta kierowcy
                  _buildDriverCard(),
                  const SizedBox(height: 16),
                  // Karta z informacjami o trasie (korki, utrudnienia)
                  if (_routeInfo != null) ...[
                    _buildRouteTrafficCard(),
                    const SizedBox(height: 16),
                  ],
                  // Karta z informacjami o przejeździe
                  _buildRideInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 384,
      width: double.infinity,
      child: Stack(
        children: [
          // Mapa Google Maps
          _isLoadingLocation || (_fromLocation == null && _toLocation == null && _currentPosition == null)
              ? Container(
                  color: const Color(0xFFEFF6FF),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF155DFC),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Ładowanie mapy...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF717182),
                            letterSpacing: -0.31,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Po utworzeniu mapy, wyśrodkuj na trasie jeśli mamy adresy
                    if (_fromLocation != null && _toLocation != null) {
                      _fitBounds();
                    } else if (_currentPosition != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          15.0,
                        ),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _fromLocation ?? 
                        (_currentPosition != null 
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : const LatLng(52.2297, 21.0122)), // Warszawa jako domyślna
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                ),
          // Overlay z informacją
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 16,
                    color: Color(0xFF155DFC),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kierowca jedzie po Ciebie',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    final initials = widget.driverName.split(' ').map((n) => n[0]).join();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          // Avatar kierowcy
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF155DFC),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  letterSpacing: -0.31,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Informacje o kierowcy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.31,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFF0B100),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.driverRating.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFFF0B100),
                        letterSpacing: -0.31,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.carModel} • ${widget.carPlate}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF717182),
                    letterSpacing: -0.31,
                  ),
                ),
              ],
            ),
          ),
          // Przyciski telefonu i wiadomości
          Row(
            children: [
              _buildActionButton(
                icon: Icons.phone,
                onPressed: () {
                  // TODO: Implementacja dzwonienia
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.message,
                onPressed: () {
                  // TODO: Implementacja wiadomości
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: const Color(0xFF0A0A0A)),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildRouteTrafficCard() {
    if (_routeInfo == null) return const SizedBox.shrink();

    final route = _routeInfo!;
    final hasTrafficDelay = route.durationInTrafficSeconds != null &&
        route.durationInTrafficSeconds! > route.durationSeconds;
    
    // Oblicz czas korka (różnica między czasem z korkami a czasem normalnym)
    final trafficDelayMinutes = hasTrafficDelay
        ? ((route.durationInTrafficSeconds! - route.durationSeconds) / 60).round()
        : 0;
    
    // Parsuj szacowany czas z widget.estimatedTime (np. "15 min" -> 15)
    int estimatedMinutes = 0;
    try {
      final match = RegExp(r'(\d+)').firstMatch(widget.estimatedTime);
      if (match != null) {
        estimatedMinutes = int.parse(match.group(1)!);
      }
    } catch (e) {
      // Jeśli nie uda się sparsować, użyj 0
    }
    
    // Oblicz czas przejazdu z korkami = szacowany czas + czas korka
    final totalTimeWithTraffic = estimatedMinutes + trafficDelayMinutes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek
          const Row(
            children: [
              Icon(
                Icons.route,
                size: 20,
                color: Color(0xFF155DFC),
              ),
              SizedBox(width: 8),
              Text(
                'Informacje o trasie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Czas przejazdu z korkami
          if (route.durationInTrafficSeconds != null && hasTrafficDelay) ...[
            Row(
              children: [
                const Icon(
                  Icons.traffic,
                  size: 20,
                  color: Color(0xFFE7000B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Czas przejazdu z korkami',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF717182),
                          letterSpacing: -0.31,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$totalTimeWithTraffic min',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE7000B),
                              letterSpacing: -0.31,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7000B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+$trafficDelayMinutes min',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE7000B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (route.durationInTrafficSeconds != null && !hasTrafficDelay) ...[
            // Brak korków
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Color(0xFF00A63E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stan ruchu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF717182),
                          letterSpacing: -0.31,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Brak korków',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF00A63E),
                          letterSpacing: -0.31,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Opłaty drogowe
          if (route.hasTolls) ...[
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 20,
                  color: Color(0xFFF0B100),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trasa zawiera opłaty drogowe',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF717182),
                      letterSpacing: -0.31,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Podsumowanie trasy (główne drogi)
          if (route.summary.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.map,
                  size: 20,
                  color: Color(0xFF717182),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Główne drogi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF717182),
                          letterSpacing: -0.31,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0A0A0A),
                          letterSpacing: -0.31,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (route.warnings.isNotEmpty) const SizedBox(height: 12),
          ],
          
          // Ostrzeżenia i utrudnienia
          if (route.warnings.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Color(0xFFF0B100),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Utrudnienia',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF717182),
                          letterSpacing: -0.31,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...route.warnings.map((warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          warning,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF717182),
                            letterSpacing: -0.31,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Szacowany czas',
            value: widget.estimatedTime,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Dystans',
            value: widget.distance,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: null,
            label: 'Koszt przejazdu',
            value: widget.cost,
            valueColor: const Color(0xFF155DFC),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    IconData? icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF717182),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF717182),
                letterSpacing: -0.31,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: valueColor ?? const Color(0xFF0A0A0A),
            letterSpacing: -0.31,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}


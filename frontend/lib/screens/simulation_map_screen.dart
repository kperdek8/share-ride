import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class SimulationMapScreen extends StatefulWidget {
  final Map<String, dynamic> simulationData;
  final String fromAddress;
  final String toAddress;

  const SimulationMapScreen({
    super.key,
    required this.simulationData,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  State<SimulationMapScreen> createState() => _SimulationMapScreenState();
}

class _SimulationMapScreenState extends State<SimulationMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _fromLocation;
  LatLng? _toLocation;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _passengers = [];

  // Klucz API Google Maps
  static const String _googleMapsApiKey = 'PRZYKLADOWY_KLUCZ';

  @override
  void initState() {
    super.initState();
    _parseSimulationData();
    _initializeMap();
  }

  void _parseSimulationData() {
    try {
      // Parsowanie lokalizacji startowej i końcowej
      final fromLoc = widget.simulationData['from_location'] as Map<String, dynamic>;
      final toLoc = widget.simulationData['to_location'] as Map<String, dynamic>;
      
      _fromLocation = LatLng(
        (fromLoc['lat'] as num).toDouble(),
        (fromLoc['lng'] as num).toDouble(),
      );
      
      _toLocation = LatLng(
        (toLoc['lat'] as num).toDouble(),
        (toLoc['lng'] as num).toDouble(),
      );

      // Parsowanie kierowców
      _drivers = List<Map<String, dynamic>>.from(
        widget.simulationData['drivers'] as List,
      );

      // Parsowanie pasażerów
      _passengers = List<Map<String, dynamic>>.from(
        widget.simulationData['passengers'] as List,
      );
    } catch (e) {
      print('Błąd parsowania danych: $e');
    }
  }

  void _initializeMap() async {
    await _createMarkers();
    await _createPolylines();
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

  /// Pobiera rzeczywistą trasę drogową z Google Directions API
  Future<List<LatLng>?> _getRoutePolyline(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_googleMapsApiKey'
        '&language=pl'
        '&region=pl',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'] as String;
          return _decodePolyline(polyline);
        }
      }
      return null;
    } catch (e) {
      print('Błąd pobierania trasy: $e');
      return null;
    }
  }

  /// Tworzy niestandardową ikonę markera z Material Icon
  Future<BitmapDescriptor> _createCustomIcon({
    required IconData iconData,
    required Color color,
    required String label,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100.0;

    // Rysuj tło (okrąg)
    final Paint backgroundPaint = Paint()..color = color;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      backgroundPaint,
    );

    // Rysuj białą obwódkę
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      borderPaint,
    );

    // Rysuj ikonę
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 50.0,
          fontFamily: iconData.fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  /// Tworzy niestandardową ikonę kierowcy (samochód)
  Future<BitmapDescriptor> _createDriverIcon() async {
    return await _createCustomIcon(
      iconData: Icons.directions_car,
      color: Colors.blue,
      label: 'Kierowca',
    );
  }

  /// Tworzy niestandardową ikonę pasażera (osoba)
  Future<BitmapDescriptor> _createPassengerIcon() async {
    return await _createCustomIcon(
      iconData: Icons.person,
      color: Colors.orange,
      label: 'Pasażer',
    );
  }

  /// Tworzy niestandardową ikonę odbioru pasażera
  Future<BitmapDescriptor> _createPickupIcon() async {
    return await _createCustomIcon(
      iconData: Icons.arrow_upward,
      color: Colors.green,
      label: 'Odbór',
    );
  }

  /// Tworzy niestandardową ikonę wysadzenia pasażera
  Future<BitmapDescriptor> _createDropoffIcon() async {
    return await _createCustomIcon(
      iconData: Icons.arrow_downward,
      color: Colors.red,
      label: 'Wysadzenie',
    );
  }

  Future<void> _createMarkers() async {
    final markers = <Marker>{};
    
    // Tworzymy niestandardowe ikony
    final driverIcon = await _createDriverIcon();
    final passengerIcon = await _createPassengerIcon();
    final pickupIcon = await _createPickupIcon();
    final dropoffIcon = await _createDropoffIcon();

    // Marker punktu startowego (zielony)
    if (_fromLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: _fromLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Skąd',
            snippet: widget.fromAddress,
          ),
        ),
      );
    }

    // Marker punktu końcowego (czerwony)
    if (_toLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: _toLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Dokąd',
            snippet: widget.toAddress,
          ),
        ),
      );
    }

    // Markery kierowców (niebieskie z ikoną samochodu)
    for (int i = 0; i < _drivers.length; i++) {
      final driver = _drivers[i];
      final location = driver['location'] as Map<String, dynamic>;
      final lat = (location['lat'] as num).toDouble();
      final lng = (location['lng'] as num).toDouble();
      final firstName = driver['first_name'] as String;
      final lastName = driver['last_name'] as String;
      final rating = driver['rating'] as num;
      final vehicleModel = driver['vehicle_model'] as String? ?? 'Pojazd';
      final vehiclePlate = driver['vehicle_plate'] as String? ?? '';

      markers.add(
        Marker(
          markerId: MarkerId('driver_$i'),
          position: LatLng(lat, lng),
          icon: driverIcon,
          infoWindow: InfoWindow(
            title: 'Kierowca: $firstName $lastName',
            snippet: 'Ocena: ${rating.toStringAsFixed(1)} ⭐\n$vehicleModel ($vehiclePlate)',
          ),
        ),
      );
    }

    // Markery pasażerów (pomarańczowe)
    for (int i = 0; i < _passengers.length; i++) {
      final passenger = _passengers[i];
      final pickupLoc = passenger['pickup_location'] as Map<String, dynamic>;
      final dropoffLoc = passenger['dropoff_location'] as Map<String, dynamic>?;
      final firstName = passenger['first_name'] as String;
      final lastName = passenger['last_name'] as String;

      // Marker odbioru (zielona ikona strzałki w górę)
      markers.add(
        Marker(
          markerId: MarkerId('passenger_pickup_$i'),
          position: LatLng(
            (pickupLoc['lat'] as num).toDouble(),
            (pickupLoc['lng'] as num).toDouble(),
          ),
          icon: pickupIcon,
          infoWindow: InfoWindow(
            title: 'Odbór: $firstName $lastName',
            snippet: pickupLoc['address'] as String? ?? 'Punkt odbioru',
          ),
        ),
      );

      // Marker wysadzenia (czerwona ikona strzałki w dół)
      if (dropoffLoc != null) {
        markers.add(
          Marker(
            markerId: MarkerId('passenger_dropoff_$i'),
            position: LatLng(
              (dropoffLoc['lat'] as num).toDouble(),
              (dropoffLoc['lng'] as num).toDouble(),
            ),
            icon: dropoffIcon,
            infoWindow: InfoWindow(
              title: 'Wysadzenie: $firstName $lastName',
              snippet: dropoffLoc['address'] as String? ?? 'Punkt wysadzenia',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _createPolylines() async {
    final polylines = <Polyline>{};

    // Główna trasa między punktem startowym a końcowym
    if (_fromLocation != null && _toLocation != null) {
      // Pobierz rzeczywistą trasę drogową z Google Directions API
      final routePoints = await _getRoutePolyline(_fromLocation!, _toLocation!);
      
      if (routePoints != null && routePoints.isNotEmpty) {
        // Użyj rzeczywistej trasy drogowej
        polylines.add(
          Polyline(
            polylineId: const PolylineId('main_route'),
            points: routePoints,
            color: Colors.blue,
            width: 4,
            patterns: [],
            geodesic: true,
          ),
        );
      } else {
        // Fallback: prosta linia jeśli nie udało się pobrać trasy
        polylines.add(
          Polyline(
            polylineId: const PolylineId('main_route'),
            points: [_fromLocation!, _toLocation!],
            color: Colors.blue,
            width: 4,
            patterns: [],
          ),
        );
      }
    }

    // Trasy dla pasażerów (od odbioru do wysadzenia)
    for (int i = 0; i < _passengers.length; i++) {
      final passenger = _passengers[i];
      final pickupLoc = passenger['pickup_location'] as Map<String, dynamic>;
      final dropoffLoc = passenger['dropoff_location'] as Map<String, dynamic>?;

      if (dropoffLoc != null) {
        polylines.add(
          Polyline(
            polylineId: PolylineId('passenger_route_$i'),
            points: [
              LatLng(
                (pickupLoc['lat'] as num).toDouble(),
                (pickupLoc['lng'] as num).toDouble(),
              ),
              LatLng(
                (dropoffLoc['lat'] as num).toDouble(),
                (dropoffLoc['lng'] as num).toDouble(),
              ),
            ],
            color: Colors.orange.withOpacity(0.6),
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }

    setState(() {
      _polylines = polylines;
    });
  }

  void _fitBounds() {
    if (_mapController == null || _fromLocation == null || _toLocation == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        _fromLocation!.latitude < _toLocation!.latitude
            ? _fromLocation!.latitude
            : _toLocation!.latitude,
        _fromLocation!.longitude < _toLocation!.longitude
            ? _fromLocation!.longitude
            : _toLocation!.longitude,
      ),
      northeast: LatLng(
        _fromLocation!.latitude > _toLocation!.latitude
            ? _fromLocation!.latitude
            : _toLocation!.latitude,
        _fromLocation!.longitude > _toLocation!.longitude
            ? _fromLocation!.longitude
            : _toLocation!.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeId = widget.simulationData['route_id'] as String? ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A0A0A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Symulacja trasy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.31,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Mapa
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _fitBounds();
                    });
                  },
                  initialCameraPosition: CameraPosition(
                    target: _fromLocation ?? const LatLng(51.1079, 17.0385),
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                ),
                // Legenda
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendItem(Icons.location_on, Colors.green, 'Start'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Icons.location_on, Colors.red, 'Koniec'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Icons.directions_car, Colors.blue, 'Kierowca'),
                        const SizedBox(height: 8),
                        _buildLegendItem(Icons.person, Colors.orange, 'Pasażer'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Panel z informacjami
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID trasy
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: Color(0xFF155DFC), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ID trasy: $routeId',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Kierowcy
                    const Text(
                      'Dostępni kierowcy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._drivers.map((driver) => _buildDriverCard(driver)),
                    const SizedBox(height: 16),
                    // Pasażerowie
                    const Text(
                      'Pasażerowie na trasie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._passengers.map((passenger) => _buildPassengerCard(passenger)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF717182),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final firstName = driver['first_name'] as String;
    final lastName = driver['last_name'] as String;
    final rating = driver['rating'] as num;
    final vehicleModel = driver['vehicle_model'] as String? ?? 'Pojazd';
    final vehiclePlate = driver['vehicle_plate'] as String? ?? '';
    final location = driver['location'] as Map<String, dynamic>;
    final address = location['address'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF717182),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vehicleModel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF717182),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF717182),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              vehiclePlate,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(Map<String, dynamic> passenger) {
    final firstName = passenger['first_name'] as String;
    final lastName = passenger['last_name'] as String;
    final pickupLoc = passenger['pickup_location'] as Map<String, dynamic>;
    final dropoffLoc = passenger['dropoff_location'] as Map<String, dynamic>?;
    final pickupAddress = pickupLoc['address'] as String? ?? '';
    final dropoffAddress = dropoffLoc?['address'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pickupAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF717182),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (dropoffAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dropoffAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF717182),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


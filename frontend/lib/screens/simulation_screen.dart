import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'login_screen.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informacja o trybie DEV
            _buildDevInfoCard(),
            const SizedBox(height: 16),
            // Karta z polami adresów
            _buildAddressCard(),
            const SizedBox(height: 16),
            // Przycisk symulacji
            _buildSimulateButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0A0A0A)),
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        },
      ),
      title: const Text(
        'Symulacja (DEV)',
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
    );
  }

  Widget _buildDevInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFC107),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Color(0xFF856404),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tryb deweloperski',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF856404),
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ten ekran służy do symulacji przejazdów.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF856404),
                    letterSpacing: -0.15,
                    height: 1.43,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
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
          // Pole "Skąd"
          _buildAddressField(
            label: 'Skąd',
            controller: _fromController,
            hint: 'Wprowadź adres początkowy',
            icon: Icons.location_on,
            iconColor: Colors.green,
            showLocationButton: true,
            onLocationButtonPressed: _getCurrentLocation,
            isLoadingLocation: _isLoadingLocation,
          ),
          const SizedBox(height: 16),
          // Pole "Dokąd"
          _buildAddressField(
            label: 'Dokąd',
            controller: _toController,
            hint: 'Wprowadź adres docelowy',
            icon: Icons.location_on,
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    bool showLocationButton = false,
    VoidCallback? onLocationButtonPressed,
    bool isLoadingLocation = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.31,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFF717182),
                letterSpacing: -0.31,
              ),
              prefixIcon: Icon(icon, color: iconColor, size: 20),
              suffixIcon: showLocationButton
                  ? IconButton(
                      icon: isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF155DFC),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                              color: Color(0xFF155DFC),
                              size: 20,
                            ),
                      onPressed: isLoadingLocation ? null : onLocationButtonPressed,
                      tooltip: 'Użyj aktualnej lokalizacji',
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulateButton() {
    final bool canSimulate = _fromController.text.trim().isNotEmpty &&
        _toController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading || !canSimulate
            ? null
            : () {
                _simulateRide();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF155DFC),
          disabledBackgroundColor: const Color(0xFFCBCED4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Symuluj przejazd',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.31,
                ),
              ),
      ),
    );
  }

  Future<void> _simulateRide() async {
    setState(() {
      _isLoading = true;
    });

    // Symulacja opóźnienia
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // TODO: W przyszłości tutaj będzie wysyłane żądanie do backendu
    // Na razie tylko pokazujemy komunikat
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Symulacja: ${_fromController.text.trim()} → ${_toController.text.trim()}\n'
            'Żądanie do backendu będzie wysyłane w przyszłości.',
          ),
          backgroundColor: const Color(0xFF155DFC),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Pobiera aktualną lokalizację urządzenia i wypełnia pole "Skąd"
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Sprawdź uprawnienia
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Usługa lokalizacji jest wyłączona. Włącz ją w ustawieniach.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Brak uprawnień do lokalizacji.');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Uprawnienia do lokalizacji są trwale zablokowane. Włącz je w ustawieniach.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Pobierz aktualną lokalizację
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Konwertuj współrzędne na adres (reverse geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          // Formatuj adres
          String address = _formatAddress(place);
          _fromController.text = address;
        } else {
          // Jeśli nie udało się pobrać adresu, użyj współrzędnych
          _fromController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        // Jeśli reverse geocoding się nie powiódł, użyj współrzędnych
        _fromController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      _showErrorSnackBar('Błąd podczas pobierania lokalizacji: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Formatuje adres z Placemark na czytelny string
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
      addressParts.insert(0, place.subThoroughfare!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }

    return addressParts.join(', ');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


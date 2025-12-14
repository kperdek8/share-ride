import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/driver_bottom_navigation_bar.dart';
import '../services/ride_management_service.dart';
import 'driver_home_screen.dart';
import 'driver_active_ride_screen.dart';

class DriverWorkScreen extends StatefulWidget {
  const DriverWorkScreen({super.key});

  @override
  State<DriverWorkScreen> createState() => _DriverWorkScreenState();
}

class _DriverWorkScreenState extends State<DriverWorkScreen> {
  bool _isOnline = true;
  bool _sharedRidesEnabled = true;
  bool _isLoading = false;
  int _timerSeconds = 12;
  Timer? _timer;
  
  // TODO: Pobierz driver_id z systemu autentykacji
  final String _driverId = 'abcd1234';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Nagłówek zielony
          _buildHeader(),
          // Główna zawartość
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Karta z nowym zleceniem
                  _buildNewOrderCard(),
                  const SizedBox(height: 16),
                  // Karta z preferencjami
                  _buildPreferencesCard(),
                  const SizedBox(height: 16),
                  // Alert z wskazówką
                  _buildTipAlert(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DriverBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF00A63E),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Górna część z tytułem i przełącznikiem
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel kierowcy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.45,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOnline ? 'Jesteś online' : 'Jesteś offline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: -0.31,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        letterSpacing: -0.31,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _isOnline,
                      onChanged: _isLoading ? null : (value) async {
                        if (!value) {
                          // Przełączenie na offline - usuń dostępność i przejdź do ekranu początkowego
                          await _goOffline();
                        }
                      },
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF030213),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBCED4),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Statystyki
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Przejazdy', '8'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Zarobione', '347 zł'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Online', '4h 23m'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: -0.31,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              letterSpacing: -0.31,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF155DFC),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek z timerem
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nowe zlecenie!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.44,
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF155DFC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_timerSeconds}s',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      letterSpacing: -0.31,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Informacje o pasażerze
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'J',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF0A0A0A),
                          letterSpacing: -0.31,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jan K.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF0A0A0A),
                          letterSpacing: -0.31,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '★ 4.9',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF717182),
                          letterSpacing: -0.31,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '2 pasażerów',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1447E6),
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Trasa
          _buildRouteInfo(
            icon: Icons.location_on,
            iconColor: Colors.green,
            label: 'Odbiór',
            address: 'pl. Grunwaldzki',
          ),
          const SizedBox(height: 12),
          _buildRouteInfo(
            icon: Icons.location_on,
            iconColor: Colors.red,
            label: 'Cel',
            address: 'Port lotniczy Wrocław',
          ),
          const SizedBox(height: 16),
          // Statystyki przejazdu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRideStat(Icons.route, '12.3 km'),
                _buildRideStat(Icons.access_time, '15 min'),
                _buildRideStat(Icons.attach_money, '39.20 zł', textColor: const Color(0xFF00A63E)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Przyciski akcji
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implementacja odrzucenia zlecenia
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  child: const Text(
                    'Odrzuć',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Nawigacja do ekranu aktywnego przejazdu
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const DriverActiveRideScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A63E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  child: const Text(
                    'Akceptuj',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF717182),
                  letterSpacing: -0.31,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideStat(IconData icon, String text, {Color? textColor}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF717182)),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textColor ?? const Color(0xFF717182),
            letterSpacing: -0.31,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard() {
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
          const Text(
            'Preferencje',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 16),
          // Przejazdy współdzielone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Przejazdy współdzielone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.31,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Akceptuj wielu pasażerów',
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
              Switch(
                value: _sharedRidesEnabled,
                onChanged: (value) {
                  setState(() {
                    _sharedRidesEnabled = value;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF030213),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBCED4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Preferowany obszar
          _buildPreferenceRow(
            title: 'Preferowany obszar',
            value: 'Centrum miasta',
            onChanged: () {
              // TODO: Implementacja zmiany obszaru
            },
          ),
          const SizedBox(height: 16),
          // Maks. pasażerów
          _buildPreferenceRow(
            title: 'Maks. pasażerów',
            value: '4 osoby',
            onChanged: () {
              // TODO: Implementacja zmiany maks. pasażerów
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow({
    required String title,
    required String value,
    required VoidCallback onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF0A0A0A),
                letterSpacing: -0.31,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF717182),
                letterSpacing: -0.31,
              ),
            ),
          ],
        ),
        OutlinedButton(
          onPressed: onChanged,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Colors.black.withOpacity(0.1),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          ),
          child: const Text(
            'Zmień',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFBEDBFF),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Color(0xFF1C398E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wskazówka:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C398E),
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Przejazdy współdzielone mogą zwiększyć Twoje zarobki nawet o 40%!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF1C398E),
                    letterSpacing: -0.15,
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Przechodzi na tryb offline - usuwa dostępność kierowcy
  Future<void> _goOffline() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Usuń kierowcę z puli dostępnych
      bool success = await RideManagementService.removeDriverAvailability(_driverId);

      if (success) {
        // Przejście do ekranu początkowego
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DriverHomeScreen(),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Nie udało się przejść na tryb offline. Spróbuj ponownie.');
        setState(() {
          _isLoading = false;
          _isOnline = true; // Przywróć poprzedni stan
        });
      }
    } catch (e) {
      _showErrorSnackBar('Błąd podczas przechodzenia na tryb offline: $e');
      setState(() {
        _isLoading = false;
        _isOnline = true; // Przywróć poprzedni stan
      });
    }
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


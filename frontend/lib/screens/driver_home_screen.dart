import 'package:flutter/material.dart';
import '../widgets/driver_bottom_navigation_bar.dart';
import 'driver_work_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Nagłówek
          _buildHeader(),
          // Główna zawartość
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 404),
                  child: _buildOfflineCard(),
                ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF4A5565),
      ),
      child: SafeArea(
        child: Row(
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
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: -0.31,
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _isOnline,
                  onChanged: (value) {
                    if (value) {
                      // Przełączenie na online - przejście do ekranu startu pracy
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const DriverWorkScreen(),
                        ),
                      );
                    } else {
                      setState(() {
                        _isOnline = value;
                      });
                    }
                  },
                  activeColor: const Color(0xFF00A63E),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFCBCED4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikona
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              size: 32,
              color: Color(0xFF4A5565),
            ),
          ),
          const SizedBox(height: 16),
          // Tytuł
          const Text(
            'Jesteś offline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 8),
          // Opis
          const Text(
            'Włącz tryb online, aby zacząć otrzymywać zlecenia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF717182),
              letterSpacing: -0.31,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Przycisk "Przejdź online"
          SizedBox(
            width: 125,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                // Nawigacja do ekranu startu pracy
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const DriverWorkScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A63E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Przejdź online',
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
    );
  }
}


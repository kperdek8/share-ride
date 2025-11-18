import 'package:flutter/material.dart';
import '../widgets/driver_bottom_navigation_bar.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Zarobki',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.45,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0A0A0A)),
      ),
      body: const Center(
        child: Text(
          'Zarobki kierowcy',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF717182),
          ),
        ),
      ),
      bottomNavigationBar: const DriverBottomNavigationBar(currentIndex: 1),
    );
  }
}


import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/ride_search_card.dart';
import '../widgets/features_cards.dart';
import '../widgets/how_it_works_card.dart';
import '../widgets/recent_rides_section.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Nagłówek z powitaniem
              _buildHeader(),
              // Główna zawartość
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Karta wyszukiwania przejazdu (przesunięta w górę, aby nachodziła na nagłówek)
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: const RideSearchCard(),
                        ),
                        const SizedBox(height: 12),
                        // Karty funkcji
                        const FeaturesCards(),
                        const SizedBox(height: 12),
                        // Sekcja "Jak to działa?"
                        const HowItWorksCard(),
                        const SizedBox(height: 12),
                        // Ostatnie przejazdy
                        const RecentRidesSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF155DFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Witaj, Przemysław!',
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
            'Dokąd się wybierasz?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: -0.31,
            ),
          ),
        ],
      ),
    );
  }
}


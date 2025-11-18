import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/passenger_home_screen.dart';
import '../screens/passenger_history_screen.dart';
import '../screens/passenger_profile_screen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  // Funkcja pomocnicza do tworzenia płynnej animacji fade
  static PageRoute<T> _createFadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  final int currentIndex;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 0.71,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Główna',
            isSelected: currentIndex == 0,
            onTap: () {
              // Nawigacja do ekranu głównego pasażera
              if (currentIndex != 0) {
                Navigator.of(context).pushReplacement(
                  _createFadeRoute(const PassengerHomeScreen()),
                );
              }
            },
          ),
          _buildNavItem(
            icon: Icons.history,
            label: 'Historia',
            isSelected: currentIndex == 1,
            onTap: () {
              // Nawigacja do historii pasażera
              if (currentIndex != 1) {
                Navigator.of(context).pushReplacement(
                  _createFadeRoute(const PassengerHistoryScreen()),
                );
              }
            },
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Profil',
            isSelected: currentIndex == 2,
            onTap: () {
              // Nawigacja do profilu pasażera
              if (currentIndex != 2) {
                Navigator.of(context).pushReplacement(
                  _createFadeRoute(const PassengerProfileScreen()),
                );
              }
            },
          ),
          _buildNavItem(
            icon: Icons.logout,
            label: 'Wyloguj',
            isSelected: currentIndex == 3,
            onTap: () {
              // Nawigacja do ekranu logowania z usunięciem wszystkich poprzednich ekranów
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF155DFC) : const Color(0xFF4A5565),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isSelected ? const Color(0xFF155DFC) : const Color(0xFF4A5565),
                height: 1.33,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


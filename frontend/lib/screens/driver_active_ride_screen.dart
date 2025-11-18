import 'package:flutter/material.dart';
import '../widgets/driver_bottom_navigation_bar.dart';

class DriverActiveRideScreen extends StatelessWidget {
  const DriverActiveRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Mapa (placeholder)
          _buildMapSection(),
          // Główna zawartość
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Karta z aktualnym zadaniem
                  _buildCurrentTaskCard(),
                  const SizedBox(height: 16),
                  // Karta z pasażerami na pokładzie
                  _buildPassengersOnBoardCard(),
                  const SizedBox(height: 16),
                  // Karta z przebiegiem trasy
                  _buildRouteProgressCard(),
                  const SizedBox(height: 16),
                  // Karta z podsumowaniem
                  _buildSummaryCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DriverBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 384,
      width: double.infinity,
      color: const Color(0xFFEFF6FF),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.navigation,
                  size: 48,
                  color: Color(0xFF00A63E),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nawigacja do kolejnego punktu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF717182),
                    letterSpacing: -0.31,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dystans: 2.3 km • ~5 min',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.31,
                  ),
                ),
              ],
            ),
          ),
          // Przycisk z zarobkiem w prawym górnym rogu
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '+39.20 zł',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF00A63E),
                  letterSpacing: -0.31,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTaskCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00A63E),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek z krokiem
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A63E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Odbiór',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Jan K.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.31,
                    ),
                  ),
                ],
              ),
              const Text(
                'Krok 1 z 4',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF717182),
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Adres
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'pl. Grunwaldzki',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Przyciski akcji
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
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implementacja potwierdzenia wsiadnięcia pasażera
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Pasażer wsiadł',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A63E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
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

  Widget _buildPassengersOnBoardCard() {
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
            'Pasażerowie na pokładzie',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'JK',
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
                const Expanded(
                  child: Column(
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
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Na pokładzie',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteProgressCard() {
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
            'Przebieg trasy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 12),
          _buildRouteStep(
            stepNumber: 1,
            isActive: true,
            badge: 'Odbiór',
            badgeColor: const Color(0xFF00A63E),
            passengerName: 'Jan K.',
            address: 'pl. Grunwaldzki',
          ),
          const SizedBox(height: 12),
          _buildRouteStep(
            stepNumber: 2,
            isActive: false,
            badge: 'Odbiór',
            badgeColor: Colors.grey,
            passengerName: 'Maria K.',
            address: 'Galeria Dominikańska',
          ),
          const SizedBox(height: 12),
          _buildRouteStep(
            stepNumber: 3,
            isActive: false,
            badge: 'Wysadzenie',
            badgeColor: const Color(0xFF155DFC),
            passengerName: 'Maria K.',
            address: 'Rynek',
          ),
          const SizedBox(height: 12),
          _buildRouteStep(
            stepNumber: 4,
            isActive: false,
            badge: 'Wysadzenie',
            badgeColor: const Color(0xFF155DFC),
            passengerName: 'Jan K.',
            address: 'ul. Jana Pawła 22',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStep({
    required int stepNumber,
    required bool isActive,
    required String badge,
    required Color badgeColor,
    required String passengerName,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00A63E) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: isActive ? Colors.white : const Color(0xFF0A0A0A),
                letterSpacing: -0.31,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE8F5E9) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      passengerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.31,
                      ),
                    ),
                  ],
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
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
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
            'Podsumowanie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.44,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Dystans całkowity', '12.3 km'),
          const SizedBox(height: 8),
          _buildSummaryRow('Szacowany czas', '15 min'),
          const SizedBox(height: 8),
          _buildSummaryRow('Liczba pasażerów', '2'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Zarobek',
            '+39.20 zł',
            valueColor: const Color(0xFF00A63E),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.31,
          ),
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
}


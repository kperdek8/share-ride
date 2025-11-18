import 'package:flutter/material.dart';

class FeaturesCards extends StatelessWidget {
  const FeaturesCards({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 387.5),
      child: SizedBox(
        width: double.infinity,
        height: 121.4,
        child: Row(
        children: [
          // Karta "Współdziel przejazd"
          Expanded(
            child: _buildFeatureCard(
              icon: Icons.people,
              iconColor: const Color(0xFF155DFC),
              backgroundColor: const Color(0xFFEFF6FF),
              title: 'Współdziel przejazd',
            ),
          ),
          const SizedBox(width: 12),
          // Karta "Niższe koszty"
          Expanded(
            child: _buildFeatureCard(
              icon: Icons.trending_down,
              iconColor: Colors.green,
              backgroundColor: Colors.green.shade50,
              title: 'Niższe koszty',
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
  }) {
    return Container(
      height: 121.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 0.71,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF717182),
              letterSpacing: -0.31,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


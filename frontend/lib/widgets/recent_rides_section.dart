import 'package:flutter/material.dart';

class RecentRidesSection extends StatelessWidget {
  const RecentRidesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 387.5),
      child: SizedBox(
        width: double.infinity,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ostatnie przejazdy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0A0A0A),
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 12),
          _buildRideCard(
            route: 'Centrum → Lotnisko',
            date: '15 paź 2025, 14:30',
            price: '32,50 zł',
          ),
          const SizedBox(height: 12),
          _buildRideCard(
            route: 'Dworzec → Galeria',
            date: '12 paź 2025, 10:15',
            price: '18,00 zł',
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildRideCard({
    required String route,
    required String date,
    required String price,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 0.71,
        ),
      ),
      padding: const EdgeInsets.all(16.71),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.31,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF717182),
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.31,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '★★★★★',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFF0B100),
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


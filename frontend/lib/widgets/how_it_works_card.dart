import 'package:flutter/material.dart';

class HowItWorksCard extends StatelessWidget {
  const HowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 387),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF155DFC),
            Color(0xFF1447E6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 0.71,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jak to działa?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.44,
            ),
          ),
          const SizedBox(height: 12),
          _buildListItem(
            icon: Icons.access_time,
            text: 'System automatycznie łączy pasażerów jadących w podobnych kierunkach',
          ),
          const SizedBox(height: 8),
          _buildListItem(
            icon: Icons.trending_down,
            text: 'Im więcej pasażerów, tym niższa cena za osobę',
          ),
          const SizedBox(height: 8),
          _buildListItem(
            icon: Icons.people,
            text: 'Akceptuj lub odrzuć współpasażerów',
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              letterSpacing: -0.31,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import '../screens/book_ride_screen.dart';

class RideSearchCard extends StatefulWidget {
  const RideSearchCard({super.key});

  @override
  State<RideSearchCard> createState() => _RideSearchCardState();
}

class _RideSearchCardState extends State<RideSearchCard> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 387.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 0.71,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Pole "Skąd wyjeżdżasz?"
          _buildInputField(
            controller: _fromController,
            icon: Icons.location_on,
            iconColor: Colors.green,
            hint: 'Skąd wyjeżdżasz?',
          ),
          const SizedBox(height: 16),
          // Pole "Dokąd jedziesz?"
          _buildInputField(
            controller: _toController,
            icon: Icons.location_on,
            iconColor: Colors.red,
            hint: 'Dokąd jedziesz?',
          ),
          const SizedBox(height: 16),
          // Przycisk "Znajdź przejazd"
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                // Nawigacja do ekranu zamawiania przejazdu z przekazanymi danymi
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookRideScreen(
                      fromAddress: _fromController.text,
                      toAddress: _toController.text,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155DFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Znajdź przejazd',
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

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF0A0A0A),
                letterSpacing: -0.31,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF717182),
                  letterSpacing: -0.31,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


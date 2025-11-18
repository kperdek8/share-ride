import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'select_ride_screen.dart';

class BookRideScreen extends StatefulWidget {
  final String? fromAddress;
  final String? toAddress;

  const BookRideScreen({
    super.key,
    this.fromAddress,
    this.toAddress,
  });

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  bool _isSharedRide = false;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.fromAddress ?? '');
    _toController = TextEditingController(text: widget.toAddress ?? '');
    _fromController.addListener(() => setState(() {}));
    _toController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Karta z polami adresów
            _buildAddressCard(),
            const SizedBox(height: 16),
            // Karta z przełącznikiem współdzielonego przejazdu
            _buildSharedRideCard(),
            const SizedBox(height: 16),
            // Alert informacyjny
            _buildInfoAlert(),
            const SizedBox(height: 16),
            // Przycisk wyszukiwania
            _buildSearchButton(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0A0A0A)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Zarezerwuj przejazd',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF0A0A0A),
          letterSpacing: -0.31,
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.shade200,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
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
        children: [
          // Pole "Skąd"
          _buildAddressField(
            label: 'Skąd',
            controller: _fromController,
            hint: 'Wprowadź adres początkowy',
            icon: Icons.location_on,
            iconColor: Colors.green,
          ),
          const SizedBox(height: 16),
          // Pole "Dokąd"
          _buildAddressField(
            label: 'Dokąd',
            controller: _toController,
            hint: 'Wprowadź adres docelowy',
            icon: Icons.location_on,
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.15,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF717182),
                    letterSpacing: -0.31,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF717182),
                      letterSpacing: -0.31,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSharedRideCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Przejazd współdzielony',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.31,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Zaoszczędź dzięki współpasażerom',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF717182),
                  letterSpacing: -0.31,
                ),
              ),
            ],
          ),
          Switch(
            value: _isSharedRide,
            onChanged: (value) {
              setState(() {
                _isSharedRide = value;
              });
            },
            activeColor: const Color(0xFF155DFC),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoAlert() {
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
            child: Text(
              'System automatycznie dobierze pasażerów jadących w podobnym kierunku. Możesz zaakceptować lub odrzucić propozycję współdzielenia.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF1C398E),
                letterSpacing: -0.15,
                height: 1.43,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    final isEnabled = _fromController.text.isNotEmpty && 
                      _toController.text.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                // Nawigacja do ekranu wyboru przejazdu
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SelectRideScreen(
                      fromAddress: _fromController.text,
                      toAddress: _toController.text,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
              ? const Color(0xFF155DFC) 
              : const Color(0xFF155DFC).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Szukaj przejazdu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}


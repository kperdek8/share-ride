import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'active_ride_screen.dart';

class SelectRideScreen extends StatefulWidget {
  final String fromAddress;
  final String toAddress;

  const SelectRideScreen({
    super.key,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  State<SelectRideScreen> createState() => _SelectRideScreenState();
}

class _SelectRideScreenState extends State<SelectRideScreen> {
  int? _selectedRideIndex;
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.ridesShortTermUrl),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _rides = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Błąd podczas pobierania danych: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd połączenia: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Karta z trasą
                  _buildRouteCard(),
                  const SizedBox(height: 16),
                  // Nagłówek "Dostępne opcje"
                  const Text(
                    'Dostępne opcje',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.31,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lista opcji przejazdów
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF155DFC),
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFFE7000B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchRides,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF155DFC),
                              ),
                              child: const Text('Spróbuj ponownie'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_rides.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Brak dostępnych przejazdów',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF717182),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildRideOptions(),
                ],
              ),
            ),
          ),
          // Przycisk potwierdzenia
          _buildConfirmButton(),
        ],
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

  Widget _buildRouteCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linia z kropkami
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A63E),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 32,
                color: const Color(0xFFD1D5DC),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7000B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Adresy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fromAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: -0.31,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.toAddress,
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
        ],
      ),
    );
  }

  Widget _buildRideOptions() {
    return Column(
      children: _rides.asMap().entries.map((entry) {
        final index = entry.key;
        final ride = entry.value;
        
        // Mapowanie danych z API
        final driverFirstName = ride['driver_first_name'] as String? ?? '';
        final driverLastName = ride['driver_last_name'] as String? ?? '';
        // Format: "Imię N." (np. "Anna K.")
        final driver = driverLastName.isNotEmpty 
            ? '$driverFirstName ${driverLastName[0]}.'
            : driverFirstName;
        
        final isShared = ride['is_shared'] as bool? ?? false;
        final sharedPassengers = ride['shared_passengers'] as int?;
        final rating = (ride['driver_rating'] as num?)?.toDouble() ?? 0.0;
        final durationMinutes = ride['duration_minutes'] as int? ?? 0;
        final extraDurationMinutes = ride['shared_extra_duration_minutes'] as int? ?? 0;
        final pricePln = (ride['price_pln'] as num?)?.toDouble() ?? 0.0;
        final sharedDiscountPln = (ride['shared_discount_pln'] as num?)?.toDouble() ?? 0.0;
        
        // Formatowanie danych dla UI
        String title;
        if (isShared && sharedPassengers != null) {
          title = 'Współdzielony - $sharedPassengers ${sharedPassengers == 1 ? 'pasażer' : sharedPassengers < 5 ? 'pasażerów' : 'pasażerów'}';
        } else {
          title = 'Solo - tylko Ty';
        }
        
        final time = '$durationMinutes min';
        final extraTime = extraDurationMinutes > 0 ? '+$extraDurationMinutes min' : '+0 min';
        final price = '${pricePln.toStringAsFixed(2)} zł';
        
        String? originalPrice;
        String? discount;
        if (isShared && sharedDiscountPln > 0) {
          final originalPriceValue = pricePln + sharedDiscountPln;
          originalPrice = '${originalPriceValue.toStringAsFixed(2)} zł';
          final discountPercent = ((sharedDiscountPln / originalPriceValue) * 100).round();
          discount = '-$discountPercent%';
        }
        
        return Padding(
          padding: EdgeInsets.only(bottom: index < _rides.length - 1 ? 12 : 0),
          child: _buildRideOptionCard(
            index: index,
            title: title,
            driver: driver,
            rating: rating,
            time: time,
            extraTime: extraTime,
            price: price,
            originalPrice: originalPrice,
            discount: discount,
            isShared: isShared,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRideOptionCard({
    required int index,
    required String title,
    required String driver,
    required double rating,
    required String time,
    required String extraTime,
    required String price,
    String? originalPrice,
    String? discount,
    required bool isShared,
  }) {
    final isSelected = _selectedRideIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRideIndex = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF155DFC)
                : Colors.black.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Górna część z tytułem, kierowcą i ceną
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF0A0A0A),
                          letterSpacing: -0.31,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$driver • ★ $rating',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF717182),
                          letterSpacing: -0.31,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF155DFC),
                        letterSpacing: -0.31,
                      ),
                    ),
                    if (originalPrice != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        originalPrice,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF717182),
                          letterSpacing: -0.31,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dolna część z ikonami i informacjami
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.access_time,
                  text: time,
                ),
                _buildInfoItem(
                  icon: Icons.location_on,
                  text: extraTime,
                ),
                if (discount != null)
                  _buildInfoItem(
                    icon: Icons.percent,
                    text: discount,
                    textColor: const Color(0xFF00A63E),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    Color? textColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF717182),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textColor ?? const Color(0xFF717182),
            letterSpacing: -0.31,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final isEnabled = _selectedRideIndex != null && !_isLoading && _rides.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: ElevatedButton(
          onPressed: isEnabled
              ? () {
                  final selectedRide = _rides[_selectedRideIndex!];
                  
                  // Mapowanie danych z API
                  final driverFirstName = selectedRide['driver_first_name'] as String? ?? '';
                  final driverLastName = selectedRide['driver_last_name'] as String? ?? '';
                  final driverName = '$driverFirstName $driverLastName'.trim();
                  final driverRating = (selectedRide['driver_rating'] as num?)?.toDouble() ?? 0.0;
                  final durationMinutes = selectedRide['duration_minutes'] as int? ?? 0;
                  final pricePln = (selectedRide['price_pln'] as num?)?.toDouble() ?? 0.0;
                  
                  // Wartości domyślne dla brakujących danych
                  const carModel = 'Toyota Corolla';
                  const carPlate = 'WA 12345';
                  final estimatedTime = '$durationMinutes min';
                  const distance = '12.3 km'; // Można później dodać do API
                  final cost = '${pricePln.toStringAsFixed(2)} zł';
                  
                  // Nawigacja do ekranu aktywnego przejazdu
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ActiveRideScreen(
                        driverName: driverName,
                        driverRating: driverRating,
                        carModel: carModel,
                        carPlate: carPlate,
                        estimatedTime: estimatedTime,
                        distance: distance,
                        cost: cost,
                        fromAddress: widget.fromAddress,
                        toAddress: widget.toAddress,
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
            'Potwierdź rezerwację',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ),
    );
  }
}


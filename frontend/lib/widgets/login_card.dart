import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/passenger_home_screen.dart';
import '../screens/driver_home_screen.dart';
import '../screens/register_screen.dart';

class LoginCard extends StatefulWidget {
  final UserRole role;

  const LoginCard({
    super.key,
    required this.role,
  });

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final _emailController = TextEditingController(text: 'przemyslaw.sipa@test.pl');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPassenger = widget.role == UserRole.passenger;
    
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek karty
          _buildCardHeader(isPassenger),
          const SizedBox(height: 24),
          // Formularz
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildCardHeader(bool isPassenger) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPassenger ? 'Zaloguj się jako pasażer' : 'Zaloguj się jako kierowca',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.31,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isPassenger
              ? 'Znajdź przejazd i zaoszczędź na podróży'
              : 'Zarabiaj przewożąc pasażerów',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF717182),
            letterSpacing: -0.31,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pole Email/Telefon
        _buildInputField(
          label: 'Email lub telefon',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        // Pole Hasło
        _buildPasswordField(),
        const SizedBox(height: 16),
        // Przycisk logowania
        _buildLoginButton(),
        const SizedBox(height: 16),
        // Link rejestracji
        _buildRegistrationLink(),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
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
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF717182),
              letterSpacing: -0.31,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hasło',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0A0A0A),
            letterSpacing: -0.15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF717182),
              letterSpacing: -0.31,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: const Color(0xFF717182),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: () {
          // Nawigacja do odpowiedniego ekranu głównego po zalogowaniu
          if (widget.role == UserRole.passenger) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PassengerHomeScreen(),
              ),
            );
          } else if (widget.role == UserRole.driver) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const DriverHomeScreen(),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF155DFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Zaloguj się',
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

  Widget _buildRegistrationLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Nie masz konta?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF717182),
            letterSpacing: -0.31,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            // Nawigacja do ekranu rejestracji
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterScreen(),
              ),
            );
          },
          child: const Text(
            'Zarejestruj się',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF155DFC),
              letterSpacing: -0.31,
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/passenger_home_screen.dart';
import '../screens/driver_home_screen.dart';

class RegisterCard extends StatefulWidget {
  final UserRole role;

  const RegisterCard({
    super.key,
    required this.role,
  });

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          _buildRegisterForm(),
        ],
      ),
    );
  }

  Widget _buildCardHeader(bool isPassenger) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPassenger ? 'Zarejestruj się jako pasażer' : 'Zarejestruj się jako kierowca',
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
              ? 'Utwórz konto i zacznij korzystać z przejazdów'
              : 'Utwórz konto i zacznij zarabiać',
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

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pole Imię
        _buildInputField(
          label: 'Imię',
          controller: _firstNameController,
        ),
        const SizedBox(height: 8),
        // Pole Nazwisko
        _buildInputField(
          label: 'Nazwisko',
          controller: _lastNameController,
        ),
        const SizedBox(height: 8),
        // Pole Email
        _buildInputField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        // Pole Telefon
        _buildInputField(
          label: 'Telefon',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        // Pole Hasło
        _buildPasswordField(
          label: 'Hasło',
          controller: _passwordController,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        const SizedBox(height: 8),
        // Pole Potwierdź hasło
        _buildPasswordField(
          label: 'Potwierdź hasło',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        const SizedBox(height: 16),
        // Przycisk rejestracji
        _buildRegisterButton(),
        const SizedBox(height: 16),
        // Link logowania
        _buildLoginLink(),
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
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
            obscureText: obscureText,
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
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: const Color(0xFF717182),
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: () {
          // Nawigacja do odpowiedniego ekranu głównego po rejestracji
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
          'Zarejestruj się',
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Masz już konto?',
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
            // Nawigacja do ekranu logowania
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: const Text(
            'Zaloguj się',
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


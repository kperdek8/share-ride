import 'package:flutter/material.dart';
import '../widgets/role_tabs.dart';
import '../widgets/register_card.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserRole _selectedRole = UserRole.passenger;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo i nagłówek
                  _buildHeader(),
                  const SizedBox(height: 24),
                  // Zakładki i formularz rejestracji
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 409),
                    child: Column(
                      children: [
                        RoleTabs(
                          selectedRole: _selectedRole,
                          onRoleChanged: (role) {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        RegisterCard(role: _selectedRole),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF155DFC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_car,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        // Tytuł
        const Text(
          'ShareRide',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF155DFC),
            letterSpacing: -0.31,
          ),
        ),
        const SizedBox(height: 8),
        // Podtytuł
        const Text(
          'Współdziel przejazd, zaoszczędź więcej',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF717182),
            letterSpacing: -0.31,
          ),
        ),
      ],
    );
  }
}


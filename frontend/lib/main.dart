import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ShareRideApp());
}

class ShareRideApp extends StatelessWidget {
  const ShareRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareRide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF155DFC),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
      ),
      home: const LoginScreen(),
    );
  }
}


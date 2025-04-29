import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';

void main() {
  runApp(const JeevaniApp());
}

class JeevaniApp extends StatelessWidget {
  const JeevaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
      }
    );
  }
}

// Placeholder for BuyerDashboard (create this screen if it doesn't exist)

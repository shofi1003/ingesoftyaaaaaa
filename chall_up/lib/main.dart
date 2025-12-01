import 'package:flutter/material.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';

void main() {
  runApp(const ChallUpApp());
}

class ChallUpApp extends StatelessWidget {
  const ChallUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChallUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}

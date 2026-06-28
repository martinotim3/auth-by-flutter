import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('login_screen'),
      body: Center(child: Text('Login')),
    );
  }
}

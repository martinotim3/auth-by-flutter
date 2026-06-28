import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class RegisterScreen extends StatelessWidget {
  final AuthService authService;
  const RegisterScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('register_screen'),
      appBar: AppBar(title: const Text('Create Account')),
      body: const Center(child: Text('Register')),
    );
  }
}

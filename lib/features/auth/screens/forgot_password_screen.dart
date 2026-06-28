import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final AuthService authService;
  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('forgot_password_screen'),
      appBar: AppBar(title: const Text('Reset Password')),
      body: const Center(child: Text('Forgot Password')),
    );
  }
}

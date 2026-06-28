import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class UserHomeScreen extends StatelessWidget {
  final AuthService authService;
  const UserHomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('user_home_screen'),
      body: Center(child: Text('User Home')),
    );
  }
}

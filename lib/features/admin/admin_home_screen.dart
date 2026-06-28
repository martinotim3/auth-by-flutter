import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  final AuthService authService;
  const AdminHomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('admin_home_screen'),
      body: Center(child: Text('Admin Home')),
    );
  }
}

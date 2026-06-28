import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/widgets/auth_button.dart';

class AdminHomeScreen extends StatelessWidget {
  final AuthService authService;
  const AdminHomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('admin_home_screen'),
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Admin content goes here.'),
            const SizedBox(height: 24),
            AuthButton(
              label: 'Sign Out',
              onPressed: () async => authService.logout(),
            ),
          ],
        ),
      ),
    );
  }
}

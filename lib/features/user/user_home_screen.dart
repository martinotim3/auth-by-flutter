import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/widgets/auth_button.dart';

class UserHomeScreen extends StatelessWidget {
  final AuthService authService;
  const UserHomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('user_home_screen'),
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('User content goes here.'),
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

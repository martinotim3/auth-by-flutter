import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:auth/features/admin/admin_home_screen.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/screens/login_screen.dart';
import 'package:auth/features/user/user_home_screen.dart';

class App extends StatelessWidget {
  final AuthService authService;

  const App({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth App',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == null) {
            return LoginScreen(authService: authService);
          }
          return FutureBuilder<String>(
            future: authService.getRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (roleSnapshot.data == 'admin') {
                return AdminHomeScreen(authService: authService);
              }
              return UserHomeScreen(authService: authService);
            },
          );
        },
      ),
    );
  }
}

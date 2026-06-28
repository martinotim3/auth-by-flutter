import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:auth/app.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(App(authService: AuthService()));
}

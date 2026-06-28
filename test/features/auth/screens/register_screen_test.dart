import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/screens/register_screen.dart';
import 'package:auth/shared/services/firestore_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    final fakeFirestore = FakeFirebaseFirestore();
    final firestoreService = FirestoreService(firestore: fakeFirestore);
    final mockAuth = MockFirebaseAuth();
    authService = AuthService(auth: mockAuth, firestoreService: firestoreService);
  });

  Widget buildSubject() => MaterialApp(
        home: RegisterScreen(authService: authService),
      );

  testWidgets('renders Full Name, Email, Password, Confirm Password and Register', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('shows validation error when passwords do not match', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'different');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('shows Verify Your Email dialog on successful registration', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'new@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Verify Your Email'), findsOneWidget);
  });
}

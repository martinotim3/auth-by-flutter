import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/screens/forgot_password_screen.dart';
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
        home: ForgotPasswordScreen(authService: authService),
      );

  testWidgets('renders Email field and Send Reset Email button', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send Reset Email'), findsOneWidget);
  });

  testWidgets('shows validation error when email is empty', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Email'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('shows success SnackBar after sending reset email', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Password reset email sent. Check your inbox.'),
      findsOneWidget,
    );
  });
}

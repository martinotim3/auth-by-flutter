import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/screens/login_screen.dart';
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
        home: LoginScreen(authService: authService),
      );

  testWidgets('renders Email, Password fields and Sign In button', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('shows validation error when fields are empty on submit', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('shows SnackBar when login fails', (tester) async {
    // Use an unverified user — AuthService always throws AuthException for
    // unverified emails, making this reliable regardless of MockFirebaseAuth
    // behaviour with unknown users.
    final mockUser = MockUser(
      uid: 'uid123',
      email: 'unverified@example.com',
      isEmailVerified: false,
    );
    final mockAuthWithUser = MockFirebaseAuth(
      mockUser: mockUser,
      verifyEmailAutomatically: false,
    );
    await mockAuthWithUser.createUserWithEmailAndPassword(
      email: 'unverified@example.com',
      password: 'password123',
    );
    final fakeFirestore = FakeFirebaseFirestore();
    final firestoreService = FirestoreService(firestore: fakeFirestore);
    final localAuthService =
        AuthService(auth: mockAuthWithUser, firestoreService: firestoreService);

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(authService: localAuthService),
    ));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'unverified@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('shows Forgot Password and Register links', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/user/user_home_screen.dart';
import 'package:auth/shared/services/firestore_service.dart';

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    final fakeFirestore = FakeFirebaseFirestore();
    final firestoreService = FirestoreService(firestore: fakeFirestore);
    final mockUser = MockUser(uid: 'uid123', isEmailVerified: true);
    mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
    authService = AuthService(auth: mockAuth, firestoreService: firestoreService);
  });

  testWidgets('renders Home title', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: UserHomeScreen(authService: authService),
    ));
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('renders Sign Out button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: UserHomeScreen(authService: authService),
    ));
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('signs out when Sign Out is tapped', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: UserHomeScreen(authService: authService),
    ));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(mockAuth.currentUser, isNull);
  });
}

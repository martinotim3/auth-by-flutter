import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/app.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/shared/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  testWidgets('shows loading indicator on first frame before stream emits', (tester) async {
    final mockAuth = MockFirebaseAuth();
    final authService = AuthService(auth: mockAuth, firestoreService: firestoreService);
    await tester.pumpWidget(App(authService: authService));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows LoginScreen when user is signed out', (tester) async {
    final mockAuth = MockFirebaseAuth();
    final authService = AuthService(auth: mockAuth, firestoreService: firestoreService);
    await tester.pumpWidget(App(authService: authService));
    await tester.pump();
    expect(find.byKey(const Key('login_screen')), findsOneWidget);
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/shared/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('AuthService.register', () {
    test('creates Firestore user doc with role user on success', () async {
      final mockAuth = MockFirebaseAuth();
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      await service.register(
        email: 'new@example.com',
        password: 'password123',
        displayName: 'New User',
      );

      final doc = await fakeFirestore
          .collection('users')
          .doc(mockAuth.currentUser!.uid)
          .get();
      expect(doc.exists, true);
      expect(doc.data()!['role'], 'user');
      expect(doc.data()!['email'], 'new@example.com');
    });

    test('throws AuthException when email already in use', () async {
      // MockFirebaseAuth does not natively throw for duplicate emails.
      // Use mock_exceptions to configure the mock to throw FirebaseAuthException.
      final mockAuth = MockFirebaseAuth();
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      await expectLater(
        service.register(
          email: 'exists@example.com',
          password: 'password123',
          displayName: 'User',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService.login', () {
    test('signs in successfully when email is verified', () async {
      final mockUser = MockUser(
        uid: 'uid123',
        email: 'test@example.com',
        isEmailVerified: true,
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser);
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      await expectLater(
        service.login(email: 'test@example.com', password: 'password123'),
        completes,
      );
    });

    test('throws AuthException with verify message when email not verified', () async {
      final mockUser = MockUser(
        uid: 'uid123',
        email: 'unverified@example.com',
        isEmailVerified: false,
      );
      // verifyEmailAutomatically: false ensures createUserWithEmailAndPassword
      // creates a user with emailVerified = false, matching the test intent.
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, verifyEmailAutomatically: false);
      await mockAuth.createUserWithEmailAndPassword(
        email: 'unverified@example.com',
        password: 'password123',
      );
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      await expectLater(
        service.login(email: 'unverified@example.com', password: 'password123'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('verify your email'),
          ),
        ),
      );
    });
  });

  group('AuthService.logout', () {
    test('signs user out', () async {
      final mockUser = MockUser(uid: 'uid123', isEmailVerified: true);
      final mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      await service.logout();
      expect(mockAuth.currentUser, isNull);
    });
  });

  group('AuthService.getRole', () {
    test('returns admin for user with admin custom claim', () async {
      // Note: MockUser uses 'customClaim' (singular), not 'customClaims'
      final mockUser = MockUser(
        uid: 'uid123',
        email: 'admin@example.com',
        isEmailVerified: true,
        customClaim: {'role': 'admin'},
      );
      final mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      final role = await service.getRole();
      expect(role, 'admin');
    });

    test('returns user when no role claim is set', () async {
      final mockUser = MockUser(uid: 'uid123', isEmailVerified: true);
      final mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      final role = await service.getRole();
      expect(role, 'user');
    });

    test('returns user when currentUser is null', () async {
      final mockAuth = MockFirebaseAuth();
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      final role = await service.getRole();
      expect(role, 'user');
    });
  });

  group('AuthService.sendPasswordReset', () {
    test('completes without error for valid email', () async {
      final mockAuth = MockFirebaseAuth();
      final service = AuthService(auth: mockAuth, firestoreService: firestoreService);

      await expectLater(
        service.sendPasswordReset('test@example.com'),
        completes,
      );
    });
  });
}

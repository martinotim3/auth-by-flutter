# Firebase Auth — Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter app with Firebase email/password auth, email verification enforcement, password reset, and role-based routing (Admin vs User via custom claims).

**Architecture:** `app.dart` wraps `MaterialApp` with a `StreamBuilder` on `authStateChanges`. Unauthenticated → `LoginScreen`. Authenticated → `FutureBuilder` reads custom claims → `AdminHomeScreen` or `UserHomeScreen`. `AuthService` owns all Firebase Auth calls. `FirestoreService` owns user profile reads/writes. Plain Dart service classes — no state management library.

**Tech Stack:** Flutter 3.x, Dart 3.x, `firebase_auth`, `cloud_firestore`, `firebase_auth_mocks` (dev), `fake_cloud_firestore` (dev)

## Global Constraints

- Package name: `auth` (imports: `package:auth/...`)
- Dart SDK: `'>=3.0.0 <4.0.0'`
- Null safety enforced throughout
- All user-visible errors displayed via `SnackBar`
- Role always sourced from Firebase custom claims (`getIdTokenResult`) — never from Firestore or client state
- Email verification checked on every login; unverified users are signed out immediately
- Firestore user doc written on registration with `role: "user"` default

---

### Task 1: Flutter project scaffold + Firebase dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: runnable Flutter project; `firebase_auth`, `cloud_firestore`, `firebase_auth_mocks`, `fake_cloud_firestore` available for import

- [ ] **Step 1: Scaffold Flutter project**

From `C:\Users\Bahati\PROJECTS\auth`, run:
```powershell
flutter create . --project-name auth --org com.example
```
Expected: Flutter scaffolds project files. `pubspec.yaml` appears with `name: auth`.

- [ ] **Step 2: Replace dependencies in pubspec.yaml**

Open `pubspec.yaml` and replace the `dependencies` and `dev_dependencies` sections:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  firebase_auth_mocks: ^0.14.0
  fake_cloud_firestore: ^3.0.0
```

- [ ] **Step 3: Install dependencies**

```powershell
flutter pub get
```
Expected output ends with: `Got dependencies!`

- [ ] **Step 4: Configure Firebase with FlutterFire CLI**

> **Manual prerequisite.** Requires a Firebase project:
> 1. Go to `console.firebase.google.com` → New project
> 2. Enable Email/Password under Authentication → Sign-in method
> 3. Enable Firestore under Firestore Database → Create database (start in test mode)

Install FlutterFire CLI:
```powershell
dart pub global activate flutterfire_cli
```

Configure (follow prompts to select your Firebase project):
```powershell
flutterfire configure
```
Expected: `lib/firebase_options.dart` created.

- [ ] **Step 5: Verify build**

```powershell
flutter build apk --debug
```
Expected: `Built build\app\outputs\flutter-apk\app-debug.apk`

- [ ] **Step 6: Commit**

```powershell
git init
git add pubspec.yaml pubspec.lock lib/firebase_options.dart
git commit -m "feat: scaffold Flutter project with Firebase dependencies"
```

---

### Task 2: AppUser model

**Files:**
- Create: `lib/shared/models/app_user.dart`
- Create: `test/shared/models/app_user_test.dart`

**Interfaces:**
- Produces:
  - `class AppUser` with `final` fields: `uid`, `email`, `role`, `displayName`, `emailVerified`
  - `const AppUser({required String uid, required String email, required String role, required String displayName, required bool emailVerified})`
  - `factory AppUser.fromFirestore(Map<String, dynamic> data, String uid, String role, bool emailVerified)`

- [ ] **Step 1: Write the failing test**

Create `test/shared/models/app_user_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/shared/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('constructs with required fields', () {
      const user = AppUser(
        uid: 'uid123',
        email: 'test@example.com',
        role: 'user',
        displayName: 'Test User',
        emailVerified: true,
      );
      expect(user.uid, 'uid123');
      expect(user.email, 'test@example.com');
      expect(user.role, 'user');
      expect(user.displayName, 'Test User');
      expect(user.emailVerified, true);
    });

    test('fromFirestore creates AppUser from map', () {
      final data = {
        'email': 'admin@example.com',
        'displayName': 'Admin User',
      };
      final user = AppUser.fromFirestore(data, 'uid456', 'admin', true);
      expect(user.uid, 'uid456');
      expect(user.email, 'admin@example.com');
      expect(user.role, 'admin');
      expect(user.displayName, 'Admin User');
      expect(user.emailVerified, true);
    });

    test('fromFirestore defaults displayName to empty string when missing', () {
      final data = {'email': 'test@example.com'};
      final user = AppUser.fromFirestore(data, 'uid789', 'user', false);
      expect(user.displayName, '');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```powershell
flutter test test/shared/models/app_user_test.dart
```
Expected: FAIL — `Error: uri 'package:auth/shared/models/app_user.dart' is not found`

- [ ] **Step 3: Implement AppUser**

Create `lib/shared/models/app_user.dart`:
```dart
class AppUser {
  final String uid;
  final String email;
  final String role;
  final String displayName;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    required this.emailVerified,
  });

  factory AppUser.fromFirestore(
    Map<String, dynamic> data,
    String uid,
    String role,
    bool emailVerified,
  ) {
    return AppUser(
      uid: uid,
      email: data['email'] as String,
      role: role,
      displayName: data['displayName'] as String? ?? '',
      emailVerified: emailVerified,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```powershell
flutter test test/shared/models/app_user_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/shared/models/app_user.dart test/shared/models/app_user_test.dart
git commit -m "feat: add AppUser model"
```

---

### Task 3: FirestoreService

**Files:**
- Create: `lib/shared/services/firestore_service.dart`
- Create: `test/shared/services/firestore_service_test.dart`

**Interfaces:**
- Consumes: `cloud_firestore`; `FakeFirebaseFirestore` in tests
- Produces:
  - `FirestoreService({FirebaseFirestore? firestore})`
  - `Future<void> createUser({required String uid, required String email, required String displayName})`
  - `Future<Map<String, dynamic>?> getUser(String uid)`
  - `Future<void> updateEmailVerified(String uid)`

- [ ] **Step 1: Write the failing tests**

Create `test/shared/services/firestore_service_test.dart`:
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/shared/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService', () {
    test('createUser writes correct data to users collection', () async {
      await service.createUser(
        uid: 'uid123',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      final doc = await fakeFirestore.collection('users').doc('uid123').get();
      expect(doc.exists, true);
      expect(doc.data()!['email'], 'test@example.com');
      expect(doc.data()!['displayName'], 'Test User');
      expect(doc.data()!['role'], 'user');
      expect(doc.data()!['emailVerified'], false);
    });

    test('getUser returns user data for existing user', () async {
      await fakeFirestore.collection('users').doc('uid123').set({
        'email': 'test@example.com',
        'displayName': 'Test User',
        'role': 'user',
        'emailVerified': false,
      });

      final data = await service.getUser('uid123');
      expect(data, isNotNull);
      expect(data!['email'], 'test@example.com');
    });

    test('getUser returns null for non-existent user', () async {
      final data = await service.getUser('nonexistent');
      expect(data, isNull);
    });

    test('updateEmailVerified sets emailVerified to true', () async {
      await fakeFirestore.collection('users').doc('uid123').set({
        'emailVerified': false,
      });

      await service.updateEmailVerified('uid123');

      final doc = await fakeFirestore.collection('users').doc('uid123').get();
      expect(doc.data()!['emailVerified'], true);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/shared/services/firestore_service_test.dart
```
Expected: FAIL — `Error: uri 'package:auth/shared/services/firestore_service.dart' is not found`

- [ ] **Step 3: Implement FirestoreService**

Create `lib/shared/services/firestore_service.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createUser({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'user',
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'emailVerified': false,
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateEmailVerified(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'emailVerified': true,
    });
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
flutter test test/shared/services/firestore_service_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/shared/services/firestore_service.dart test/shared/services/firestore_service_test.dart
git commit -m "feat: add FirestoreService"
```

---

### Task 4: AuthService

**Files:**
- Create: `lib/features/auth/auth_service.dart`
- Create: `test/features/auth/auth_service_test.dart`

**Interfaces:**
- Consumes: `FirestoreService` from Task 3; `firebase_auth`; `firebase_auth_mocks` in tests
- Produces:
  - `class AuthException implements Exception { final String message; const AuthException(this.message); }`
  - `AuthService({FirebaseAuth? auth, FirestoreService? firestoreService})`
  - `Stream<User?> get authStateChanges`
  - `Future<void> register({required String email, required String password, required String displayName})`
  - `Future<void> login({required String email, required String password})`
  - `Future<void> logout()`
  - `Future<void> sendPasswordReset(String email)`
  - `Future<String> getRole()` — returns `'admin'` or `'user'`
  - `Future<void> resendVerificationEmail()`

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/auth_service_test.dart`:
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
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
      final mockAuth = MockFirebaseAuth();
      await mockAuth.createUserWithEmailAndPassword(
        email: 'exists@example.com',
        password: 'password123',
      );
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
      final mockAuth = MockFirebaseAuth(mockUser: mockUser);
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
      final mockUser = MockUser(
        uid: 'uid123',
        email: 'admin@example.com',
        isEmailVerified: true,
        customClaims: {'role': 'admin'},
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
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/features/auth/auth_service_test.dart
```
Expected: FAIL — `Error: uri 'package:auth/features/auth/auth_service.dart' is not found`

- [ ] **Step 3: Implement AuthService**

Create `lib/features/auth/auth_service.dart`:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auth/shared/services/firestore_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  AuthService({
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.sendEmailVerification();
      await _firestoreService.createUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null && !credential.user!.emailVerified) {
        await _auth.signOut();
        throw const AuthException(
          'Please verify your email before logging in.',
        );
      }
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  Future<String> getRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'user';
    final tokenResult = await user.getIdTokenResult(true);
    return (tokenResult.claims?['role'] as String?) ?? 'user';
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  String _mapError(String code) {
    return switch (code) {
      'wrong-password' => 'Incorrect password.',
      'invalid-credential' => 'Incorrect email or password.',
      'user-not-found' => 'No account found with this email.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-email' => 'Invalid email address.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
flutter test test/features/auth/auth_service_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/auth/auth_service.dart test/features/auth/auth_service_test.dart
git commit -m "feat: add AuthService with register, login, logout, password reset, role"
```

---

### Task 5: App root routing

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart`
- Create: `lib/features/auth/screens/login_screen.dart` (stub)
- Create: `lib/features/admin/admin_home_screen.dart` (stub)
- Create: `lib/features/user/user_home_screen.dart` (stub)
- Create: `test/app_test.dart`

**Interfaces:**
- Consumes: `AuthService` from Task 4
- Produces: `App({required AuthService authService})` — root `MaterialApp` with `StreamBuilder` auth routing

- [ ] **Step 1: Write the failing tests**

Create `test/app_test.dart`:
```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/app_test.dart
```
Expected: FAIL — `Error: uri 'package:auth/app.dart' is not found`

- [ ] **Step 3: Create stub screens (compile targets for app.dart)**

Create `lib/features/auth/screens/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('login_screen'),
      body: Center(child: Text('Login')),
    );
  }
}
```

Create `lib/features/admin/admin_home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  final AuthService authService;
  const AdminHomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('admin_home_screen'),
      body: Center(child: Text('Admin Home')),
    );
  }
}
```

Create `lib/features/user/user_home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class UserHomeScreen extends StatelessWidget {
  final AuthService authService;
  const UserHomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('user_home_screen'),
      body: Center(child: Text('User Home')),
    );
  }
}
```

- [ ] **Step 4: Implement app.dart**

Create `lib/app.dart`:
```dart
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
```

- [ ] **Step 5: Update main.dart**

Replace the contents of `lib/main.dart`:
```dart
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
```

- [ ] **Step 6: Run tests to verify they pass**

```powershell
flutter test test/app_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 7: Commit**

```powershell
git add lib/app.dart lib/main.dart lib/features/auth/screens/login_screen.dart lib/features/admin/admin_home_screen.dart lib/features/user/user_home_screen.dart test/app_test.dart
git commit -m "feat: add app root with StreamBuilder auth routing"
```

---

### Task 6: Shared auth widgets

**Files:**
- Create: `lib/features/auth/widgets/auth_text_field.dart`
- Create: `lib/features/auth/widgets/auth_button.dart`
- Create: `test/features/auth/widgets/auth_button_test.dart`

**Interfaces:**
- Produces:
  - `AuthTextField({required TextEditingController controller, required String label, bool obscureText = false, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator})`
  - `AuthButton({required String label, required VoidCallback? onPressed, bool isLoading = false})`

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/widgets/auth_button_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/features/auth/widgets/auth_button.dart';

void main() {
  group('AuthButton', () {
    testWidgets('shows label text when not loading', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AuthButton(label: 'Sign In', onPressed: () {})),
      ));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows CircularProgressIndicator when isLoading is true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthButton(label: 'Sign In', onPressed: () {}, isLoading: true),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('button onPressed is null when isLoading is true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthButton(label: 'Sign In', onPressed: () {}, isLoading: true),
        ),
      ));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('button onPressed is null when passed null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AuthButton(label: 'Sign In', onPressed: null)),
      ));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/features/auth/widgets/auth_button_test.dart
```
Expected: FAIL — `Error: uri 'package:auth/features/auth/widgets/auth_button.dart' is not found`

- [ ] **Step 3: Implement AuthTextField**

Create `lib/features/auth/widgets/auth_text_field.dart`:
```dart
import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement AuthButton**

Create `lib/features/auth/widgets/auth_button.dart`:
```dart
import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```powershell
flutter test test/features/auth/widgets/auth_button_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```powershell
git add lib/features/auth/widgets/ test/features/auth/widgets/
git commit -m "feat: add shared AuthTextField and AuthButton widgets"
```

---

### Task 7: LoginScreen

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`
- Create: `lib/features/auth/screens/forgot_password_screen.dart` (stub)
- Create: `lib/features/auth/screens/register_screen.dart` (stub)
- Create: `test/features/auth/screens/login_screen_test.dart`

**Interfaces:**
- Consumes: `AuthService.login()`, `AuthService.resendVerificationEmail()` from Task 4; `AuthTextField`, `AuthButton` from Task 6
- Produces: Full login form; navigates to `ForgotPasswordScreen` and `RegisterScreen`

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/screens/login_screen_test.dart`:
```dart
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
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('shows validation error when fields are empty on submit', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('shows SnackBar when login fails', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'wrong@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'wrongpassword');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('shows Forgot Password and Register links', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/features/auth/screens/login_screen_test.dart
```
Expected: FAIL — stub `LoginScreen` has none of the expected widgets

- [ ] **Step 3: Create stubs for navigation targets**

Create `lib/features/auth/screens/forgot_password_screen.dart` (stub — replaced in Task 9):
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final AuthService authService;
  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('forgot_password_screen'),
      appBar: AppBar(title: const Text('Reset Password')),
      body: const Center(child: Text('Forgot Password')),
    );
  }
}
```

Create `lib/features/auth/screens/register_screen.dart` (stub — replaced in Task 8):
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

class RegisterScreen extends StatelessWidget {
  final AuthService authService;
  const RegisterScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('register_screen'),
      appBar: AppBar(title: const Text('Create Account')),
      body: const Center(child: Text('Register')),
    );
  }
}
```

- [ ] **Step 4: Implement LoginScreen**

Replace `lib/features/auth/screens/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/screens/forgot_password_screen.dart';
import 'package:auth/features/auth/screens/register_screen.dart';
import 'package:auth/features/auth/widgets/auth_button.dart';
import 'package:auth/features/auth/widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _showResend = e.message.contains('verify your email'));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('login_screen'),
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your password' : null,
              ),
              const SizedBox(height: 24),
              AuthButton(
                label: 'Sign In',
                onPressed: _isLoading ? null : _login,
                isLoading: _isLoading,
              ),
              if (_showResend) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await widget.authService.resendVerificationEmail();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Verification email sent.')));
                  },
                  child: const Text('Resend verification email'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ForgotPasswordScreen(authService: widget.authService),
                  ),
                ),
                child: const Text('Forgot Password?'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegisterScreen(authService: widget.authService),
                  ),
                ),
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```powershell
flutter test test/features/auth/screens/login_screen_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```powershell
git add lib/features/auth/screens/ test/features/auth/screens/login_screen_test.dart
git commit -m "feat: implement LoginScreen with form validation and error handling"
```

---

### Task 8: RegisterScreen

**Files:**
- Modify: `lib/features/auth/screens/register_screen.dart`
- Create: `test/features/auth/screens/register_screen_test.dart`

**Interfaces:**
- Consumes: `AuthService.register({required String email, required String password, required String displayName})` from Task 4; `AuthTextField`, `AuthButton` from Task 6

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/screens/register_screen_test.dart`:
```dart
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
    await tester.tap(find.text('Register'));
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
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Verify Your Email'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/features/auth/screens/register_screen_test.dart
```
Expected: FAIL — stub has none of the expected widgets

- [ ] **Step 3: Implement RegisterScreen**

Replace `lib/features/auth/screens/register_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/widgets/auth_button.dart';
import 'package:auth/features/auth/widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Verify Your Email'),
          content: Text(
            'A verification link was sent to ${_emailController.text.trim()}. '
            'Verify before signing in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('register_screen'),
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmController,
                label: 'Confirm Password',
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm your password';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AuthButton(
                label: 'Register',
                onPressed: _isLoading ? null : _register,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
flutter test test/features/auth/screens/register_screen_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/auth/screens/register_screen.dart test/features/auth/screens/register_screen_test.dart
git commit -m "feat: implement RegisterScreen with email verification dialog"
```

---

### Task 9: ForgotPasswordScreen

**Files:**
- Modify: `lib/features/auth/screens/forgot_password_screen.dart`
- Create: `test/features/auth/screens/forgot_password_screen_test.dart`

**Interfaces:**
- Consumes: `AuthService.sendPasswordReset(String email)` from Task 4; `AuthTextField`, `AuthButton` from Task 6

- [ ] **Step 1: Write the failing tests**

Create `test/features/auth/screens/forgot_password_screen_test.dart`:
```dart
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
    await tester.tap(find.text('Send Reset Email'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('shows success SnackBar after sending reset email', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.tap(find.text('Send Reset Email'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Password reset email sent. Check your inbox.'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/features/auth/screens/forgot_password_screen_test.dart
```
Expected: FAIL — stub has none of the expected widgets

- [ ] **Step 3: Implement ForgotPasswordScreen**

Replace `lib/features/auth/screens/forgot_password_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';
import 'package:auth/features/auth/widgets/auth_button.dart';
import 'package:auth/features/auth/widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthService authService;
  const ForgotPasswordScreen({super.key, required this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.authService.sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password reset email sent. Check your inbox.')));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('forgot_password_screen'),
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter your email and we\'ll send a password reset link.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 24),
              AuthButton(
                label: 'Send Reset Email',
                onPressed: _isLoading ? null : _sendReset,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```powershell
flutter test test/features/auth/screens/forgot_password_screen_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/auth/screens/forgot_password_screen.dart test/features/auth/screens/forgot_password_screen_test.dart
git commit -m "feat: implement ForgotPasswordScreen with reset email and success SnackBar"
```

---

### Task 10: Role home screens + Firestore security rules

**Files:**
- Modify: `lib/features/admin/admin_home_screen.dart`
- Modify: `lib/features/user/user_home_screen.dart`
- Create: `firestore.rules`
- Create: `test/features/admin/admin_home_screen_test.dart`
- Create: `test/features/user/user_home_screen_test.dart`

**Interfaces:**
- Consumes: `AuthService.logout()` from Task 4

- [ ] **Step 1: Write the failing tests**

Create `test/features/admin/admin_home_screen_test.dart`:
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/features/admin/admin_home_screen.dart';
import 'package:auth/features/auth/auth_service.dart';
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

  testWidgets('renders Admin Dashboard title', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AdminHomeScreen(authService: authService),
    ));
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('renders Sign Out button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AdminHomeScreen(authService: authService),
    ));
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('signs out when Sign Out is tapped', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AdminHomeScreen(authService: authService),
    ));
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(mockAuth.currentUser, isNull);
  });
}
```

Create `test/features/user/user_home_screen_test.dart`:
```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

```powershell
flutter test test/features/admin/admin_home_screen_test.dart test/features/user/user_home_screen_test.dart
```
Expected: FAIL — stubs don't have 'Admin Dashboard', 'Home', or 'Sign Out'

- [ ] **Step 3: Implement AdminHomeScreen**

Replace `lib/features/admin/admin_home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

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
            ElevatedButton(
              onPressed: () async => authService.logout(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement UserHomeScreen**

Replace `lib/features/user/user_home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:auth/features/auth/auth_service.dart';

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
            ElevatedButton(
              onPressed: () async => authService.logout(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Write Firestore security rules**

Create `firestore.rules`:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

```powershell
flutter test test/features/admin/admin_home_screen_test.dart test/features/user/user_home_screen_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 7: Run full test suite**

```powershell
flutter test
```
Expected: All tests pass with no failures.

- [ ] **Step 8: Commit**

```powershell
git add lib/features/admin/admin_home_screen.dart lib/features/user/user_home_screen.dart firestore.rules test/features/admin/ test/features/user/
git commit -m "feat: implement AdminHomeScreen, UserHomeScreen with logout and Firestore security rules"
```

---

## Post-Implementation: Assign Admin Role

Client code cannot set custom claims. Use Firebase console or Firebase Admin SDK:

**Firebase console:**
1. Authentication → Users → select user → click "..." → Edit user
2. Add custom claims: `{"role": "admin"}`

**Firebase Admin SDK (Node.js):**
```js
const admin = require('firebase-admin');
admin.auth().setCustomUserClaims(uid, { role: 'admin' });
```

New users default to `role: "user"` (set by `FirestoreService.createUser`). No client action needed for standard users.

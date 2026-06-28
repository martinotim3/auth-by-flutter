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
  User? _pendingVerificationUser;

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
      try {
        await credential.user!.sendEmailVerification();
        await _firestoreService.createUser(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
        );
      } catch (_) {
        await credential.user!.delete();
        rethrow;
      }
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
        _pendingVerificationUser = credential.user;
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
    await _pendingVerificationUser?.sendEmailVerification();
    _pendingVerificationUser = null;
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

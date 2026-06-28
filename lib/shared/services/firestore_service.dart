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

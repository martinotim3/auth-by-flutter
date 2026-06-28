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

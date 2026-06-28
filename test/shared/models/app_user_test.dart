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

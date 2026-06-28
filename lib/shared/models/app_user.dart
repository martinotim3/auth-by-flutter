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

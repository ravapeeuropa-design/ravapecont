import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? 'Usuario sin email',
      displayName: user.displayName,
    );
  }
}

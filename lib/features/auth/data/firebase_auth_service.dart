import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';

class AuthException implements Exception {
  const AuthException({required this.code, this.message});

  final String code;
  final String? message;

  @override
  String toString() {
    if (message != null && message!.isNotEmpty) {
      return 'No se pudo acceder. Código: $code. Detalle: $message';
    }
    return 'No se pudo acceder. Código: $code';
  }
}

class UnknownAuthException implements Exception {
  const UnknownAuthException({this.message});

  final String? message;

  @override
  String toString() {
    if (message != null && message!.isNotEmpty) {
      return 'No se pudo acceder. Código: desconocido. Detalle: $message';
    }
    return 'No se pudo acceder. Código: desconocido';
  }
}

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;

  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
      (user) => user == null ? null : AppUser.fromFirebaseUser(user),
    );
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (credential.user == null) {
        throw const UnknownAuthException();
      }
    } on FirebaseAuthException catch (error) {
      throw AuthException(code: error.code, message: error.message);
    } catch (error) {
      throw UnknownAuthException(message: error.toString());
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}

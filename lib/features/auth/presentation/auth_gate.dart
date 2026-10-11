import 'package:flutter/material.dart';

import '../data/firebase_auth_service.dart';
import '../domain/app_user.dart';
import 'authenticated_app.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
    required FirebaseAuthService authService,
    this.initialAuthState,
  }) : _authService = authService;

  final Future<void> Function(ThemeMode themeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode;

  final FirebaseAuthService _authService;
  final Stream<AppUser?>? initialAuthState;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: initialAuthState ?? _authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se ha podido comprobar la sesión.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return LoginPage(
            authService: _authService,
          );
        }

        return AuthenticatedApp(
          user: user,
          authService: _authService,
          onThemeModeChanged: onThemeModeChanged,
          currentThemeMode: currentThemeMode,
        );
      },
    );
  }
}

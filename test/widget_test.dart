import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ravapecont/app/app_local_state.dart';
import 'package:ravapecont/app/app_routes.dart';
import 'package:ravapecont/features/auth/data/firebase_auth_service.dart';
import 'package:ravapecont/features/auth/domain/app_user.dart';
import 'package:ravapecont/features/auth/presentation/auth_gate.dart';

void main() {
  testWidgets('LoginPage muestra acceso privado sin sesión', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          initialAuthState: Stream<AppUser?>.empty(),
          onThemeModeChanged: (_) async {},
          currentThemeMode: ThemeMode.system,
          authService: FirebaseAuthService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acceso privado'), findsOneWidget);
  });

  group('AppShell route parsing safety', () {
    late AppLocalState state;

    setUp(() {
      state = AppLocalState();
    });

    test('/dashboard no devuelve companyId', () {
      expect(state.companyIdFromRoute(AppRoutes.dashboard), isNull);
    });

    test('/companies no devuelve companyId', () {
      expect(state.companyIdFromRoute(AppRoutes.companies), isNull);
    });

    test('/companies/abc obtiene companyId abc', () {
      expect(state.companyIdFromRoute('/companies/abc'), 'abc');
    });

    test('/companies/abc/invoices obtiene companyId abc', () {
      expect(state.companyIdFromRoute('/companies/abc/invoices'), 'abc');
    });

    test('/companies/abc/quotes obtiene companyId abc', () {
      expect(state.companyIdFromRoute('/companies/abc/quotes'), 'abc');
    });

    test('/companies/ no devuelve ID', () {
      expect(state.companyIdFromRoute('/companies/'), isNull);
    });

    test('/documents/new no devuelve ID', () {
      expect(state.companyIdFromRoute(AppRoutes.documentsNew), isNull);
    });
  });
}

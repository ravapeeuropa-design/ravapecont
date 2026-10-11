import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_shell.dart';
import '../features/auth/data/firebase_auth_service.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/domain/app_user.dart';
import '../features/companies/data/firestore_company_repository.dart';
import '../features/customers/data/firestore_customer_repository.dart';
import '../core/preferences/theme_preferences.dart';
import '../core/theme/app_theme.dart';

const bool _bypassAuthForLocalDevelopment = bool.fromEnvironment('BYPASS_AUTH', defaultValue: false);

class RavapecontApp extends StatefulWidget {
  const RavapecontApp({super.key});

  @override
  State<RavapecontApp> createState() => _RavapecontAppState();
}

class _RavapecontAppState extends State<RavapecontApp> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final themeMode = await ThemePreferences.load();
    if (!mounted) return;
    setState(() {
      _themeMode = themeMode;
    });
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (!mounted) return;
    setState(() {
      _themeMode = themeMode;
    });
    await ThemePreferences.save(themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ravapecont',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: _bypassAuthForLocalDevelopment
          ? _buildBypassHome()
          : AuthGate(onThemeModeChanged: setThemeMode, currentThemeMode: _themeMode, authService: _authService),
    );
  }
  Widget _buildBypassHome() {
    const currentUser = AppUser(
      id: 'local-development',
      email: 'Desarrollo local',
      displayName: 'Modo desarrollo',
    );
    final firestore = FirebaseFirestore.instance;
    final companyRepository = FirestoreCompanyRepository(firestore: firestore);
    final customerRepository = FirestoreCustomerRepository(firestore: firestore);
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF000000),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: const Text(
            'Modo desarrollo: autenticación omitida',
            style: TextStyle(color: Color(0xFFF5F5F5)),
          ),
        ),
        Expanded(
          child: AppShell(
            currentUser: currentUser,
            onSignOutRequested: () async {},
            companyRepository: companyRepository,
            customerRepository: customerRepository,
            onThemeModeChanged: setThemeMode,
            currentThemeMode: _themeMode,
          ),
        ),
      ],
    );
  }
}

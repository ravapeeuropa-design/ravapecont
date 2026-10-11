import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/app_shell.dart';
import '../../../features/companies/data/firestore_company_repository.dart';
import '../../../features/customers/data/firestore_customer_repository.dart';
import '../data/firebase_auth_service.dart';
import '../domain/app_user.dart';

class AuthenticatedApp extends StatelessWidget {
  AuthenticatedApp({
    super.key,
    required this.user,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
    FirebaseAuthService? authService,
    FirestoreCompanyRepository? companyRepository,
    FirestoreCustomerRepository? customerRepository,
  })  : _authService = authService,
        _companyRepository = companyRepository,
        _customerRepository = customerRepository {
    if ((_companyRepository == null) != (_customerRepository == null)) {
      throw ArgumentError('Los dos repositorios deben indicarse juntos.');
    }
  }

  final AppUser user;
  final Future<void> Function(ThemeMode themeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode;
  final FirebaseAuthService? _authService;
  final FirestoreCompanyRepository? _companyRepository;
  final FirestoreCustomerRepository? _customerRepository;

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final companyRepository = _companyRepository ?? FirestoreCompanyRepository(firestore: firestore);
    final customerRepository = _customerRepository ?? FirestoreCustomerRepository(firestore: firestore);
    return AppShell(
      currentUser: user,
      onSignOutRequested: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('Se cerrará la sesión actual.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _authService?.signOut();
        }
      },
      companyRepository: companyRepository,
      customerRepository: customerRepository,
      onThemeModeChanged: onThemeModeChanged,
      currentThemeMode: currentThemeMode,
    );
  }
}

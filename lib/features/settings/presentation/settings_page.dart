import 'package:flutter/material.dart';

import '../../auth/domain/app_user.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.currentUser,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.onSignOutRequested,
  });

  final AppUser currentUser;
  final ThemeMode currentThemeMode;
  final Future<void> Function(ThemeMode themeMode) onThemeModeChanged;
  final Future<void> Function() onSignOutRequested;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final email = currentUser.email.isEmpty ? 'Usuario sin email' : currentUser.email;
    final displayName = currentUser.displayName ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajustes',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          Text(
            'Apariencia',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Claro'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Oscuro'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('Sistema'),
              ),
            ],
            selected: {currentThemeMode},
            onSelectionChanged: (selection) async {
              final themeMode = selection.first;
              await onThemeModeChanged(themeMode);
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Cuenta',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(email, style: TextStyle(color: colorScheme.onSurface)),
          if (displayName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(displayName, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 32),
          Text(
            'Sesión',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onSignOutRequested,
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class ThemePreferences {
  static const _themeModeKey = 'theme_mode';

  ThemePreferences._();

  static Future<ThemeMode> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_themeModeKey);

    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  static Future<void> save(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();

    final value = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await preferences.setString(_themeModeKey, value);
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

final themeNotifierProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  return ThemeProvider();
});

class ThemeState {
  final bool isDarkMode;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;

  ThemeState({
    required this.isDarkMode,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
  });

  // Light mode colors
  static const lightBackgroundColor = Color(0xFFF5F5F5);
  static const lightSurfaceColor = Colors.white;
  static const lightTextColor = Colors.black87;
  static const lightSecondaryTextColor = Colors.black54;

  // Dark mode colors
  static const darkBackgroundColor = Color(0xFF0C0F14);
  static const darkSurfaceColor = Color.fromARGB(255, 20, 25, 34);
  static const darkTextColor = Colors.white;
  static const darkSecondaryTextColor = Colors.white70;

  factory ThemeState.dark() => ThemeState(
        isDarkMode: true,
        backgroundColor: darkBackgroundColor,
        surfaceColor: darkSurfaceColor,
        textColor: darkTextColor,
        secondaryTextColor: darkSecondaryTextColor,
      );

  factory ThemeState.light() => ThemeState(
        isDarkMode: false,
        backgroundColor: lightBackgroundColor,
        surfaceColor: lightSurfaceColor,
        textColor: lightTextColor,
        secondaryTextColor: lightSecondaryTextColor,
      );

  Color getPrimaryTextColor() => isDarkMode ? darkTextColor : lightTextColor;
  Color getSecondaryTextColor() =>
      isDarkMode ? darkSecondaryTextColor : lightSecondaryTextColor;
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String DARK_MODE_KEY = 'dark_mode';

  ThemeNotifier() : super(ThemeState.dark()) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(DARK_MODE_KEY) ?? true;
    state = isDarkMode ? ThemeState.dark() : ThemeState.light();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newIsDarkMode = !state.isDarkMode;
    await prefs.setBool(DARK_MODE_KEY, newIsDarkMode);
    state = newIsDarkMode ? ThemeState.dark() : ThemeState.light();
  }
}

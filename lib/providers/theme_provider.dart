import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String DARK_MODE_KEY = 'dark_mode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(DARK_MODE_KEY) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DARK_MODE_KEY, _isDarkMode);
    notifyListeners();
  }

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

  Color get backgroundColor => _isDarkMode ? darkBackgroundColor : lightBackgroundColor;
  Color get surfaceColor => _isDarkMode ? darkSurfaceColor : lightSurfaceColor;
  Color get textColor => _isDarkMode ? darkTextColor : lightTextColor;
  Color get secondaryTextColor => _isDarkMode ? darkSecondaryTextColor : lightSecondaryTextColor;

  // Helper methods for getting text colors
  Color getTextColor(Color lightColor, Color darkColor) {
    return _isDarkMode ? darkColor : lightColor;
  }

  Color getPrimaryTextColor() {
    return _isDarkMode ? darkTextColor : Colors.black;
  }

  Color getSecondaryTextColor() {
    return _isDarkMode ? darkSecondaryTextColor : Colors.black54;
  }
}

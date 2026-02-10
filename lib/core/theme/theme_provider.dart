import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Theme Provider for managing light/dark theme state
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Check if current theme is dark
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Toggle between light and dark theme
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system, switch to opposite of current system setting
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }

  /// Set light theme
  void setLightTheme() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  /// Set dark theme
  void setDarkTheme() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  /// Set system theme
  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}

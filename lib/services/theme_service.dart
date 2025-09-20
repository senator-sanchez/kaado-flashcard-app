// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:shared_preferences/shared_preferences.dart';

// Project imports - Utils
import '../utils/app_theme.dart' as app_theme;

enum AppThemeMode {
  light,
  dark,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal() {
    _loadThemeFromPreferences();
  }

  AppThemeMode _currentTheme = AppThemeMode.dark;
  
  AppThemeMode get currentTheme => _currentTheme;
  
  /// Get the current ThemeData based on selected theme
  ThemeData get themeData {
    switch (_currentTheme) {
      case AppThemeMode.light:
        return app_theme.AppTheme.lightTheme;
      case AppThemeMode.dark:
        return app_theme.AppTheme.darkTheme;
    }
  }
  
  /// Load theme from shared preferences
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('selected_theme') ?? AppThemeMode.dark.index;
      _currentTheme = AppThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      // If loading fails, use default theme
      _currentTheme = AppThemeMode.dark;
      notifyListeners();
    }
  }
  
  /// Public method to initialize the theme service
  Future<void> initialize() async {
    await _loadThemeFromPreferences();
  }
  
  /// Set theme and save to preferences
  Future<void> setTheme(AppThemeMode theme) async {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
      
      // Save to preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('selected_theme', theme.index);
      } catch (e) {
        // Handle error silently - theme will still work for current session
      }
    }
  }
}

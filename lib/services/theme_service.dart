// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:shared_preferences/shared_preferences.dart';

// Project imports - Utils
import '../utils/theme_colors.dart';

enum AppTheme {
  light,
  dark,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal() {
    _loadThemeFromPreferences();
  }

  AppTheme _currentTheme = AppTheme.dark;
  
  AppTheme get currentTheme => _currentTheme;
  
  /// Load theme from shared preferences
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('selected_theme') ?? AppTheme.dark.index;
      _currentTheme = AppTheme.values[themeIndex];
      _initializeThemeColors();
    } catch (e) {
      // If loading fails, use default theme
      _currentTheme = AppTheme.dark;
      _initializeThemeColors();
    }
  }

  /// Initialize theme colors to match current theme
  void _initializeThemeColors() {
    ThemeColors.instance.setTheme(_currentTheme);
  }
  
  /// Public method to initialize the theme service
  Future<void> initialize() async {
    await _loadThemeFromPreferences();
  }
  
  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    ThemeColors.instance.setTheme(theme);
    _saveThemeToPreferences(theme);
    notifyListeners();
  }

  /// Save theme to shared preferences
  Future<void> _saveThemeToPreferences(AppTheme theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_theme', theme.index);
    } catch (e) {
      // Handle error silently
    }
  }
  
  ThemeData getThemeData() {
    final colors = ThemeColors.instance;
    
    return ThemeData(
      brightness: _currentTheme == AppTheme.dark ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: colors.primaryBlue,
      scaffoldBackgroundColor: colors.backgroundColor,
      cardColor: colors.cardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.appBarBackground,
        foregroundColor: colors.appBarIcon,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colors.primaryText),
        bodyMedium: TextStyle(color: colors.primaryText),
        titleLarge: TextStyle(color: colors.titleText),
        titleMedium: TextStyle(color: colors.titleText),
        titleSmall: TextStyle(color: colors.secondaryText),
      ),
      colorScheme: ColorScheme(
        brightness: _currentTheme == AppTheme.dark ? Brightness.dark : Brightness.light,
        primary: colors.primaryBlue,
        secondary: colors.completionGold,
        surface: colors.backgroundColor,
        error: colors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: colors.primaryText,
        onError: Colors.white,
      ),
    );
  }
}

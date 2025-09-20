import 'package:flutter/material.dart';

/// Custom theme extensions for app-specific properties
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.cardBackground,
    required this.correctButton,
    required this.incorrectButton,
    required this.skipButton,
    required this.actionButtonBackground,
    required this.buttonTextOnColored,
    required this.shadowColor,
    required this.divider,
    required this.appBarIcon,
    required this.appBarBackground,
    required this.backgroundColor,
    required this.primaryText,
    required this.secondaryText,
    required this.surface,
    required this.primaryBlue,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.topTextBackgroundColor,
    required this.cardShadow,
  });

  final Color cardBackground;
  final Color correctButton;
  final Color incorrectButton;
  final Color skipButton;
  final Color actionButtonBackground;
  final Color buttonTextOnColored;
  final Color shadowColor;
  final Color divider;
  final Color appBarIcon;
  final Color appBarBackground;
  final Color backgroundColor;
  final Color primaryText;
  final Color secondaryText;
  final Color surface;
  final Color primaryBlue;
  final Color primaryIcon;
  final Color secondaryIcon;
  final Color topTextBackgroundColor;
  final Color cardShadow;

  @override
  AppThemeExtension copyWith({
    Color? cardBackground,
    Color? correctButton,
    Color? incorrectButton,
    Color? skipButton,
    Color? actionButtonBackground,
    Color? buttonTextOnColored,
    Color? shadowColor,
    Color? divider,
    Color? appBarIcon,
    Color? appBarBackground,
    Color? backgroundColor,
    Color? primaryText,
    Color? secondaryText,
    Color? surface,
    Color? primaryBlue,
    Color? primaryIcon,
    Color? secondaryIcon,
    Color? topTextBackgroundColor,
    Color? cardShadow,
  }) {
    return AppThemeExtension(
      cardBackground: cardBackground ?? this.cardBackground,
      correctButton: correctButton ?? this.correctButton,
      incorrectButton: incorrectButton ?? this.incorrectButton,
      skipButton: skipButton ?? this.skipButton,
      actionButtonBackground: actionButtonBackground ?? this.actionButtonBackground,
      buttonTextOnColored: buttonTextOnColored ?? this.buttonTextOnColored,
      shadowColor: shadowColor ?? this.shadowColor,
      divider: divider ?? this.divider,
      appBarIcon: appBarIcon ?? this.appBarIcon,
      appBarBackground: appBarBackground ?? this.appBarBackground,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      surface: surface ?? this.surface,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      primaryIcon: primaryIcon ?? this.primaryIcon,
      secondaryIcon: secondaryIcon ?? this.secondaryIcon,
      topTextBackgroundColor: topTextBackgroundColor ?? this.topTextBackgroundColor,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      correctButton: Color.lerp(correctButton, other.correctButton, t)!,
      incorrectButton: Color.lerp(incorrectButton, other.incorrectButton, t)!,
      skipButton: Color.lerp(skipButton, other.skipButton, t)!,
      actionButtonBackground: Color.lerp(actionButtonBackground, other.actionButtonBackground, t)!,
      buttonTextOnColored: Color.lerp(buttonTextOnColored, other.buttonTextOnColored, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      appBarIcon: Color.lerp(appBarIcon, other.appBarIcon, t)!,
      appBarBackground: Color.lerp(appBarBackground, other.appBarBackground, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      primaryIcon: Color.lerp(primaryIcon, other.primaryIcon, t)!,
      secondaryIcon: Color.lerp(secondaryIcon, other.secondaryIcon, t)!,
      topTextBackgroundColor: Color.lerp(topTextBackgroundColor, other.topTextBackgroundColor, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

/// App theme configurations
class AppTheme {
  static const _primaryBlue = Color(0xFF1976D2);

  /// Light theme configuration
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: _primaryBlue,
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFB00020),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      onError: Colors.white,
    );

    const appExtension = AppThemeExtension(
      cardBackground: Color(0xFFFFFFFF),
      correctButton: Color(0xFF4CAF50),
      incorrectButton: Color(0xFFF44336),
      skipButton: Color(0xFFFF9800),
      actionButtonBackground: Color(0xFF6C757D),
      buttonTextOnColored: Colors.white,
      shadowColor: Color(0x1A000000),
      divider: Color(0xFFE0E0E0),
      appBarIcon: Colors.white,
      appBarBackground: _primaryBlue,
      backgroundColor: Color(0xFFF5F5F5),
      primaryText: Colors.black87,
      secondaryText: Colors.black54,
      surface: Color(0xFFFFFFFF),
        primaryBlue: _primaryBlue,
        primaryIcon: _primaryBlue,
        secondaryIcon: Color(0xFF757575),
        topTextBackgroundColor: Color(0xFFE0E0E0),
        cardShadow: Color(0x1A000000),
      );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 2,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.black87,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.black87,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[appExtension],
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF64B5F6),
      secondary: Color(0xFF03DAC6),
      surface: Color(0xFF2D2D2D),
      error: Color(0xFFCF6679),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
    );

    const appExtension = AppThemeExtension(
      cardBackground: Color(0xFF2D2D2D),
      correctButton: Color(0xFF66BB6A),
      incorrectButton: Color(0xFFEF5350),
      skipButton: Color(0xFFFFB74D),
      actionButtonBackground: Color(0xFF6C757D),
      buttonTextOnColored: Colors.white,
      shadowColor: Color(0x33000000),
      divider: Color(0xFF424242),
      appBarIcon: Colors.white,
      appBarBackground: Color(0xFF1E1E1E),
      backgroundColor: Color(0xFF121212),
      primaryText: Colors.white,
      secondaryText: Color(0xFFB0B0B0),
      surface: Color(0xFF2D2D2D),
        primaryBlue: Color(0xFF64B5F6),
        primaryIcon: Color(0xFF64B5F6),
        secondaryIcon: Color(0xFFB0B0B0),
        topTextBackgroundColor: Color(0xFF424242),
        cardShadow: Color(0x33000000),
      );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64B5F6),
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF2D2D2D),
        elevation: 4,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 12,
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[appExtension],
    );
  }
}

/// Helper extension to easily access custom theme properties
extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme => Theme.of(this).extension<AppThemeExtension>()!;
}

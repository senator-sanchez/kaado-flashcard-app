import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/background_photo_service.dart';

class ThemeColors {
  static ThemeColors? _instance;
  static ThemeColors get instance => _instance ??= ThemeColors._();
  ThemeColors._();

  AppTheme _currentTheme = AppTheme.dark;

  AppTheme get currentTheme => _currentTheme;

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
  }

  // Helper method to get color based on theme
  Color _getColorForTheme({
    required Color lightColor,
    required Color darkColor,
  }) {
    switch (_currentTheme) {
      case AppTheme.light:
        return lightColor;
      case AppTheme.dark:
        return darkColor;
    }
  }

  // Helper method for colors that are the same in light theme
  Color _getColorForLight({
    required Color lightColor,
    required Color darkColor,
  }) {
    return _currentTheme == AppTheme.dark ? darkColor : lightColor;
  }


  // Primary Colors
  Color get primaryBlue => _getColorForLight(
    lightColor: const Color(0xFF1976D2),
    darkColor: Colors.blue[300]!,
  );

  Color get completionGold => _getColorForLight(
    lightColor: const Color(0xFFFFC107),
    darkColor: Colors.amber[300]!,
  );

  // Background Colors
  Color get backgroundColor => _getColorForTheme(
    lightColor: Colors.white,
    darkColor: const Color(0xFF121212),
  );

  // Background Image
  String? get backgroundImagePath => BackgroundPhotoService.instance.backgroundPhotoPath;

  Color get cardBackground => _getColorForTheme(
    lightColor: Colors.white,
    darkColor: const Color(0xFF1E1E1E),
  );

  Color get appBarBackground => _getColorForTheme(
    lightColor: Colors.blue,
    darkColor: const Color(0xFF1E1E1E),
  );

  // Text Colors
  Color get primaryText => _getColorForTheme(
    lightColor: Colors.black,
    darkColor: Colors.white,
  );

  Color get secondaryText => _getColorForTheme(
    lightColor: Colors.black54,
    darkColor: Colors.white60,
  );

  Color get buttonText => _getColorForTheme(
    lightColor: Colors.black,
    darkColor: Colors.white,
  );

  Color get buttonTextOnColored => _getColorForTheme(
    lightColor: Colors.white,
    darkColor: Colors.white,
  );

  /// Get a solid background color for text when background images are used
  Color get textBackgroundColor => _getColorForTheme(
    lightColor: Colors.black, // Dark background for light text
    darkColor: Colors.white,  // Light background for dark text
  );

  /// Get a background color for top text elements (progress bar, action buttons, instructions)
  Color get topTextBackgroundColor => _getColorForTheme(
    lightColor: Colors.white,      // White for light theme
    darkColor: Colors.grey[700]!,  // Darker grey for dark theme
  );

  Color get titleText => _getColorForTheme(
    lightColor: Colors.black,
    darkColor: Colors.white,
  );

  Color get cardText => _getColorForTheme(
    lightColor: Colors.black,
    darkColor: Colors.white,
  );

  // Icon Colors
  Color get primaryIcon => _currentTheme == AppTheme.light
      ? Colors.black
      : _currentTheme == AppTheme.dark
          ? Colors.white
          : const Color(0xFF1976D2);

  Color get secondaryIcon => _currentTheme == AppTheme.light
      ? Colors.black54
      : _currentTheme == AppTheme.dark
          ? Colors.white60
          : const Color(0xFF424242);

  Color get appBarIcon => _currentTheme == AppTheme.light
      ? Colors.white
      : _currentTheme == AppTheme.dark
          ? Colors.white
          : Colors.black; // Main theme - dark text on light background

  // Button Colors
  Color get correctButton => _getColorForLight(
    lightColor: Colors.green,
    darkColor: Colors.green[600]!,
  );

  Color get incorrectButton => _getColorForLight(
    lightColor: Colors.red,
    darkColor: Colors.red[600]!,
  );

  Color get skipButton => _getColorForLight(
    lightColor: Colors.orange,
    darkColor: Colors.orange[600]!,
  );

  // Action Button Colors (Skip, Shuffle, Reset)
  Color get actionButtonBackground => _getColorForTheme(
    lightColor: Colors.blue[700]!, // Darker blue for better contrast
    darkColor: Colors.grey[800]!, // Darker grey for better contrast
  );

  Color get actionButtonText => _getColorForTheme(
    lightColor: Colors.white, // White text on dark blue background
    darkColor: Colors.white, // White text on dark grey background
  );

  Color get actionButtonLabelText => _getColorForTheme(
    lightColor: Colors.black87, // Dark text on light background
    darkColor: Colors.white, // White text on dark background
  );

  // Progress Bar Colors
  Color get progressBarBackground => _currentTheme == AppTheme.light
      ? Colors.grey[200]!
      : _currentTheme == AppTheme.dark
          ? Colors.grey[800]!
          : Colors.white; // Main theme - white background from mockup

  Color get progressBarFill => _currentTheme == AppTheme.dark
      ? Colors.blue[400]!
      : const Color(0xFF1976D2);

  Color get progressBarCompleted => _currentTheme == AppTheme.dark
      ? Colors.amber[400]!
      : const Color(0xFFFFC107);

  // Shadow Colors
  Color get cardShadow => _currentTheme == AppTheme.light
      ? Colors.black.withValues(alpha: 0.1)
      : _currentTheme == AppTheme.dark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.1);

  // Divider Colors
  Color get divider => _currentTheme == AppTheme.light
      ? Colors.grey[300]!
      : _currentTheme == AppTheme.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!;

  // Surface Colors
  Color get surface => _currentTheme == AppTheme.light
      ? Colors.white
      : _currentTheme == AppTheme.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFF2D2D2D); // Dark surface for main theme

  // Error Colors
  Color get error => _currentTheme == AppTheme.dark
      ? Colors.redAccent
      : Colors.red;

  /// Consolidated function to handle background color for icons when image is added or removed
  Color? getIconBackgroundColor({required bool hasBackgroundImage}) {
    if (!hasBackgroundImage) {
      return null; // No background when no image
    }
    
    // Return appropriate background color when image is present
    return topTextBackgroundColor;
  }
}

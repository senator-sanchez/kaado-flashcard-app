import 'package:flutter/material.dart';
import 'theme_colors.dart';

/// Utility class for common decoration patterns
/// Helps maintain consistency and reduces code duplication
class DecorationUtils {
  static ThemeColors get _colors => ThemeColors.instance;

  /// Standard card decoration
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? _colors.cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: _colors.cardShadow,
          blurRadius: 8.0,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Standard button decoration with shadow
  static BoxDecoration buttonDecoration({
    required Color backgroundColor,
    double borderRadius = 12.0,
    double shadowBlur = 8.0,
    double shadowOffset = 4.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: _colors.cardShadow,
          blurRadius: shadowBlur,
          offset: Offset(0, shadowOffset),
        ),
      ],
    );
  }

  /// Standard tile decoration for list items
  static BoxDecoration tileDecoration({
    Color? backgroundColor,
    bool isSelected = false,
    double borderRadius = 12.0,
    double shadowBlur = 4.0,
    double shadowOffset = 2.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? _colors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isSelected ? _colors.primaryBlue : _colors.divider,
        width: isSelected ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: _colors.cardShadow,
          blurRadius: shadowBlur,
          offset: Offset(0, shadowOffset),
        ),
      ],
    );
  }

  /// Standard checkbox tile decoration
  static BoxDecoration checkboxTileDecoration({
    required bool isChecked,
    Color? backgroundColor,
    double borderRadius = 8.0,
  }) {
    return BoxDecoration(
      color: isChecked 
          ? _colors.primaryBlue.withValues(alpha: 0.1) 
          : (backgroundColor ?? _colors.surface),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isChecked ? _colors.primaryBlue : _colors.divider,
        width: isChecked ? 2 : 1,
      ),
    );
  }
}

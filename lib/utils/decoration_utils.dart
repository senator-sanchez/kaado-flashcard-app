import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Utility class for common decoration patterns
/// Helps maintain consistency and reduces code duplication
class DecorationUtils {
  /// Standard card decoration
  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? backgroundColor,
    double borderRadius = 16.0,
  }) {
    final appTheme = context.appTheme;
    return BoxDecoration(
      color: backgroundColor ?? appTheme.cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: appTheme.cardShadow,
          blurRadius: 8.0,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Standard button decoration with shadow
  static BoxDecoration buttonDecoration(
    BuildContext context, {
    required Color backgroundColor,
    double borderRadius = 12.0,
    double shadowBlur = 8.0,
    double shadowOffset = 4.0,
  }) {
    final appTheme = context.appTheme;
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: appTheme.cardShadow,
          blurRadius: shadowBlur,
          offset: Offset(0, shadowOffset),
        ),
      ],
    );
  }

  /// Standard tile decoration for list items
  static BoxDecoration tileDecoration(
    BuildContext context, {
    Color? backgroundColor,
    bool isSelected = false,
    double borderRadius = 12.0,
    double shadowBlur = 4.0,
    double shadowOffset = 2.0,
  }) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return BoxDecoration(
      color: backgroundColor ?? appTheme.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isSelected ? theme.primaryColor : appTheme.divider,
        width: isSelected ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: appTheme.cardShadow,
          blurRadius: shadowBlur,
          offset: Offset(0, shadowOffset),
        ),
      ],
    );
  }

  /// Standard checkbox tile decoration
  static BoxDecoration checkboxTileDecoration(
    BuildContext context, {
    required bool isChecked,
    Color? backgroundColor,
    double borderRadius = 8.0,
  }) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return BoxDecoration(
      color: isChecked 
          ? theme.primaryColor.withValues(alpha: 0.1) 
          : (backgroundColor ?? appTheme.surface),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isChecked ? theme.primaryColor : appTheme.divider,
        width: isChecked ? 2 : 1,
      ),
    );
  }
}

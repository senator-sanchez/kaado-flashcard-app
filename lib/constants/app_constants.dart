import 'package:flutter/material.dart';
import 'app_strings.dart';
import 'app_sizes.dart';

/// Main application constants
/// Provides access to all organized constant categories
class AppConstants {
  // ===== APP INFORMATION =====
  static const String appName = AppStrings.appName;
  static const String appVersion = AppStrings.appVersion;
  
  // ===== CARD CONSTANTS =====
  static const double cardMinHeight = AppSizes.cardMinHeight;
  static const double cardMinHeightWeb = AppSizes.cardMinHeight;
  static const double cardPadding = AppSizes.paddingMedium;
  static const double cardBackTextSize = AppSizes.fontXLarge;
  static const double cardCompletionIconSize = AppSizes.iconXLarge;
  static const double cardCompletionSpacing = AppSizes.spacingMedium;
  static const double cardCompletionTitleSize = AppSizes.fontTitle;
  static const double cardCompletionSubtitleSize = AppSizes.fontLarge;

  // ===== RESPONSIVE DESIGN METHODS =====
  
  /// Get maximum content width based on screen size
  static double getMaxContentWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > AppSizes.desktopBreakpoint) return AppSizes.cardMaxWidthLargeDesktop;
    if (screenWidth > AppSizes.mobileBreakpoint) return AppSizes.cardMaxWidthDesktop;
    return double.infinity; // Mobile (full width)
  }
  
  /// Get maximum card width based on screen size
  static double getCardMaxWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > AppSizes.desktopBreakpoint) return AppSizes.cardMaxWidthLargeDesktop;
    if (screenWidth > AppSizes.mobileBreakpoint) return AppSizes.cardMaxWidthDesktop;
    return double.infinity; // Mobile (full width)
  }
  
  /// Get button size based on screen size
  static double getButtonSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > AppSizes.mobileBreakpoint) return AppSizes.actionButtonSizeWeb;
    return AppSizes.actionButtonSize;
  }
  
  /// Get button spacing based on screen size
  static double getButtonSpacing(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > AppSizes.mobileBreakpoint) return AppSizes.spacingXLarge;
    return AppSizes.spacingMedium;
  }
  
  /// Check if the current context is web/desktop
  static bool isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width > AppSizes.mobileBreakpoint;
  }
  
  // ===== OPACITY VALUES =====
  static const double secondaryTextOpacity = 0.7;
  static const double disabledButtonOpacity = 0.5;
  static const double shadowOpacity = 0.1;
  static const double textOpacityLight = 0.5;
  static const double textOpacityMedium = 0.7;
  static const double themeShadowAlpha = 0.3;
  
  // ===== ANIMATION VALUES =====
  static const double animationEndValue = 1.0;
  static const double animationStartValue = 0.0;
  static const double progressMultiplier = 100.0;
  static const double luminanceThreshold = 0.5;
  
  // ===== SWIPE ANIMATION CONSTANTS =====
  static const double swipeRotationMultiplier = 0.0003;
  static const double swipeThresholdOpacity = 0.7;
  static const double swipeExitDistanceMultiplier = 1.5;
  static const int swipeAnimationFrameRate = 16; // ~60fps
  
  // ===== TEXT LAYOUT CONSTANTS =====
  static const int singleLineMaxLines = 1;
  static const int? multipleLinesMaxLines = null;
  
  // ===== ASSET PATH CONSTANTS =====
  static const String assetsPath = 'assets/';
  static const String backgroundsPath = 'assets/backgrounds/';
  static const String backgroundFileNamePrefix = 'background_';
  static const String backgroundFileExtension = '.jpg';
  
  // ===== IMAGE EXTENSION CONSTANTS =====
  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg', 
    '.png',
    '.gif',
    '.webp',
    '.svg'
  ];
}

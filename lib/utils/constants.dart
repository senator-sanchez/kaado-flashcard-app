import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

/// Application constants and configuration values
/// Centralizes all hardcoded values for easy maintenance
/// 
/// This class now serves as a coordinator for the organized constant files
class AppConstants {
  // ===== APP INFORMATION =====
  static const String appName = AppStrings.appName;
  static const String appVersion = AppStrings.appVersion;
  
  // ===== COLORS =====
  // Note: Colors are now handled by ThemeColors class for theme consistency
  // These constants are kept for backward compatibility but should be replaced with theme colors
  
  // ===== TYPOGRAPHY =====
  // Typography constants are now in AppTextStyles
  static const double englishTextSize = 24.0;
  static const double buttonTextSize = 16.0;
  static const double emojiSize = 24.0;
  static const double categoryTitleSize = 16.0;
  static const double cardCountSize = 12.0;
  
  // ===== SPACING AND SIZES =====
  // Spacing constants are now in AppSizes
  static const double cardPadding = 20.0;
  static const double buttonSpacing = 16.0;
  static const double buttonWidth = 100.0;
  static const double buttonHeight = 60.0;
  static const double categoryBadgeMargin = 8.0;
  static const double categoryBadgePadding = 8.0;
  static const double categoryBadgeRadius = 12.0;
  
  // ===== CARD SIZING CONSTANTS =====
  // Card sizing constants are now in AppSizes
  static const double cardMinHeight = 300.0;
  static const double cardMinHeightWeb = 350.0;
  static const double cardBorderRadius = 16.0;
  static const double cardShadowBlur = 4.0;
  static const double cardShadowOffset = 2.0;
  
  // ===== CARD CONTENT SIZING CONSTANTS =====
  // Card content sizing constants are now in AppTextStyles and AppSizes
  static const double cardFrontTextSize = 48.0;
  static const double cardBackTextSize = 24.0;
  static const double cardCompletionIconSize = 60.0;
  static const double cardCompletionTitleSize = 24.0;
  static const double cardCompletionSubtitleSize = 16.0;
  static const double cardCompletionSpacing = 16.0;
  static const double cardCompletionSubtitleSpacing = 8.0;
  
  // ===== ACTION BUTTON CONSTANTS =====
  // Action button constants are now in AppSizes
  static const double actionButtonIconSize = 24.0;
  static const double actionButtonLabelSize = 12.0;
  static const double actionButtonSpacing = 8.0;
  static const double actionButtonBorderRadius = 25.0;
  static const double actionButtonShadowBlur = 4.0;
  static const double actionButtonShadowOffset = 2.0;
  static const double actionButtonShadowSpread = 0.0;
  
  // ===== SPACING CONSTANTS =====
  // Spacing constants are now in AppSizes
  static const double cardContentSpacing = 20.0;
  static const double cardBackContentBottomPadding = 8.0;
  
  // ===== FONT WEIGHT CONSTANTS =====
  // Font weight constants are now in AppTextStyles
  static const FontWeight cardTitleWeight = FontWeight.bold;
  static const FontWeight cardBackWeight = FontWeight.w500;
  
  // ===== OPACITY CONSTANTS =====
  static const double secondaryTextOpacity = 0.7;
  static const double disabledButtonOpacity = 0.5;
  
  // ===== PROGRESS BAR CONSTANTS =====
  // Progress bar constants are now in AppSizes and AppTextStyles
  static const double progressBarHeight = 20.0;
  static const double progressBarBorderRadius = 10.0;
  static const double progressBarBorderWidth = 2.0;
  static const double progressBarSpacing = 16.0;
  static const double progressTextSize = 18.0;
  static const double progressScoreSize = 18.0;
  
  // ===== TEXT BACKGROUND CONSTANTS =====
  // Text background constants are now in AppSizes
  static const double textBackgroundPaddingHorizontal = 8.0;
  static const double textBackgroundPaddingVertical = 4.0;
  static const double textBackgroundBorderRadius = 6.0;
  
  // ===== REVIEW SECTION CONSTANTS =====
  // Review section constants are now in AppSizes
  static const double reviewSectionMarginTop = 8.0;
  static const double reviewSectionPaddingHorizontal = 16.0;
  static const double reviewSectionPaddingVertical = 12.0;
  static const double reviewSectionBorderRadius = 12.0;
  static const double reviewButtonPaddingHorizontal = 16.0;
  static const double reviewButtonPaddingVertical = 8.0;
  static const double reviewButtonBorderRadius = 8.0;
  static const double reviewButtonSpacing = 8.0;
  
  // ===== SWIPE HINT CONSTANTS =====
  // Swipe hint constants are now in AppSizes
  static const double swipeHintArrowSizeMultiplier = 0.06;
  static const double swipeHintLabelSizeMultiplier = 0.03;
  static const double swipeHintSpacingMultiplier = 0.005;
  
  // ===== CARD ANIMATION CONSTANTS =====
  // Card animation constants are now in AppSizes and AppTextStyles
  static const double cardAnimationSpacing = 20.0;
  static const double cardAnimationTextSize = 20.0;
  static const double cardAnimationSubtextSize = 16.0;
  static const double cardAnimationSubtextSpacing = 10.0;
  static const double cardAnimationBorderRadius = 16.0;
  static const double cardAnimationShadowBlur = 4.0;
  static const double cardAnimationShadowOffset = 2.0;
  static const double cardAnimationShadowSpread = 0.0;
  
  // ===== SPACING CONSTANTS =====
  // Spacing constants are now in AppSizes
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 20.0;
  
  // ===== ANIMATION CONSTANTS =====
  // Animation constants are now in AppDurations and AppSizes
  static const int animationDelayMs = 150;
  static const double cardHeightMultiplier = 0.35;
  static const double instructionSpacingMultiplier = 0.015;
  static const double instructionTextSizeMultiplier = 0.035;
  
  // ===== OPACITY CONSTANTS =====
  static const double shadowOpacity = 0.1;
  static const double textOpacityLight = 0.5;
  static const double textOpacityMedium = 0.7;
  
  // ===== BORDER CONSTANTS =====
  // Border constants are now in AppSizes
  static const double cardBorderWidth = 2.0;
  static const double cardVerticalPadding = 8.0;
  
  // ===== ICON AND SIZE CONSTANTS =====
  // Icon and size constants are now in AppSizes
  static const double emptyStateIconSize = 80.0;
  static const double themeIconSize = 20.0;
  static const double categoryIconSize = 20.0;
  static const double themeTileSize = 40.0;
  static const double categoryTileSize = 40.0;
  
  // ===== FONT WEIGHT CONSTANTS =====
  // Font weight constants are now in AppTextStyles
  static const FontWeight progressTextWeight = FontWeight.w600;
  static const FontWeight themeSelectedWeight = FontWeight.w600;
  static const FontWeight themeNormalWeight = FontWeight.w500;
  static const FontWeight categoryWeight = FontWeight.w500;
  static const FontWeight actionButtonWeight = FontWeight.w600;
  
  // ===== ANIMATION VALUES =====
  static const double animationEndValue = 1.0;
  static const double animationStartValue = 0.0;
  static const double progressMultiplier = 100.0;
  static const double luminanceThreshold = 0.5;
  
  // ===== SWIPE ANIMATION CONSTANTS =====
  // Swipe animation constants are now in AppSizes and AppDurations
  static const double swipeRotationMultiplier = 0.0003;
  static const double swipeThresholdOpacity = 0.7;
  static const int swipeOpacityAnimationDuration = 100;
  static const int swipeExitAnimationDuration = 300;
  static const int swipeReturnAnimationDuration = 400;
  static const double swipeExitDistanceMultiplier = 1.5;
  static const int swipeAnimationFrameRate = 16;
  
  // ===== SPACING VALUES =====
  // Spacing values are now in AppSizes
  static const double noSpacing = 0.0;
  static const double themeTilePadding = 16.0;
  static const double themeTileTopPadding = 8.0;
  static const double categorySpacing = 20.0;
  static const double categorySpacingSmall = 16.0;
  static const double categorySpacingLarge = 40.0;
  static const double dividerHeight = 32.0;
  static const double themeTileBorderRadius = 8.0;
  static const double themeTileBorderWidth = 2.0;
  static const double themeShadowBlur = 4.0;
  static const double themeShadowOffset = 2.0;
  static const double themeShadowOpacity = 0.3;
  
  // ===== TEXT SIZE CONSTANTS =====
  // Text size constants are now in AppTextStyles
  static const double themeTitleSize = 24.0;
  static const double categoryCountSize = 12.0;
  
  // ===== OPACITY VALUES =====
  static const double themeShadowAlpha = 0.3;
  
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
  
  // ===== RESPONSIVE DESIGN BREAKPOINTS =====
  // Responsive design breakpoints are now in AppSizes
  static const double mobileBreakpoint = 800.0;
  static const double desktopBreakpoint = 1200.0;
  
  // ===== RESPONSIVE DESIGN METHODS =====
  
  /// Get maximum content width based on screen size
  static double getMaxContentWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > desktopBreakpoint) return 800;
    if (screenWidth > mobileBreakpoint) return 600;
    return double.infinity; // Mobile (full width)
  }
  
  /// Get maximum card width based on screen size
  static double getCardMaxWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > desktopBreakpoint) return 500;
    if (screenWidth > mobileBreakpoint) return 400;
    return double.infinity; // Mobile (full width)
  }
  
  /// Get button size based on screen size
  static double getButtonSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > mobileBreakpoint) return 70.0;
    return 50.0;
  }
  
  /// Get button spacing based on screen size
  static double getButtonSpacing(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > mobileBreakpoint) return 24.0;
    return buttonSpacing; // Mobile spacing
  }
  
  /// Check if the current context is web/desktop
  static bool isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width > mobileBreakpoint;
  }
  
  // ===== NAVIGATION DRAWER CONSTANTS =====
  static const double drawerSpacingSmall = 8.0;
  static const double drawerSpacingMedium = 16.0;
  static const double drawerIconSize = 64.0;
  static const double drawerTitleSize = 18.0;
  static const double drawerSubtitleSize = 14.0;
}

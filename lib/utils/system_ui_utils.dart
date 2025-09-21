import 'package:flutter/material.dart';

/// Utility class for handling system UI elements like navigation bars
/// 
/// This class provides utilities for:
/// - Detecting system navigation bar presence
/// - Getting safe area insets
/// - Handling gesture vs button navigation
/// - Providing safe area widgets
class SystemUIUtils {
  /// Check if the system navigation bar is visible/enabled
  static bool hasSystemNavigationBar(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.bottom > 0;
  }
  
  /// Get the system navigation bar height
  static double getSystemNavigationBarHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.bottom;
  }
  
  /// Get the system status bar height
  static double getSystemStatusBarHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.top;
  }
  
  /// Get safe area padding for bottom navigation
  static EdgeInsets getBottomNavigationSafeArea(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      bottom: mediaQuery.padding.bottom,
    );
  }
  
  /// Check if the device has gesture navigation (Android 10+)
  static bool hasGestureNavigation(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Gesture navigation typically has very small bottom padding
    return mediaQuery.padding.bottom < 20;
  }
  
  /// Get recommended bottom navigation height including system UI
  static double getRecommendedBottomNavigationHeight(BuildContext context) {
    const double baseHeight = 80.0;
    final double systemPadding = getSystemNavigationBarHeight(context);
    return baseHeight + systemPadding;
  }
  
  /// Create a safe area widget that respects system UI
  /// 
  /// This widget automatically adjusts for:
  /// - System navigation bar (Android 3-button navigation)
  /// - Gesture navigation
  /// - Status bar
  /// - Notches and cutouts
  static Widget createSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
  
  /// Create a safe area widget specifically for scrollable content
  /// 
  /// This ensures scrollable content never overlaps with system UI
  static Widget createScrollableSafeArea({
    required Widget child,
    bool respectBottomNavigation = true,
  }) {
    return SafeArea(
      bottom: respectBottomNavigation,
      child: child,
    );
  }
}

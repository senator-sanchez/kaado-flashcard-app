/// Application duration constants
/// Centralizes all timing values for consistent animations and delays
class AppDurations {
  // ===== ANIMATION DURATIONS =====
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
  
  // ===== SWIPE ANIMATIONS =====
  static const Duration swipeOpacityAnimation = Duration(milliseconds: 100);
  static const Duration swipeExitAnimation = Duration(milliseconds: 300);
  static const Duration swipeReturnAnimation = Duration(milliseconds: 400);
  static const Duration swipeThresholdAnimation = Duration(milliseconds: 200);
  
  // ===== CARD ANIMATIONS =====
  static const Duration cardFlipAnimation = Duration(milliseconds: 600);
  static const Duration cardSlideAnimation = Duration(milliseconds: 400);
  static const Duration cardFadeAnimation = Duration(milliseconds: 300);
  static const Duration cardScaleAnimation = Duration(milliseconds: 250);
  
  // ===== FAB ANIMATIONS =====
  static const Duration fabOpenAnimation = Duration(milliseconds: 200);
  static const Duration fabCloseAnimation = Duration(milliseconds: 150);
  static const Duration fabItemAnimation = Duration(milliseconds: 100);
  
  // ===== PROGRESS ANIMATIONS =====
  static const Duration progressAnimation = Duration(milliseconds: 800);
  static const Duration progressBarAnimation = Duration(milliseconds: 600);
  static const Duration progressTextAnimation = Duration(milliseconds: 400);
  
  // ===== TRANSITION ANIMATIONS =====
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration dialogTransition = Duration(milliseconds: 250);
  static const Duration drawerTransition = Duration(milliseconds: 300);
  static const Duration bottomSheetTransition = Duration(milliseconds: 250);
  
  // ===== HOVER ANIMATIONS =====
  static const Duration hoverAnimation = Duration(milliseconds: 200);
  static const Duration rippleAnimation = Duration(milliseconds: 300);
  static const Duration focusAnimation = Duration(milliseconds: 150);
  
  // ===== LOADING ANIMATIONS =====
  static const Duration loadingAnimation = Duration(milliseconds: 1000);
  static const Duration shimmerAnimation = Duration(milliseconds: 1500);
  static const Duration pulseAnimation = Duration(milliseconds: 800);
  
  // ===== DELAYS =====
  static const Duration delayShort = Duration(milliseconds: 100);
  static const Duration delayMedium = Duration(milliseconds: 300);
  static const Duration delayLong = Duration(milliseconds: 500);
  static const Duration delayVeryLong = Duration(milliseconds: 1000);
  
  // ===== TIMEOUTS =====
  static const Duration timeoutShort = Duration(seconds: 5);
  static const Duration timeoutMedium = Duration(seconds: 10);
  static const Duration timeoutLong = Duration(seconds: 30);
  static const Duration timeoutVeryLong = Duration(minutes: 1);
  
  // ===== DEBOUNCE DURATIONS =====
  static const Duration debounceShort = Duration(milliseconds: 100);
  static const Duration debounceMedium = Duration(milliseconds: 300);
  static const Duration debounceLong = Duration(milliseconds: 500);
  
  // ===== REFRESH DURATIONS =====
  static const Duration refreshShort = Duration(seconds: 1);
  static const Duration refreshMedium = Duration(seconds: 3);
  static const Duration refreshLong = Duration(seconds: 5);
}

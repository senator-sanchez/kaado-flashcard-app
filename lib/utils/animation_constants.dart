import 'package:flutter/material.dart';

/// Animation constants for swipe effects and transitions
class AnimationConstants {
  // Animation durations
  static const Duration swipeDuration = Duration(milliseconds: 400);
  static const Duration quickAnimationDuration = Duration(milliseconds: 200);
  
  // Swipe animation parameters - Tinder-like short swipe distances
  static const double maxDragDistance = 200.0;
  static const double thresholdValue = 0.2535; // About 51px
  static const double rotationMax = 0.15;
  static const double scaleMin = 0.95;
  
  // Animation curves
  static const Curve swipeCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve quickCurve = Curves.easeInOut;
}

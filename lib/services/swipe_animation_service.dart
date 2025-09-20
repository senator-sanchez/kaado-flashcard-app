import 'package:flutter/services.dart';
import '../utils/animation_constants.dart';

/// Service to handle swipe animation logic and calculations
class SwipeAnimationService {
  static const double _thresholdValue = AnimationConstants.thresholdValue;
  static const double _maxDragDistance = AnimationConstants.maxDragDistance;
  static const double _rotationMax = AnimationConstants.rotationMax;
  static const double _scaleMin = AnimationConstants.scaleMin;

  /// Calculate rotation angle based on drag offset
  static double getRotationAngle(Offset dragOffset) {
    final double rotation = (dragOffset.dx / _maxDragDistance) * _rotationMax;
    return rotation.clamp(-_rotationMax, _rotationMax);
  }

  /// Calculate scale value based on drag distance
  static double getScaleValue(Offset dragOffset) {
    final double distance = dragOffset.distance;
    final double scale = 1.0 - (distance / _maxDragDistance) * (1.0 - _scaleMin);
    return scale.clamp(_scaleMin, 1.0);
  }

  /// Calculate fade opacity based on drag distance
  static double getFadeOpacity(Offset dragOffset) {
    final double distance = dragOffset.distance;
    final double opacity = 1.0 - (distance / _maxDragDistance) * 0.3;
    return opacity.clamp(0.7, 1.0);
  }

  /// Check if drag has reached the threshold for action
  static bool hasReachedThreshold(Offset dragOffset) {
    return dragOffset.distance >= _thresholdValue * _maxDragDistance;
  }

  /// Determine swipe direction from drag offset
  static SwipeDirection getSwipeDirection(Offset dragOffset) {
    if (dragOffset.dy.abs() > dragOffset.dx.abs()) {
      return SwipeDirection.vertical;
    } else if (dragOffset.dx > 0) {
      return SwipeDirection.right;
    } else {
      return SwipeDirection.left;
    }
  }

  /// Provide haptic feedback for swipe actions
  static void provideHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Provide haptic feedback for threshold reached
  static void provideThresholdFeedback() {
    HapticFeedback.selectionClick();
  }
}

enum SwipeDirection { left, right, vertical }

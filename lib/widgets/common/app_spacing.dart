import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

/// Reusable spacing widgets for consistent layout
class AppSpacing {
  // ===== HORIZONTAL SPACING =====
  static const Widget horizontalXSmall = SizedBox(width: AppSizes.spacingXSmall);
  static const Widget horizontalSmall = SizedBox(width: AppSizes.spacingSmall);
  static const Widget horizontalMedium = SizedBox(width: AppSizes.spacingMedium);
  static const Widget horizontalLarge = SizedBox(width: AppSizes.spacingLarge);
  static const Widget horizontalXLarge = SizedBox(width: AppSizes.spacingXLarge);
  static const Widget horizontalXXLarge = SizedBox(width: AppSizes.spacingXXLarge);
  static const Widget horizontalXXXLarge = SizedBox(width: AppSizes.spacingXXXLarge);

  // ===== VERTICAL SPACING =====
  static const Widget verticalXSmall = SizedBox(height: AppSizes.spacingXSmall);
  static const Widget verticalSmall = SizedBox(height: AppSizes.spacingSmall);
  static const Widget verticalMedium = SizedBox(height: AppSizes.spacingMedium);
  static const Widget verticalLarge = SizedBox(height: AppSizes.spacingLarge);
  static const Widget verticalXLarge = SizedBox(height: AppSizes.spacingXLarge);
  static const Widget verticalXXLarge = SizedBox(height: AppSizes.spacingXXLarge);
  static const Widget verticalXXXLarge = SizedBox(height: AppSizes.spacingXXXLarge);

  // ===== CUSTOM SPACING =====
  static Widget horizontal(double width) => SizedBox(width: width);
  static Widget vertical(double height) => SizedBox(height: height);
  static Widget square(double size) => SizedBox(width: size, height: size);

  // ===== RESPONSIVE SPACING =====
  static Widget responsiveHorizontal(BuildContext context, {
    double mobile = AppSizes.spacingMedium,
    double tablet = AppSizes.spacingLarge,
    double desktop = AppSizes.spacingXLarge,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > AppSizes.desktopBreakpoint) {
      return SizedBox(width: desktop);
    } else if (screenWidth > AppSizes.mobileBreakpoint) {
      return SizedBox(width: tablet);
    } else {
      return SizedBox(width: mobile);
    }
  }

  static Widget responsiveVertical(BuildContext context, {
    double mobile = AppSizes.spacingMedium,
    double tablet = AppSizes.spacingLarge,
    double desktop = AppSizes.spacingXLarge,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > AppSizes.desktopBreakpoint) {
      return SizedBox(height: desktop);
    } else if (screenWidth > AppSizes.mobileBreakpoint) {
      return SizedBox(height: tablet);
    } else {
      return SizedBox(height: mobile);
    }
  }
}

/// Divider with consistent styling
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });

  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? AppSizes.spacingMedium,
      thickness: thickness ?? 1.0,
      color: color,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

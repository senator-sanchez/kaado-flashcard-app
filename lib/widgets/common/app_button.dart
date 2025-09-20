import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';

/// Reusable button widget with consistent styling
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.fontSize,
    this.fontWeight,
    this.isLoading = false,
    this.isEnabled = true,
    this.size = AppButtonSize.medium,
  });

  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool isLoading;
  final bool isEnabled;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primaryBlue;
    final effectiveTextColor = textColor ?? AppColors.white;
    final effectivePadding = padding ?? _getPaddingForSize(size);
    final effectiveBorderRadius = borderRadius ?? _getBorderRadiusForSize(size);
    final effectiveFontSize = fontSize ?? _getFontSizeForSize(size);
    final effectiveFontWeight = fontWeight ?? _getFontWeightForSize(size);

    return ElevatedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveTextColor,
        padding: effectivePadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        elevation: AppSizes.shadowOffsetMedium,
        shadowColor: AppColors.shadowMedium,
      ),
      child: isLoading
          ? SizedBox(
              width: AppSizes.iconSmall,
              height: AppSizes.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: effectiveFontSize,
                fontWeight: effectiveFontWeight,
              ),
            ),
    );
  }

  EdgeInsetsGeometry _getPaddingForSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: AppSizes.paddingSmall,
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.paddingMedium,
        );
      case AppButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXLarge,
          vertical: AppSizes.paddingLarge,
        );
    }
  }

  double _getBorderRadiusForSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.radiusMedium;
      case AppButtonSize.medium:
        return AppSizes.radiusLarge;
      case AppButtonSize.large:
        return AppSizes.radiusXLarge;
    }
  }

  double _getFontSizeForSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonSmall.fontSize!;
      case AppButtonSize.medium:
        return AppTextStyles.buttonMedium.fontSize!;
      case AppButtonSize.large:
        return AppTextStyles.buttonLarge.fontSize!;
    }
  }

  FontWeight _getFontWeightForSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonSmall.fontWeight!;
      case AppButtonSize.medium:
        return AppTextStyles.buttonMedium.fontWeight!;
      case AppButtonSize.large:
        return AppTextStyles.buttonLarge.fontWeight!;
    }
  }
}

/// Button size enumeration
enum AppButtonSize {
  small,
  medium,
  large,
}

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

/// Reusable card widget with consistent styling
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation,
    this.shadowColor,
    this.border,
    this.onTap,
  });

  final Widget child;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? shadowColor;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusXLarge),
        border: border,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? AppColors.shadowLight,
            blurRadius: AppSizes.shadowBlurMedium,
            offset: Offset(0, AppSizes.shadowOffsetMedium),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppSizes.paddingLarge),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusXLarge),
        child: card,
      );
    }

    return card;
  }
}

/// Card with background photo support
class AppCardWithBackground extends StatelessWidget {
  const AppCardWithBackground({
    super.key,
    required this.child,
    this.backgroundImage,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation,
    this.shadowColor,
    this.border,
    this.onTap,
  });

  final Widget child;
  final String? backgroundImage;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? shadowColor;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusXLarge),
        border: border,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? AppColors.shadowLight,
            blurRadius: AppSizes.shadowBlurMedium,
            offset: Offset(0, AppSizes.shadowOffsetMedium),
          ),
        ],
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radiusXLarge),
          child: Padding(
            padding: padding ?? EdgeInsets.all(AppSizes.paddingLarge),
            child: child,
          ),
        ),
      ),
    );
  }
}

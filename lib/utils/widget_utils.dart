import 'package:flutter/material.dart';
import 'constants.dart';
import 'theme_colors.dart';

/// Utility class for common widget patterns and layouts
/// Follows DRY principles by centralizing common widget creation logic
class WidgetUtils {
  static final ThemeColors _colors = ThemeColors.instance;

  /// Creates a standard spacing widget
  static Widget spacing({double? height, double? width}) {
    return SizedBox(
      height: height ?? AppConstants.smallSpacing,
      width: width ?? AppConstants.smallSpacing,
    );
  }

  /// Creates a standard padding widget
  static Widget padding({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? all,
    double? horizontal,
    double? vertical,
  }) {
    EdgeInsetsGeometry finalPadding;
    
    if (padding != null) {
      finalPadding = padding;
    } else if (all != null) {
      finalPadding = EdgeInsets.all(all);
    } else if (horizontal != null || vertical != null) {
      finalPadding = EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    } else {
      finalPadding = EdgeInsets.all(AppConstants.cardPadding);
    }

    return Padding(
      padding: finalPadding,
      child: child,
    );
  }

  /// Creates a standard container with decoration
  static Widget container({
    required Widget child,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? _colors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.cardBorderRadius),
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }

  /// Creates a standard text widget with theme-aware styling
  static Widget text(
    String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize ?? AppConstants.englishTextSize,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? _colors.primaryText,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Creates a standard icon widget with theme-aware styling
  static Widget icon(
    IconData icon, {
    double? size,
    Color? color,
  }) {
    return Icon(
      icon,
      size: size ?? AppConstants.categoryIconSize,
      color: color ?? _colors.primaryIcon,
    );
  }

  /// Creates a standard elevated button with theme-aware styling
  static Widget elevatedButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? _colors.primaryBlue,
        foregroundColor: textColor ?? _colors.buttonTextOnColored,
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: AppConstants.reviewButtonPaddingHorizontal,
          vertical: AppConstants.reviewButtonPaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.reviewButtonBorderRadius),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? AppConstants.buttonTextSize,
          fontWeight: fontWeight ?? FontWeight.w600,
        ),
      ),
    );
  }

  /// Creates a standard row with consistent spacing
  static Widget row({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double? spacing,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: spacing ?? AppConstants.reviewButtonSpacing));
      }
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }

  /// Creates a standard column with consistent spacing
  static Widget column({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double? spacing,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: spacing ?? AppConstants.smallSpacing));
      }
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }
}

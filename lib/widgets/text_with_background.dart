import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../services/background_photo_service.dart';

/// A widget that wraps text with a solid background when background images are active
class TextWithBackground extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool
  isTopText; // true for progress bar, action buttons, instructions; false for swipe hints

  const TextWithBackground(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isTopText = true, // Default to top text
  });

  @override
  State<TextWithBackground> createState() => _TextWithBackgroundState();
}

class _TextWithBackgroundState extends State<TextWithBackground> {
  final BackgroundPhotoService _backgroundPhotoService =
      BackgroundPhotoService.instance;

  @override
  void initState() {
    super.initState();
    _backgroundPhotoService.addListener(_onBackgroundChanged);
  }

  @override
  void dispose() {
    _backgroundPhotoService.removeListener(_onBackgroundChanged);
    super.dispose();
  }

  void _onBackgroundChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final hasBackgroundImage = _backgroundPhotoService.hasBackgroundPhoto;

    if (!hasBackgroundImage) {
      // No background image, return normal text
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    // Background image is active, wrap text with appropriate background
    final backgroundColor = widget.isTopText
        ? appTheme.topTextBackgroundColor // Light grey for top text
        : appTheme.cardBackground; // Theme-aware background for swipe hints

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.textBackgroundPaddingHorizontal,
        vertical: AppConstants.textBackgroundPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          AppConstants.textBackgroundBorderRadius,
        ),
      ),
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}

/// A widget that wraps a child with a solid background when background images are active
class WidgetWithBackground extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const WidgetWithBackground({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  State<WidgetWithBackground> createState() => _WidgetWithBackgroundState();
}

class _WidgetWithBackgroundState extends State<WidgetWithBackground> {
  final BackgroundPhotoService _backgroundPhotoService =
      BackgroundPhotoService.instance;

  @override
  void initState() {
    super.initState();
    _backgroundPhotoService.addListener(_onBackgroundChanged);
  }

  @override
  void dispose() {
    _backgroundPhotoService.removeListener(_onBackgroundChanged);
    super.dispose();
  }

  void _onBackgroundChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final hasBackgroundImage = _backgroundPhotoService.hasBackgroundPhoto;

    if (!hasBackgroundImage) {
      // No background image, return child as-is
      return widget.child;
    }

    // Background image is active, wrap child with contrasting background
    // For WidgetWithBackground, we'll use a default contrasting color
    // since we can't easily determine the child's text color
    final backgroundColor = _getDefaultContrastingBackgroundColor();

    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(
            horizontal: AppConstants.textBackgroundPaddingHorizontal,
            vertical: AppConstants.textBackgroundPaddingVertical,
          ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            widget.borderRadius ??
            BorderRadius.circular(AppConstants.textBackgroundBorderRadius),
      ),
      child: widget.child,
    );
  }

  /// Get a default contrasting background color based on the theme
  Color _getDefaultContrastingBackgroundColor() {
    final appTheme = context.appTheme;
    // Use the consolidated function for icon background colors
    return appTheme.cardBackground.withValues(alpha: 0.9);
  }
}

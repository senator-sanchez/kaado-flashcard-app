// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Utils
import '../../utils/app_theme.dart';

/// Shared section header component for consistent styling
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: TextStyle(
              color: appTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

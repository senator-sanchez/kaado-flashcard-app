import 'package:flutter/material.dart';
import '../../utils/theme_colors.dart';

/// Shared section header component for consistent styling
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.instance;
    
    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.primaryIcon,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
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

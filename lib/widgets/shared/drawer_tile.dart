import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/decoration_utils.dart';

/// Shared drawer tile component for consistent styling
class DrawerTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isSelected;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const DrawerTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
    this.isSelected = false,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: appTheme.surface, // Use surface color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.primaryColor : appTheme.divider,
          width: isSelected ? 2 : 1,
        ),
        // Remove heavy shadows - use subtle shadows like v10.2
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 4.0,
            offset: Offset(0, 2.0),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? (isSelected ? theme.primaryColor : appTheme.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primaryColor : appTheme.divider,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? (isSelected ? appTheme.buttonTextOnColored : appTheme.primaryIcon),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: appTheme.primaryText, // Use primary text color (adapts to theme)
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: appTheme.secondaryText, // Use secondary text color (adapts to theme)
                  fontSize: 14,
                ),
              )
            : null,
        trailing: trailing ?? (isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 20,
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: appTheme.secondaryIcon,
                size: 16,
              )),
        onTap: onTap,
      ),
    );
  }
}

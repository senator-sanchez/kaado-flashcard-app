import 'package:flutter/material.dart';
import '../../utils/theme_colors.dart';
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
    final colors = ThemeColors.instance;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: DecorationUtils.tileDecoration(
        isSelected: isSelected,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? (isSelected ? colors.primaryBlue : colors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primaryBlue : colors.divider,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? (isSelected ? colors.appBarIcon : colors.primaryIcon),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: trailing ?? (isSelected
            ? Icon(
                Icons.check_circle,
                color: colors.primaryBlue,
                size: 20,
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: colors.secondaryIcon,
                size: 16,
              )),
        onTap: onTap,
      ),
    );
  }
}

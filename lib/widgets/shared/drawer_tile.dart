import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Shared drawer tile component following Material Design best practices
class DrawerTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isSelected;
  final Color? iconColor;

  const DrawerTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
    this.isSelected = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? (isSelected ? theme.primaryColor : appTheme.primaryIcon),
              size: 24,
            ),
            SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: appTheme.primaryText,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: appTheme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? (isSelected
                ? Icon(
                    Icons.check,
                    color: theme.primaryColor,
                    size: 20,
                  )
                : Icon(
                    Icons.chevron_right,
                    color: appTheme.secondaryIcon,
                    size: 20,
                  )),
          ],
        ),
      ),
    );
  }
}
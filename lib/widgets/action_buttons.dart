import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import 'text_with_background.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onShuffle;
  final VoidCallback onReset;

  const ActionButtons({
    super.key,
    required this.onShuffle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 8, 
        horizontal: AppConstants.isWeb(context) ? 40 : 20,
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
        // Shuffle Button
        _ActionButton(
          icon: Icons.shuffle,
          label: 'Shuffle',
          onPressed: onShuffle,
          isEnabled: true,
        ),
        
        // Reset Button
        _ActionButton(
          icon: Icons.refresh,
          label: 'Reset',
          onPressed: onReset,
          isEnabled: true,
        ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    
    return Column(
      children: [
        Container(
          width: AppConstants.getButtonSize(context),
          height: AppConstants.getButtonSize(context),
          decoration: BoxDecoration(
            color: isEnabled ? appTheme.actionButtonBackground : appTheme.actionButtonBackground.withValues(alpha: AppConstants.disabledButtonOpacity),
            borderRadius: BorderRadius.circular(AppConstants.actionButtonBorderRadius),
            boxShadow: [
              BoxShadow(
                color: appTheme.cardShadow,
                blurRadius: AppConstants.actionButtonShadowBlur,
                offset: Offset(0, AppConstants.actionButtonShadowOffset),
                spreadRadius: AppConstants.actionButtonShadowSpread,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: appTheme.actionButtonText),
            onPressed: isEnabled ? onPressed : null,
          ),
        ),
        SizedBox(height: AppConstants.actionButtonSpacing),
        TextWithBackground(
          label,
          style: TextStyle(
            fontSize: AppConstants.actionButtonLabelSize,
            color: appTheme.actionButtonLabelText,
            fontWeight: AppConstants.actionButtonWeight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

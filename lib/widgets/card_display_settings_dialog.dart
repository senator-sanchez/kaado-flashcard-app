import 'package:flutter/material.dart';
import '../models/card_display_settings.dart';
import '../services/card_display_service.dart';
import '../utils/app_theme.dart';

/// Dialog for configuring card display settings
class CardDisplaySettingsDialog extends StatefulWidget {
  const CardDisplaySettingsDialog({super.key});

  @override
  State<CardDisplaySettingsDialog> createState() => _CardDisplaySettingsDialogState();
}

class _CardDisplaySettingsDialogState extends State<CardDisplaySettingsDialog> {
  late CardDisplaySettings _settings;
  final CardDisplayService _service = CardDisplayService.instance;

  @override
  void initState() {
    super.initState();
    _settings = _service.currentSettings;
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return AlertDialog(
      backgroundColor: appTheme.surface,
      title: Text(
        'Card Display Settings',
        style: TextStyle(
          color: appTheme.primaryText,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Front Display Section
            Text(
              'Front of Card',
              style: TextStyle(
                color: appTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            ...CardDisplayType.values.map((type) => _buildRadioTile(
              type,
              _settings.frontDisplay,
              (value) => setState(() => _settings = _settings.copyWith(frontDisplay: value!)),
            )),
            
            SizedBox(height: 24),
            
            // Back Display Section
            Text(
              'Back of Card (check all that apply)',
              style: TextStyle(
                color: appTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            ...CardDisplayType.values.map((type) => _buildCheckboxTile(
              type,
              _settings.backDisplays.contains(type),
              type == _settings.frontDisplay ? null : (value) {
                setState(() {
                  final newBackDisplays = List<CardDisplayType>.from(_settings.backDisplays);
                  if (value == true) {
                    newBackDisplays.add(type);
                  } else {
                    newBackDisplays.remove(type);
                  }
                  _settings = _settings.copyWith(backDisplays: newBackDisplays);
                });
              },
              isDisabled: type == _settings.frontDisplay,
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: appTheme.secondaryText),
          ),
        ),
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await _service.saveSettings(_settings);
            if (mounted) {
              navigator.pop();
            }
          },
          child: Text(
            'Save',
            style: TextStyle(
              color: appTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioTile(
    CardDisplayType type,
    CardDisplayType selectedType,
    ValueChanged<CardDisplayType?> onChanged,
  ) {
    final appTheme = context.appTheme;
    final isSelected = type == selectedType;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? appTheme.primaryBlue.withValues(alpha: 0.1) : appTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? appTheme.primaryBlue : appTheme.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<CardDisplayType>(
        value: type,
        // ignore: deprecated_member_use
        groupValue: selectedType,
        // ignore: deprecated_member_use
        onChanged: onChanged,
        title: Text(
          type.displayName,
          style: TextStyle(
            color: appTheme.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          type.description,
          style: TextStyle(
            color: appTheme.secondaryText,
            fontSize: 12,
          ),
        ),
        activeColor: appTheme.primaryBlue,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildCheckboxTile(
    CardDisplayType type,
    bool isChecked,
    ValueChanged<bool?>? onChanged,
    {bool isDisabled = false}
  ) {
    final appTheme = context.appTheme;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isDisabled 
          ? appTheme.surface.withValues(alpha: 0.5)
          : isChecked ? appTheme.primaryBlue.withValues(alpha: 0.1) : appTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDisabled 
            ? appTheme.divider.withValues(alpha: 0.5)
            : isChecked ? appTheme.primaryBlue : appTheme.divider,
          width: isChecked ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: isDisabled ? null : onChanged,
        title: Text(
          type.displayName,
          style: TextStyle(
            color: isDisabled ? appTheme.secondaryText.withValues(alpha: 0.5) : appTheme.primaryText,
            fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          isDisabled ? 'Same as front display' : type.description,
          style: TextStyle(
            color: isDisabled ? appTheme.secondaryText.withValues(alpha: 0.5) : appTheme.secondaryText,
            fontSize: 12,
          ),
        ),
        activeColor: appTheme.primaryBlue,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
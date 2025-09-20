import 'package:flutter/material.dart';
import '../models/card_display_settings.dart';
import '../services/card_display_service.dart';
import '../utils/theme_colors.dart';

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
    final colors = ThemeColors.instance;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Card Display Settings',
        style: TextStyle(
          color: colors.primaryText,
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
                color: colors.primaryText,
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
                color: colors.primaryText,
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
            style: TextStyle(color: colors.secondaryText),
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
              color: colors.primaryBlue,
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
    final colors = ThemeColors.instance;
    final isSelected = type == selectedType;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? colors.primaryBlue.withValues(alpha: 0.1) : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? colors.primaryBlue : colors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<CardDisplayType>(
        value: type,
        groupValue: selectedType,
        onChanged: onChanged,
        title: Text(
          type.displayName,
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          type.description,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 12,
          ),
        ),
        activeColor: colors.primaryBlue,
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
    final colors = ThemeColors.instance;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isDisabled 
          ? colors.surface.withValues(alpha: 0.5)
          : isChecked ? colors.primaryBlue.withValues(alpha: 0.1) : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDisabled 
            ? colors.divider.withValues(alpha: 0.5)
            : isChecked ? colors.primaryBlue : colors.divider,
          width: isChecked ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: isDisabled ? null : onChanged,
        title: Text(
          type.displayName,
          style: TextStyle(
            color: isDisabled ? colors.secondaryText.withValues(alpha: 0.5) : colors.primaryText,
            fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          isDisabled ? 'Same as front display' : type.description,
          style: TextStyle(
            color: isDisabled ? colors.secondaryText.withValues(alpha: 0.5) : colors.secondaryText,
            fontSize: 12,
          ),
        ),
        activeColor: colors.primaryBlue,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
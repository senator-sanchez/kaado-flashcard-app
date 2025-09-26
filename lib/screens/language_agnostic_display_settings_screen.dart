import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
import '../models/language_agnostic_display_settings.dart';
import '../models/language_field_option.dart';
import '../models/card_display_settings.dart';

/// Language-agnostic Card Display Settings Screen
/// 
/// Allows users to customize what fields appear on the front and back of cards
/// for any language combination. This is critical for multi-language support.
class LanguageAgnosticDisplaySettingsScreen extends ConsumerStatefulWidget {
  final String targetLanguage;
  final String userLanguage;
  
  const LanguageAgnosticDisplaySettingsScreen({
    super.key,
    required this.targetLanguage,
    required this.userLanguage,
  });

  @override
  ConsumerState<LanguageAgnosticDisplaySettingsScreen> createState() => _LanguageAgnosticDisplaySettingsScreenState();
}

class _LanguageAgnosticDisplaySettingsScreenState extends ConsumerState<LanguageAgnosticDisplaySettingsScreen> {
  late LanguageAgnosticDisplaySettings _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load current card display settings
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // For now, use default settings for the target language
      // In a real implementation, this would load from storage
      _settings = LanguageAgnosticDisplaySettings.getDefaultForLanguage(widget.targetLanguage);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  /// Save card display settings
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real implementation, this would save to storage
      // For now, just show success message
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
        // Close the screen and return to main screen after saving
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.appBarBackground,
        foregroundColor: appTheme.appBarIcon,
        elevation: 0,
        title: Text(
          'Card Display Settings',
          style: TextStyle(
            color: appTheme.appBarIcon,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appTheme.primaryIcon,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: TextStyle(
                  color: appTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: appTheme.primaryIcon,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSizes.paddingMedium,
                right: AppSizes.paddingMedium,
                top: AppSizes.paddingMedium,
                bottom: AppSizes.paddingLarge + 80, // Extra padding for Android navigation
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageInfo(appTheme),
                  SizedBox(height: AppSizes.spacingLarge),
                  
                  _buildSectionHeader('Front Card Display', appTheme),
                  SizedBox(height: AppSizes.spacingMedium),
                  _buildFrontCardSettings(appTheme),
                  
                  SizedBox(height: AppSizes.spacingLarge),
                  
                  _buildSectionHeader('Back Card Display', appTheme),
                  SizedBox(height: AppSizes.spacingMedium),
                  _buildBackCardSettings(appTheme),
                  
                  SizedBox(height: AppSizes.spacingLarge),
                  
                  _buildSectionHeader('Study Modes', appTheme),
                  SizedBox(height: AppSizes.spacingMedium),
                  _buildStudyModeSettings(appTheme),
                ],
              ),
            ),
    );
  }

  Widget _buildLanguageInfo(AppThemeExtension appTheme) {
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Row(
          children: [
            Icon(
              Icons.language,
              color: appTheme.primaryIcon,
              size: 24,
            ),
            SizedBox(width: AppSizes.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: appTheme.primaryText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Learning: ${widget.targetLanguage.toUpperCase()} | Native: ${widget.userLanguage.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeExtension appTheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: appTheme.primaryText,
      ),
    );
  }

  Widget _buildFrontCardSettings(AppThemeExtension appTheme) {
    final availableFields = LanguageFieldOptions.getFieldsForLanguage(widget.targetLanguage);
    
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: availableFields.map((field) {
            return _buildRadioOption(
              field.displayName,
              field.description,
              field,
              _settings.frontField,
              (value) => setState(() => _settings = _settings.copyWith(frontField: value)),
              appTheme,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBackCardSettings(AppThemeExtension appTheme) {
    final availableFields = LanguageFieldOptions.getFieldsForLanguage(widget.targetLanguage);
    
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: availableFields.map((field) {
            // Check if this field would conflict with front field
            final wouldConflict = _wouldConflictWithFront(field);
            final isCurrentlySelected = _settings.backFields.contains(field);

            return _buildCheckboxOption(
              field.displayName,
              field.description,
              field,
              isCurrentlySelected,
              (isChecked) {
                if (isChecked && wouldConflict) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot select ${field.displayName} for back when it\'s already selected for front'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final newBackFields = Set<LanguageFieldOption>.from(_settings.backFields);
                if (isChecked) {
                  newBackFields.add(field);
                } else {
                  newBackFields.remove(field);
                }
                setState(() => _settings = _settings.copyWith(backFields: newBackFields));
              },
              appTheme,
              isDisabled: wouldConflict && !isCurrentlySelected,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStudyModeSettings(AppThemeExtension appTheme) {
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            _buildRadioOption(
              'Recognition Mode',
              'See ${widget.targetLanguage}, guess ${widget.userLanguage}',
              CardDisplayMode.recognition,
              _settings.displayMode,
              (value) => setState(() => _settings = _settings.copyWith(displayMode: value)),
              appTheme,
            ),
            _buildRadioOption(
              'Production Mode',
              'See ${widget.userLanguage}, produce ${widget.targetLanguage}',
              CardDisplayMode.production,
              _settings.displayMode,
              (value) => setState(() => _settings = _settings.copyWith(displayMode: value)),
              appTheme,
            ),
            _buildRadioOption(
              'Mixed Mode',
              'Random front/back combinations',
              CardDisplayMode.mixed,
              _settings.displayMode,
              (value) => setState(() => _settings = _settings.copyWith(displayMode: value)),
              appTheme,
            ),
          ],
        ),
      ),
    );
  }

  /// Check if a back field would conflict with the current front field
  bool _wouldConflictWithFront(LanguageFieldOption backField) {
    return _settings.frontField == backField;
  }

  Widget _buildRadioOption<T>(
    String title,
    String subtitle,
    T value,
    T groupValue,
    ValueChanged<T> onChanged,
    AppThemeExtension appTheme,
  ) {
    return RadioListTile<T>(
      title: Text(
        title,
        style: TextStyle(
          color: appTheme.primaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: appTheme.secondaryText,
          fontSize: 12,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: (value) => onChanged(value!),
      activeColor: appTheme.primaryBlue,
    );
  }

  Widget _buildCheckboxOption<T>(
    String title,
    String subtitle,
    T value,
    bool isChecked,
    ValueChanged<bool> onChanged,
    AppThemeExtension appTheme, {
    bool isDisabled = false,
  }) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDisabled ? appTheme.secondaryText.withValues(alpha: 0.5) : appTheme.primaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDisabled ? appTheme.secondaryText.withValues(alpha: 0.5) : appTheme.secondaryText,
          fontSize: 12,
        ),
      ),
      value: isChecked,
      onChanged: isDisabled ? null : (checked) => onChanged(checked!),
      activeColor: appTheme.primaryBlue,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

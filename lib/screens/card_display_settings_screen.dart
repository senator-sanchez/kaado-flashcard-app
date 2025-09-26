import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
import '../services/card_display_service.dart';
import '../models/card_display_settings.dart';

/// Card Display Settings Screen
/// 
/// Allows users to customize what fields appear on the front and back of cards.
/// This is critical for language learning flexibility and different study modes.
class CardDisplaySettingsScreen extends ConsumerStatefulWidget {
  const CardDisplaySettingsScreen({super.key});

  @override
  ConsumerState<CardDisplaySettingsScreen> createState() => _CardDisplaySettingsScreenState();
}

class _CardDisplaySettingsScreenState extends ConsumerState<CardDisplaySettingsScreen> {
  late CardDisplaySettings _settings;
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
      final settings = await CardDisplayService.instance.getDisplaySettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
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
      await CardDisplayService.instance.saveDisplaySettings(_settings);
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
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            _buildRadioOption(
              'Kana',
              'Show Japanese kana characters',
              FrontCardOption.kana,
              _settings.frontCardOption,
              (value) => setState(() => _settings = _settings.copyWith(frontCardOption: value)),
              appTheme,
            ),
            _buildRadioOption(
              'Hiragana',
              'Show only hiragana characters',
              FrontCardOption.hiragana,
              _settings.frontCardOption,
              (value) => setState(() => _settings = _settings.copyWith(frontCardOption: value)),
              appTheme,
            ),
            _buildRadioOption(
              'Kanji',
              'Show kanji characters',
              FrontCardOption.kanji,
              _settings.frontCardOption,
              (value) => setState(() => _settings = _settings.copyWith(frontCardOption: value)),
              appTheme,
            ),
            _buildRadioOption(
              'Romaji',
              'Show romanized text',
              FrontCardOption.romaji,
              _settings.frontCardOption,
              (value) => setState(() => _settings = _settings.copyWith(frontCardOption: value)),
              appTheme,
            ),
            _buildRadioOption(
              'English',
              'Show English translation',
              FrontCardOption.english,
              _settings.frontCardOption,
              (value) => setState(() => _settings = _settings.copyWith(frontCardOption: value)),
              appTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCardSettings(AppThemeExtension appTheme) {
    // Always show all back options in consistent static order
    final allBackOptions = [
      BackCardOption.kana,
      BackCardOption.hiragana,
      BackCardOption.kanji,
      BackCardOption.romaji,
      BackCardOption.english,
    ];

    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: allBackOptions.map((option) {
            String title;
            String subtitle;
            
            switch (option) {
              case BackCardOption.kana:
                title = 'Kana';
                subtitle = 'Show Japanese kana characters';
                break;
              case BackCardOption.hiragana:
                title = 'Hiragana';
                subtitle = 'Show only hiragana characters';
                break;
              case BackCardOption.kanji:
                title = 'Kanji';
                subtitle = 'Show kanji characters';
                break;
              case BackCardOption.romaji:
                title = 'Romaji';
                subtitle = 'Show romanized text';
                break;
              case BackCardOption.english:
                title = 'English';
                subtitle = 'Show English translation';
                break;
            }

            // Check if this option would conflict with front card option
            final wouldConflict = _wouldConflictWithFront(option);
            final isCurrentlySelected = _settings.backCardOptions.contains(option);

            return _buildCheckboxOption(
              title,
              subtitle,
              option,
              isCurrentlySelected,
              (isChecked) {
                if (isChecked && wouldConflict) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot select $title for back when it\'s already selected for front'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final newBackOptions = Set<BackCardOption>.from(_settings.backCardOptions);
                if (isChecked) {
                  newBackOptions.add(option);
                } else {
                  newBackOptions.remove(option);
                }
                setState(() => _settings = _settings.copyWith(backCardOptions: newBackOptions));
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
              'See Japanese, guess English',
              CardDisplayMode.recognition,
              _settings.displayMode,
              (value) => setState(() => _settings = _settings.copyWith(displayMode: value)),
              appTheme,
            ),
            _buildRadioOption(
              'Production Mode',
              'See English, produce Japanese',
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

  /// Check if a back card option would conflict with the current front card option
  bool _wouldConflictWithFront(BackCardOption backOption) {
    switch (_settings.frontCardOption) {
      case FrontCardOption.kana:
        return backOption == BackCardOption.kana;
      case FrontCardOption.hiragana:
        return backOption == BackCardOption.hiragana;
      case FrontCardOption.kanji:
        return backOption == BackCardOption.kanji;
      case FrontCardOption.romaji:
        return backOption == BackCardOption.romaji;
      case FrontCardOption.english:
        return backOption == BackCardOption.english;
    }
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

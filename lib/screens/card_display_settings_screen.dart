import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
// import '../constants/app_strings.dart'; // Unused import removed
import '../services/card_display_service.dart';
import '../models/card_display_settings.dart';

/// Card Display Settings Screen
/// 
/// Allows users to customize what fields appear on the front and back of cards.
/// This is critical for language learning flexibility and different study modes.
class CardDisplaySettingsScreen extends StatefulWidget {
  const CardDisplaySettingsScreen({super.key});

  @override
  State<CardDisplaySettingsScreen> createState() => _CardDisplaySettingsScreenState();
}

class _CardDisplaySettingsScreenState extends State<CardDisplaySettingsScreen> {
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
    final theme = Theme.of(context);
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
            color: appTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.paddingMedium),
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
                  
                  SizedBox(height: AppSizes.spacingLarge),
                  
                  _buildSectionHeader('Field Visibility', appTheme),
                  SizedBox(height: AppSizes.spacingMedium),
                  _buildFieldVisibilitySettings(appTheme),
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
            _buildFieldOption(
              'Kana (Hiragana/Katakana)',
              'Show Japanese kana characters',
              _settings.showKana,
              (value) => setState(() => _settings = _settings.copyWith(showKana: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Hiragana Only',
              'Show only hiragana characters',
              _settings.showHiragana,
              (value) => setState(() => _settings = _settings.copyWith(showHiragana: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Kanji',
              'Show kanji characters',
              _settings.showKanji,
              (value) => setState(() => _settings = _settings.copyWith(showKanji: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Romaji',
              'Show romanized text',
              _settings.showRomaji,
              (value) => setState(() => _settings = _settings.copyWith(showRomaji: value)),
              appTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCardSettings(AppThemeExtension appTheme) {
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            _buildFieldOption(
              'English Translation',
              'Show English translations',
              _settings.showEnglish,
              (value) => setState(() => _settings = _settings.copyWith(showEnglish: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Notes',
              'Show user notes',
              _settings.showNotes,
              (value) => setState(() => _settings = _settings.copyWith(showNotes: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Pronunciation',
              'Show pronunciation guides',
              _settings.showPronunciation,
              (value) => setState(() => _settings = _settings.copyWith(showPronunciation: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Context',
              'Show example sentences',
              _settings.showContext,
              (value) => setState(() => _settings = _settings.copyWith(showContext: value)),
              appTheme,
            ),
          ],
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

  Widget _buildFieldVisibilitySettings(AppThemeExtension appTheme) {
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            _buildFieldOption(
              'Show Field Labels',
              'Display field names (e.g., "Kana:", "English:")',
              _settings.showFieldLabels,
              (value) => setState(() => _settings = _settings.copyWith(showFieldLabels: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Compact Mode',
              'Use smaller text and spacing',
              _settings.compactMode,
              (value) => setState(() => _settings = _settings.copyWith(compactMode: value)),
              appTheme,
            ),
            _buildFieldOption(
              'Highlight Differences',
              'Highlight differences between similar cards',
              _settings.highlightDifferences,
              (value) => setState(() => _settings = _settings.copyWith(highlightDifferences: value)),
              appTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    AppThemeExtension appTheme,
  ) {
    return SwitchListTile(
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
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildRadioOption(
    String title,
    String subtitle,
    CardDisplayMode value,
    CardDisplayMode groupValue,
    ValueChanged<CardDisplayMode> onChanged,
    AppThemeExtension appTheme,
  ) {
    return RadioListTile<CardDisplayMode>(
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
      activeColor: Theme.of(context).primaryColor,
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/card_display_settings.dart';
import '../services/app_logger.dart';

/// Service to manage comprehensive card display settings
/// 
/// Handles all card display preferences including front/back fields,
/// study modes, and UI preferences. Critical for language learning flexibility.
class CardDisplayService {
  static const String _settingsKey = 'card_display_settings';
  static CardDisplayService? _instance;
  
  static CardDisplayService get instance => _instance ??= CardDisplayService._();
  CardDisplayService._();

  CardDisplaySettings _currentSettings = CardDisplaySettings.defaultSettings;

  /// Get current display settings
  CardDisplaySettings get currentSettings => _currentSettings;

  /// Load settings from shared preferences
  Future<CardDisplaySettings> getDisplaySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = CardDisplaySettings.fromJson(settingsMap);
        AppLogger.info('Card display settings loaded successfully');
      } else {
        AppLogger.info('No saved settings found, using defaults');
      }
    } catch (e) {
      AppLogger.error('Error loading card display settings', e);
      _currentSettings = CardDisplaySettings.defaultSettings;
    }
    
    return _currentSettings;
  }

  /// Save settings to shared preferences
  Future<void> saveDisplaySettings(CardDisplaySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
      _currentSettings = settings;
      AppLogger.info('Card display settings saved successfully');
    } catch (e) {
      AppLogger.error('Error saving card display settings', e);
      rethrow;
    }
  }

  /// Update front card display options
  Future<void> updateFrontCardSettings({
    bool? showKana,
    bool? showHiragana,
    bool? showKanji,
    bool? showRomaji,
  }) async {
    final newSettings = _currentSettings.copyWith(
      showKana: showKana,
      showHiragana: showHiragana,
      showKanji: showKanji,
      showRomaji: showRomaji,
    );
    
    await saveDisplaySettings(newSettings);
  }

  /// Update back card display options
  Future<void> updateBackCardSettings({
    bool? showEnglish,
    bool? showNotes,
    bool? showPronunciation,
    bool? showContext,
  }) async {
    final newSettings = _currentSettings.copyWith(
      showEnglish: showEnglish,
      showNotes: showNotes,
      showPronunciation: showPronunciation,
      showContext: showContext,
    );
    
    await saveDisplaySettings(newSettings);
  }

  /// Update study mode
  Future<void> updateStudyMode(CardDisplayMode displayMode) async {
    final newSettings = _currentSettings.copyWith(displayMode: displayMode);
    await saveDisplaySettings(newSettings);
  }

  /// Update UI preferences
  Future<void> updateUIPreferences({
    bool? showFieldLabels,
    bool? compactMode,
    bool? highlightDifferences,
  }) async {
    final newSettings = _currentSettings.copyWith(
      showFieldLabels: showFieldLabels,
      compactMode: compactMode,
      highlightDifferences: highlightDifferences,
    );
    
    await saveDisplaySettings(newSettings);
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await saveDisplaySettings(CardDisplaySettings.defaultSettings);
    AppLogger.info('Card display settings reset to defaults');
  }

  /// Check if settings are valid
  bool validateSettings(CardDisplaySettings settings) {
    // Ensure at least one front field is enabled
    if (!settings.hasFrontFields) {
      AppLogger.error('No front fields enabled');
      return false;
    }
    
    // Ensure at least one back field is enabled
    if (!settings.hasBackFields) {
      AppLogger.error('No back fields enabled');
      return false;
    }
    
    return true;
  }

  /// Get settings summary for display
  String getSettingsSummary(CardDisplaySettings settings) {
    final frontFields = settings.enabledFrontFields.join(', ');
    final backFields = settings.enabledBackFields.join(', ');
    return 'Front: $frontFields | Back: $backFields | Mode: ${settings.displayModeName}';
  }

  /// Export settings as JSON string
  Future<String> exportSettings() async {
    final settings = await getDisplaySettings();
    return jsonEncode(settings.toJson());
  }

  /// Import settings from JSON string
  Future<void> importSettings(String jsonString) async {
    try {
      final settingsMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = CardDisplaySettings.fromJson(settingsMap);
      
      if (validateSettings(settings)) {
        await saveDisplaySettings(settings);
        AppLogger.info('Settings imported successfully');
      } else {
        throw Exception('Invalid settings format');
      }
    } catch (e) {
      AppLogger.error('Error importing settings', e);
      rethrow;
    }
  }

  /// Get recommended settings for different study goals
  static CardDisplaySettings getRecommendedSettings(String studyGoal) {
    switch (studyGoal.toLowerCase()) {
      case 'beginner':
        return CardDisplaySettings(
          showKana: true,
          showHiragana: true,
          showEnglish: true,
          showNotes: true,
          displayMode: CardDisplayMode.recognition,
          showFieldLabels: true,
        );
      case 'intermediate':
        return CardDisplaySettings(
          showKana: true,
          showKanji: true,
          showEnglish: true,
          showNotes: true,
          showContext: true,
          displayMode: CardDisplayMode.mixed,
          showFieldLabels: false,
        );
      case 'advanced':
        return CardDisplaySettings(
          showKanji: true,
          showEnglish: true,
          showNotes: true,
          showContext: true,
          displayMode: CardDisplayMode.production,
          compactMode: true,
          highlightDifferences: true,
        );
      case 'kanji_focus':
        return CardDisplaySettings(
          showKanji: true,
          showEnglish: true,
          showNotes: true,
          showPronunciation: true,
          displayMode: CardDisplayMode.recognition,
          showFieldLabels: true,
        );
      case 'conversation':
        return CardDisplaySettings(
          showKana: true,
          showEnglish: true,
          showContext: true,
          displayMode: CardDisplayMode.production,
          compactMode: true,
        );
      default:
        return CardDisplaySettings.defaultSettings;
    }
  }

  /// Apply recommended settings for a study goal
  Future<void> applyRecommendedSettings(String studyGoal) async {
    final recommended = getRecommendedSettings(studyGoal);
    await saveDisplaySettings(recommended);
    AppLogger.info('Applied recommended settings for: $studyGoal');
  }
}
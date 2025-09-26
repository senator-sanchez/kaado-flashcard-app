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
      } else {
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
    } catch (e) {
      AppLogger.error('Error saving card display settings', e);
      rethrow;
    }
  }

  /// Update front card display option
  Future<void> updateFrontCardOption(FrontCardOption frontCardOption) async {
    final newSettings = _currentSettings.copyWith(frontCardOption: frontCardOption);
    await saveDisplaySettings(newSettings);
  }

  /// Update back card display options
  Future<void> updateBackCardOptions(Set<BackCardOption> backCardOptions) async {
    final newSettings = _currentSettings.copyWith(backCardOptions: backCardOptions);
    await saveDisplaySettings(newSettings);
  }

  /// Update study mode
  Future<void> updateStudyMode(CardDisplayMode displayMode) async {
    final newSettings = _currentSettings.copyWith(displayMode: displayMode);
    await saveDisplaySettings(newSettings);
  }


  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await saveDisplaySettings(CardDisplaySettings.defaultSettings);
  }

  /// Check if settings are valid
  bool validateSettings(CardDisplaySettings settings) {
    // Ensure front and back options are different (prevent duplication)
    if (!settings.hasValidConfiguration) {
      AppLogger.error('Front and back card options cannot be the same');
      return false;
    }
    
    return true;
  }

  /// Get settings summary for display
  String getSettingsSummary(CardDisplaySettings settings) {
    return 'Front: ${settings.frontCardOptionName} | Back: ${settings.backCardOptionsNames} | Mode: ${settings.displayModeName}';
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
          frontCardOption: FrontCardOption.kana,
          backCardOptions: {BackCardOption.english},
          displayMode: CardDisplayMode.recognition,
        );
      case 'intermediate':
        return CardDisplaySettings(
          frontCardOption: FrontCardOption.kanji,
          backCardOptions: {BackCardOption.english},
          displayMode: CardDisplayMode.mixed,
        );
      case 'advanced':
        return CardDisplaySettings(
          frontCardOption: FrontCardOption.kanji,
          backCardOptions: {BackCardOption.english},
          displayMode: CardDisplayMode.production,
        );
      case 'kanji_focus':
        return CardDisplaySettings(
          frontCardOption: FrontCardOption.kanji,
          backCardOptions: {BackCardOption.english},
          displayMode: CardDisplayMode.recognition,
        );
      case 'conversation':
        return CardDisplaySettings(
          frontCardOption: FrontCardOption.kana,
          backCardOptions: {BackCardOption.english},
          displayMode: CardDisplayMode.production,
        );
      default:
        return CardDisplaySettings.defaultSettings;
    }
  }

  /// Apply recommended settings for a study goal
  Future<void> applyRecommendedSettings(String studyGoal) async {
    final recommended = getRecommendedSettings(studyGoal);
    await saveDisplaySettings(recommended);
  }
}
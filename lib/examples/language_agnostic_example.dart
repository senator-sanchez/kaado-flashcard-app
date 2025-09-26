import '../models/language_agnostic_display_settings.dart';
import '../models/language_field_option.dart';
import '../models/card_display_settings.dart';

/// Example of how to use the language-agnostic display settings
/// This shows how the system can work with different languages
class LanguageAgnosticExample {
  
  /// Example: Japanese learning settings
  static LanguageAgnosticDisplaySettings createJapaneseSettings() {
    return LanguageAgnosticDisplaySettings(
      frontField: LanguageFieldOptions.kana,
      backFields: {LanguageFieldOptions.english, LanguageFieldOptions.hiragana},
      displayMode: CardDisplayMode.recognition,
      targetLanguage: 'japanese',
      userLanguage: 'english',
    );
  }

  /// Example: Spanish learning settings
  static LanguageAgnosticDisplaySettings createSpanishSettings() {
    return LanguageAgnosticDisplaySettings(
      frontField: LanguageFieldOptions.spanish,
      backFields: {LanguageFieldOptions.english},
      displayMode: CardDisplayMode.recognition,
      targetLanguage: 'spanish',
      userLanguage: 'english',
    );
  }

  /// Example: French learning settings
  static LanguageAgnosticDisplaySettings createFrenchSettings() {
    return LanguageAgnosticDisplaySettings(
      frontField: LanguageFieldOptions.french,
      backFields: {LanguageFieldOptions.english},
      displayMode: CardDisplayMode.mixed,
      targetLanguage: 'french',
      userLanguage: 'english',
    );
  }

  /// Example: German learning settings
  static LanguageAgnosticDisplaySettings createGermanSettings() {
    return LanguageAgnosticDisplaySettings(
      frontField: LanguageFieldOptions.german,
      backFields: {LanguageFieldOptions.english},
      displayMode: CardDisplayMode.production,
      targetLanguage: 'german',
      userLanguage: 'english',
    );
  }

  /// Example: Mixed mode settings (random front/back)
  static LanguageAgnosticDisplaySettings createMixedModeSettings(String targetLanguage) {
    return LanguageAgnosticDisplaySettings(
      frontField: LanguageFieldOptions.getPrimaryField(targetLanguage),
      backFields: {LanguageFieldOptions.getTranslationField()},
      displayMode: CardDisplayMode.mixed,
      targetLanguage: targetLanguage,
      userLanguage: 'english',
    );
  }

  /// Example: Custom field configuration
  static LanguageAgnosticDisplaySettings createCustomSettings() {
    return LanguageAgnosticDisplaySettings(
      frontField: LanguageFieldOptions.kana,
      backFields: {
        LanguageFieldOptions.english,
        LanguageFieldOptions.hiragana,
        LanguageFieldOptions.romaji,
      },
      displayMode: CardDisplayMode.recognition,
      targetLanguage: 'japanese',
      userLanguage: 'english',
    );
  }

  /// Example: Get available fields for a language
  static List<LanguageFieldOption> getAvailableFields(String language) {
    return LanguageFieldOptions.getFieldsForLanguage(language);
  }

  /// Example: Validate settings
  static bool validateSettings(LanguageAgnosticDisplaySettings settings) {
    return settings.hasValidConfiguration;
  }

  /// Example: Convert to JSON for storage
  static Map<String, dynamic> settingsToJson(LanguageAgnosticDisplaySettings settings) {
    return settings.toJson();
  }

  /// Example: Load from JSON
  static LanguageAgnosticDisplaySettings settingsFromJson(Map<String, dynamic> json) {
    return LanguageAgnosticDisplaySettings.fromJson(json);
  }
}

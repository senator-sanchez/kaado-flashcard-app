import 'language_field_option.dart';
import 'card_display_settings.dart';

/// Language-agnostic card display settings
/// This replaces the hardcoded Japanese/English specific settings
class LanguageAgnosticDisplaySettings {
  // Front card display - single selection
  final LanguageFieldOption frontField;
  
  // Back card display - multiple selection
  final Set<LanguageFieldOption> backFields;
  
  // Study mode settings
  final CardDisplayMode displayMode;
  
  // Language context
  final String targetLanguage; // e.g., 'japanese', 'spanish', 'french'
  final String userLanguage; // e.g., 'english' (user's native language)

  const LanguageAgnosticDisplaySettings({
    required this.frontField,
    required this.backFields,
    required this.displayMode,
    required this.targetLanguage,
    required this.userLanguage,
  });

  /// Default settings for Japanese learning
  static LanguageAgnosticDisplaySettings defaultJapaneseSettings = LanguageAgnosticDisplaySettings(
    frontField: LanguageFieldOptions.kana,
    backFields: {LanguageFieldOptions.english},
    displayMode: CardDisplayMode.recognition,
    targetLanguage: 'japanese',
    userLanguage: 'english',
  );

  /// Default settings for Spanish learning
  static LanguageAgnosticDisplaySettings defaultSpanishSettings = LanguageAgnosticDisplaySettings(
    frontField: LanguageFieldOptions.spanish,
    backFields: {LanguageFieldOptions.english},
    displayMode: CardDisplayMode.recognition,
    targetLanguage: 'spanish',
    userLanguage: 'english',
  );

  /// Get default settings for a specific language
  static LanguageAgnosticDisplaySettings getDefaultForLanguage(String targetLanguage) {
    switch (targetLanguage.toLowerCase()) {
      case 'japanese':
        return defaultJapaneseSettings;
      case 'spanish':
        return defaultSpanishSettings;
      default:
        return defaultJapaneseSettings; // Fallback to Japanese
    }
  }

  /// Create a copy with updated values
  LanguageAgnosticDisplaySettings copyWith({
    LanguageFieldOption? frontField,
    Set<LanguageFieldOption>? backFields,
    CardDisplayMode? displayMode,
    String? targetLanguage,
    String? userLanguage,
  }) {
    return LanguageAgnosticDisplaySettings(
      frontField: frontField ?? this.frontField,
      backFields: backFields ?? this.backFields,
      displayMode: displayMode ?? this.displayMode,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      userLanguage: userLanguage ?? this.userLanguage,
    );
  }

  /// Get display mode name
  String get displayModeName {
    switch (displayMode) {
      case CardDisplayMode.recognition:
        return 'Recognition Mode';
      case CardDisplayMode.production:
        return 'Production Mode';
      case CardDisplayMode.mixed:
        return 'Mixed Mode';
    }
  }

  /// Get display mode description
  String get displayModeDescription {
    switch (displayMode) {
      case CardDisplayMode.recognition:
        return 'See $targetLanguage, guess $userLanguage';
      case CardDisplayMode.production:
        return 'See $userLanguage, produce $targetLanguage';
      case CardDisplayMode.mixed:
        return 'Random front/back combinations';
    }
  }

  /// Get front field name
  String get frontFieldName => frontField.displayName;

  /// Get back fields names as comma-separated string
  String get backFieldsNames {
    if (backFields.isEmpty) return 'None';
    return backFields.map((field) => field.displayName).join(', ');
  }

  /// Check if front and back fields are different (prevent duplication)
  bool get hasValidConfiguration {
    return !backFields.contains(frontField);
  }

  /// Get field value from flashcard data
  String getFieldValue(dynamic flashcard, LanguageFieldOption field) {
    // This would need to be implemented based on how flashcard data is structured
    // For now, return a placeholder
    return '';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageAgnosticDisplaySettings &&
        other.frontField == frontField &&
        other.backFields == backFields &&
        other.displayMode == displayMode &&
        other.targetLanguage == targetLanguage &&
        other.userLanguage == userLanguage;
  }

  @override
  int get hashCode {
    return Object.hash(
      frontField,
      backFields,
      displayMode,
      targetLanguage,
      userLanguage,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'frontField': frontField.fieldType,
      'backFields': backFields.map((e) => e.fieldType).toList(),
      'displayMode': displayMode.name,
      'targetLanguage': targetLanguage,
      'userLanguage': userLanguage,
    };
  }

  /// Create from JSON
  factory LanguageAgnosticDisplaySettings.fromJson(Map<String, dynamic> json) {
    final targetLanguage = json['targetLanguage'] ?? 'japanese';
    final userLanguage = json['userLanguage'] ?? 'english';
    final availableFields = LanguageFieldOptions.getFieldsForLanguage(targetLanguage);
    
    // Find front field
    final frontFieldType = json['frontField'] ?? 'kana';
    final frontField = availableFields.firstWhere(
      (field) => field.fieldType == frontFieldType,
      orElse: () => LanguageFieldOptions.getPrimaryField(targetLanguage),
    );
    
    // Find back fields
    final backFieldTypes = (json['backFields'] as List<dynamic>?)?.cast<String>() ?? ['english'];
    final backFields = backFieldTypes
        .map((type) => availableFields.firstWhere(
              (field) => field.fieldType == type,
              orElse: () => LanguageFieldOptions.getTranslationField(),
            ))
        .toSet();
    
    return LanguageAgnosticDisplaySettings(
      frontField: frontField,
      backFields: backFields,
      displayMode: CardDisplayMode.values.firstWhere(
        (e) => e.name == json['displayMode'],
        orElse: () => CardDisplayMode.recognition,
      ),
      targetLanguage: targetLanguage,
      userLanguage: userLanguage,
    );
  }

  @override
  String toString() {
    return 'LanguageAgnosticDisplaySettings('
        'front: $frontFieldName, '
        'back: $backFieldsNames, '
        'mode: $displayModeName, '
        'target: $targetLanguage, '
        'user: $userLanguage'
        ')';
  }
}

// CardDisplayMode is imported from the existing card_display_settings.dart
// to avoid duplication and import conflicts

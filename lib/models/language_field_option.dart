/// Generic field option for any language
/// This replaces the hardcoded Japanese-specific field options
class LanguageFieldOption {
  final String fieldType; // e.g., 'kana', 'hiragana', 'english', 'spanish', 'french'
  final String displayName; // e.g., 'Kana', 'Hiragana', 'English', 'Spanish', 'French'
  final String description; // e.g., 'Japanese kana characters', 'English translation'
  final bool isPrimary; // Whether this is a primary field for the language
  final bool isTranslation; // Whether this is a translation field (usually user's native language)

  const LanguageFieldOption({
    required this.fieldType,
    required this.displayName,
    required this.description,
    this.isPrimary = false,
    this.isTranslation = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageFieldOption && other.fieldType == fieldType;
  }

  @override
  int get hashCode => fieldType.hashCode;

  @override
  String toString() => 'LanguageFieldOption(fieldType: $fieldType, displayName: $displayName)';
}

/// Predefined field options for common languages
class LanguageFieldOptions {
  // Japanese fields
  static const kana = LanguageFieldOption(
    fieldType: 'kana',
    displayName: 'Kana',
    description: 'Japanese kana characters',
    isPrimary: true,
  );
  
  static const hiragana = LanguageFieldOption(
    fieldType: 'hiragana',
    displayName: 'Hiragana',
    description: 'Hiragana characters',
  );
  
  static const kanji = LanguageFieldOption(
    fieldType: 'kanji',
    displayName: 'Kanji',
    description: 'Kanji characters',
  );
  
  static const romaji = LanguageFieldOption(
    fieldType: 'romaji',
    displayName: 'Romaji',
    description: 'Romanized text',
  );

  // Translation fields (user's native language)
  static const english = LanguageFieldOption(
    fieldType: 'english',
    displayName: 'English',
    description: 'English translation',
    isTranslation: true,
  );

  // Spanish fields
  static const spanish = LanguageFieldOption(
    fieldType: 'spanish',
    displayName: 'Spanish',
    description: 'Spanish text',
    isPrimary: true,
  );

  // French fields
  static const french = LanguageFieldOption(
    fieldType: 'french',
    displayName: 'French',
    description: 'French text',
    isPrimary: true,
  );

  // German fields
  static const german = LanguageFieldOption(
    fieldType: 'german',
    displayName: 'German',
    description: 'German text',
    isPrimary: true,
  );

  // Get all available field options for a specific language
  static List<LanguageFieldOption> getFieldsForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'japanese':
        return [kana, hiragana, kanji, romaji, english];
      case 'spanish':
        return [spanish, english];
      case 'french':
        return [french, english];
      case 'german':
        return [german, english];
      default:
        return [english]; // Fallback to English only
    }
  }

  // Get primary field for a language
  static LanguageFieldOption getPrimaryField(String language) {
    switch (language.toLowerCase()) {
      case 'japanese':
        return kana;
      case 'spanish':
        return spanish;
      case 'french':
        return french;
      case 'german':
        return german;
      default:
        return english;
    }
  }

  // Get translation field (user's native language)
  static LanguageFieldOption getTranslationField() {
    return english; // For now, assume English is the user's native language
  }
}

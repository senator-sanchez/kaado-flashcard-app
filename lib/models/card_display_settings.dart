/// Card display mode enumeration
enum CardDisplayMode {
  recognition, // See Japanese, guess English
  production,  // See English, produce Japanese
  mixed,       // Random front/back combinations
}

/// Card display settings model
/// 
/// Comprehensive settings for customizing card display behavior.
/// This is critical for language learning flexibility and different study modes.
class CardDisplaySettings {
  // Front card display options
  final bool showKana;
  final bool showHiragana;
  final bool showKanji;
  final bool showRomaji;
  
  // Back card display options
  final bool showEnglish;
  final bool showNotes;
  final bool showPronunciation;
  final bool showContext;
  
  // Study mode settings
  final CardDisplayMode displayMode;
  
  // UI preferences
  final bool showFieldLabels;
  final bool compactMode;
  final bool highlightDifferences;

  const CardDisplaySettings({
    // Front card options
    this.showKana = true,
    this.showHiragana = false,
    this.showKanji = false,
    this.showRomaji = false,
    
    // Back card options
    this.showEnglish = true,
    this.showNotes = true,
    this.showPronunciation = false,
    this.showContext = false,
    
    // Study mode
    this.displayMode = CardDisplayMode.recognition,
    
    // UI preferences
    this.showFieldLabels = true,
    this.compactMode = false,
    this.highlightDifferences = false,
  });

  /// Default card display settings for new users
  static const CardDisplaySettings defaultSettings = CardDisplaySettings(
    showKana: true,
    showEnglish: true,
    showNotes: true,
    displayMode: CardDisplayMode.recognition,
    showFieldLabels: true,
  );

  /// Create a copy with updated values
  CardDisplaySettings copyWith({
    // Front card options
    bool? showKana,
    bool? showHiragana,
    bool? showKanji,
    bool? showRomaji,
    
    // Back card options
    bool? showEnglish,
    bool? showNotes,
    bool? showPronunciation,
    bool? showContext,
    
    // Study mode
    CardDisplayMode? displayMode,
    
    // UI preferences
    bool? showFieldLabels,
    bool? compactMode,
    bool? highlightDifferences,
  }) {
    return CardDisplaySettings(
      showKana: showKana ?? this.showKana,
      showHiragana: showHiragana ?? this.showHiragana,
      showKanji: showKanji ?? this.showKanji,
      showRomaji: showRomaji ?? this.showRomaji,
      showEnglish: showEnglish ?? this.showEnglish,
      showNotes: showNotes ?? this.showNotes,
      showPronunciation: showPronunciation ?? this.showPronunciation,
      showContext: showContext ?? this.showContext,
      displayMode: displayMode ?? this.displayMode,
      showFieldLabels: showFieldLabels ?? this.showFieldLabels,
      compactMode: compactMode ?? this.compactMode,
      highlightDifferences: highlightDifferences ?? this.highlightDifferences,
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
        return 'See Japanese, guess English';
      case CardDisplayMode.production:
        return 'See English, produce Japanese';
      case CardDisplayMode.mixed:
        return 'Random front/back combinations';
    }
  }

  /// Check if any front field is enabled
  bool get hasFrontFields {
    return showKana || showHiragana || showKanji || showRomaji;
  }

  /// Check if any back field is enabled
  bool get hasBackFields {
    return showEnglish || showNotes || showPronunciation || showContext;
  }

  /// Get list of enabled front fields
  List<String> get enabledFrontFields {
    final fields = <String>[];
    if (showKana) fields.add('Kana');
    if (showHiragana) fields.add('Hiragana');
    if (showKanji) fields.add('Kanji');
    if (showRomaji) fields.add('Romaji');
    return fields;
  }

  /// Get list of enabled back fields
  List<String> get enabledBackFields {
    final fields = <String>[];
    if (showEnglish) fields.add('English');
    if (showNotes) fields.add('Notes');
    if (showPronunciation) fields.add('Pronunciation');
    if (showContext) fields.add('Context');
    return fields;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardDisplaySettings &&
        other.showKana == showKana &&
        other.showHiragana == showHiragana &&
        other.showKanji == showKanji &&
        other.showRomaji == showRomaji &&
        other.showEnglish == showEnglish &&
        other.showNotes == showNotes &&
        other.showPronunciation == showPronunciation &&
        other.showContext == showContext &&
        other.displayMode == displayMode &&
        other.showFieldLabels == showFieldLabels &&
        other.compactMode == compactMode &&
        other.highlightDifferences == highlightDifferences;
  }

  @override
  int get hashCode {
    return Object.hash(
      showKana,
      showHiragana,
      showKanji,
      showRomaji,
      showEnglish,
      showNotes,
      showPronunciation,
      showContext,
      displayMode,
      showFieldLabels,
      compactMode,
      highlightDifferences,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'showKana': showKana,
      'showHiragana': showHiragana,
      'showKanji': showKanji,
      'showRomaji': showRomaji,
      'showEnglish': showEnglish,
      'showNotes': showNotes,
      'showPronunciation': showPronunciation,
      'showContext': showContext,
      'displayMode': displayMode.name,
      'showFieldLabels': showFieldLabels,
      'compactMode': compactMode,
      'highlightDifferences': highlightDifferences,
    };
  }

  /// Create from JSON
  factory CardDisplaySettings.fromJson(Map<String, dynamic> json) {
    return CardDisplaySettings(
      showKana: json['showKana'] ?? true,
      showHiragana: json['showHiragana'] ?? false,
      showKanji: json['showKanji'] ?? false,
      showRomaji: json['showRomaji'] ?? false,
      showEnglish: json['showEnglish'] ?? true,
      showNotes: json['showNotes'] ?? true,
      showPronunciation: json['showPronunciation'] ?? false,
      showContext: json['showContext'] ?? false,
      displayMode: CardDisplayMode.values.firstWhere(
        (e) => e.name == json['displayMode'],
        orElse: () => CardDisplayMode.recognition,
      ),
      showFieldLabels: json['showFieldLabels'] ?? true,
      compactMode: json['compactMode'] ?? false,
      highlightDifferences: json['highlightDifferences'] ?? false,
    );
  }

  @override
  String toString() {
    return 'CardDisplaySettings('
        'front: ${enabledFrontFields.join(', ')}, '
        'back: ${enabledBackFields.join(', ')}, '
        'mode: $displayModeName'
        ')';
  }
}
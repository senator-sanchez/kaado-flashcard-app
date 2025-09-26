/// Card display mode enumeration
enum CardDisplayMode {
  recognition, // See Japanese, guess English
  production,  // See English, produce Japanese
  mixed,       // Random front/back combinations
}

/// Front card display options
enum FrontCardOption {
  kana,
  hiragana,
  kanji,
  romaji,
  english,
}

/// Back card display options
enum BackCardOption {
  kana,
  hiragana,
  kanji,
  romaji,
  english,
}

/// Card display settings model
/// 
/// Comprehensive settings for customizing card display behavior.
/// This is critical for language learning flexibility and different study modes.
class CardDisplaySettings {
  // Front card display - single selection
  final FrontCardOption frontCardOption;
  
  // Back card display - multiple selection
  final Set<BackCardOption> backCardOptions;
  
  // Study mode settings
  final CardDisplayMode displayMode;

  const CardDisplaySettings({
    this.frontCardOption = FrontCardOption.kana,
    this.backCardOptions = const {BackCardOption.english},
    this.displayMode = CardDisplayMode.recognition,
  });

  /// Default card display settings for new users
  static const CardDisplaySettings defaultSettings = CardDisplaySettings(
    frontCardOption: FrontCardOption.kana,
    backCardOptions: {BackCardOption.english},
    displayMode: CardDisplayMode.recognition,
  );

  /// Create a copy with updated values
  CardDisplaySettings copyWith({
    FrontCardOption? frontCardOption,
    Set<BackCardOption>? backCardOptions,
    CardDisplayMode? displayMode,
  }) {
    return CardDisplaySettings(
      frontCardOption: frontCardOption ?? this.frontCardOption,
      backCardOptions: backCardOptions ?? this.backCardOptions,
      displayMode: displayMode ?? this.displayMode,
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

  /// Get front card option name
  String get frontCardOptionName {
    switch (frontCardOption) {
      case FrontCardOption.kana:
        return 'Kana';
      case FrontCardOption.hiragana:
        return 'Hiragana';
      case FrontCardOption.kanji:
        return 'Kanji';
      case FrontCardOption.romaji:
        return 'Romaji';
      case FrontCardOption.english:
        return 'English';
    }
  }

  /// Get back card options names as comma-separated string
  String get backCardOptionsNames {
    if (backCardOptions.isEmpty) return 'None';
    return backCardOptions.map((option) {
      switch (option) {
        case BackCardOption.kana:
          return 'Kana';
        case BackCardOption.hiragana:
          return 'Hiragana';
        case BackCardOption.kanji:
          return 'Kanji';
        case BackCardOption.romaji:
          return 'Romaji';
        case BackCardOption.english:
          return 'English';
      }
    }).join(', ');
  }

  /// Check if front and back options are different (prevent duplication)
  bool get hasValidConfiguration {
    return !backCardOptions.contains(FrontCardOption.values.firstWhere(
      (front) => front.name == frontCardOption.name,
      orElse: () => FrontCardOption.kana,
    ));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardDisplaySettings &&
        other.frontCardOption == frontCardOption &&
        other.backCardOptions == backCardOptions &&
        other.displayMode == displayMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      frontCardOption,
      backCardOptions,
      displayMode,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'frontCardOption': frontCardOption.name,
      'backCardOptions': backCardOptions.map((e) => e.name).toList(),
      'displayMode': displayMode.name,
    };
  }

  /// Create from JSON
  factory CardDisplaySettings.fromJson(Map<String, dynamic> json) {
    return CardDisplaySettings(
      frontCardOption: FrontCardOption.values.firstWhere(
        (e) => e.name == json['frontCardOption'],
        orElse: () => FrontCardOption.kana,
      ),
      backCardOptions: (json['backCardOptions'] as List<dynamic>?)
          ?.map((e) => BackCardOption.values.firstWhere(
                (option) => option.name == e,
                orElse: () => BackCardOption.english,
              ))
          .toSet() ?? {BackCardOption.english},
      displayMode: CardDisplayMode.values.firstWhere(
        (e) => e.name == json['displayMode'],
        orElse: () => CardDisplayMode.recognition,
      ),
    );
  }

  @override
  String toString() {
    return 'CardDisplaySettings('
        'front: $frontCardOptionName, '
        'back: $backCardOptionsNames, '
        'mode: $displayModeName'
        ')';
  }
}
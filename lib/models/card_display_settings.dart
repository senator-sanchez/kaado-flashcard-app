/// Card display type enumeration
enum CardDisplayType {
  kana,
  hiragana,
  english,
  romaji;
  
  String get displayName {
    switch (this) {
      case CardDisplayType.kana:
        return 'Kana (Japanese characters)';
      case CardDisplayType.hiragana:
        return 'Hiragana';
      case CardDisplayType.english:
        return 'English';
      case CardDisplayType.romaji:
        return 'Romaji (Romanized)';
    }
  }
  
  String get description {
    switch (this) {
      case CardDisplayType.kana:
        return 'Japanese characters';
      case CardDisplayType.hiragana:
        return 'Hiragana script';
      case CardDisplayType.english:
        return 'English translation';
      case CardDisplayType.romaji:
        return 'Romanized pronunciation';
    }
  }
}

/// Card display settings model
class CardDisplaySettings {
  final CardDisplayType frontDisplay;
  final List<CardDisplayType> backDisplays;

  const CardDisplaySettings({
    required this.frontDisplay,
    required this.backDisplays,
  });

  /// Default card display settings
  static const CardDisplaySettings defaultSettings = CardDisplaySettings(
    frontDisplay: CardDisplayType.kana,
    backDisplays: [CardDisplayType.english, CardDisplayType.hiragana],
  );

  /// Create a copy with updated values
  CardDisplaySettings copyWith({
    CardDisplayType? frontDisplay,
    List<CardDisplayType>? backDisplays,
  }) {
    return CardDisplaySettings(
      frontDisplay: frontDisplay ?? this.frontDisplay,
      backDisplays: backDisplays ?? this.backDisplays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardDisplaySettings &&
        other.frontDisplay == frontDisplay &&
        _listEquals(other.backDisplays, backDisplays);
  }

  @override
  int get hashCode => frontDisplay.hashCode ^ backDisplays.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'frontDisplay': frontDisplay.name,
      'backDisplays': backDisplays.map((e) => e.name).toList(),
    };
  }

  /// Create from JSON
  factory CardDisplaySettings.fromJson(Map<String, dynamic> json) {
    return CardDisplaySettings(
      frontDisplay: CardDisplayType.values.firstWhere(
        (e) => e.name == json['frontDisplay'],
        orElse: () => CardDisplayType.kana,
      ),
      backDisplays: (json['backDisplays'] as List<dynamic>?)
          ?.map((e) => CardDisplayType.values.firstWhere(
                (type) => type.name == e,
                orElse: () => CardDisplayType.english,
              ))
          .toList() ??
          [CardDisplayType.english, CardDisplayType.hiragana],
    );
  }
}
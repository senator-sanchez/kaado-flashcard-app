/// Represents a Japanese language flashcard with kana, reading, and English translation
class Flashcard {
  final int id;
  final String kana; // Japanese text (kanji, hiragana, katakana, or mixed)
  final String? hiragana; // Hiragana reading/pronunciation guide
  final String english; // English translation
  final String? romaji; // Romaji reading (optional)
  final String? scriptType; // Type of Japanese script
  final String? notes; // Free text notes for the card
  final int categoryId; // Category this card belongs to
  final String? categoryName; // Name of the category (computed field)

  Flashcard({
    required this.id,
    required this.kana,
    this.hiragana,
    required this.english,
    this.romaji,
    this.scriptType,
    this.notes,
    required this.categoryId,
    this.categoryName,
  });

  /// Create a Flashcard from a database map
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? map['card_id'] ?? 0,
      kana: map['kana'] ?? '',
      hiragana: map['hiragana'],
      english: map['english'] ?? '',
      romaji: map['romaji'],
      scriptType: map['script_type'],
      notes: map['notes'],
      categoryId: map['category_id'] ?? 0,
      categoryName: map['category_name'],
    );
  }

  /// Convert Flashcard to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kana': kana,
      'hiragana': hiragana,
      'english': english,
      'romaji': romaji,
      'script_type': scriptType,
      'notes': notes,
      'category_id': categoryId,
      // Note: category_name is a computed field, not a database column
    };
  }

  /// Get the primary display text (kana)
  String get displayText => kana;
  
  /// Get the reading guide (hiragana if available)
  String get reading => hiragana ?? '';

  @override
  String toString() {
    return 'Flashcard(id: $id, kana: $kana, english: $english, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Flashcard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

import 'card.dart';
import 'card_field.dart';

/// Legacy Flashcard model for backward compatibility
/// This wraps the new Card + CardField structure to maintain existing API
class Flashcard {
  final int id;
  final String kana; // Japanese text (kanji, hiragana, katakana, or mixed)
  final String? hiragana; // Hiragana reading/pronunciation guide
  final String english; // English translation
  final String? romaji; // Romaji reading (optional)
  final String? scriptType; // Type of Japanese script (legacy field)
  final String? notes; // Free text notes for the card
  final bool isFavorite; // Whether this card is marked as favorite
  final int categoryId; // Category/Deck this card belongs to
  final String? categoryName; // Name of the category/deck (computed field)
  
  // New fields for compatibility with new schema
  final Card? _card; // Internal Card object
  final List<CardField>? _fields; // Internal CardField list

  Flashcard({
    required this.id,
    required this.kana,
    this.hiragana,
    required this.english,
    this.romaji,
    this.scriptType,
    this.notes,
    this.isFavorite = false,
    required this.categoryId,
    this.categoryName,
    Card? card,
    List<CardField>? fields,
  }) : _card = card, _fields = fields;

  /// Create a Flashcard from a database map (legacy format)
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? map['card_id'] ?? 0,
      kana: map['kana'] ?? '',
      hiragana: map['hiragana'],
      english: map['english'] ?? '',
      romaji: map['romaji'],
      scriptType: map['script_type'],
      notes: map['notes'],
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      categoryId: map['category_id'] ?? map['deck_id'] ?? 0,
      categoryName: map['category_name'] ?? map['deck_name'],
    );
  }

  /// Create a Flashcard from new Card + CardField structure
  factory Flashcard.fromCard(Card card) {
    return Flashcard(
      id: card.id,
      kana: card.getFieldValue('kana') ?? '',
      hiragana: card.getFieldValue('hiragana'),
      english: card.getFieldValue('english') ?? '',
      romaji: card.getFieldValue('romaji'),
      scriptType: null, // Legacy field, not used in new schema
      notes: card.notes,
      isFavorite: card.isFavorite,
      categoryId: card.deckId,
      categoryName: card.deckName,
      card: card,
      fields: card.fields,
    );
  }

  /// Convert Flashcard to a database map (legacy format)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kana': kana,
      'hiragana': hiragana,
      'english': english,
      'romaji': romaji,
      'script_type': scriptType,
      'notes': notes,
      'is_favorite': isFavorite ? 1 : 0,
      'category_id': categoryId,
      'deck_id': categoryId, // Support both old and new column names
      // Note: category_name/deck_name is a computed field, not a database column
    };
  }

  /// Get the underlying Card object (if available)
  Card? get card => _card;

  /// Get the underlying CardField list (if available)
  List<CardField>? get fields => _fields;
  
  /// Create a copy of this Flashcard with updated values
  Flashcard copyWith({
    int? id,
    String? kana,
    String? hiragana,
    String? english,
    String? romaji,
    String? scriptType,
    String? notes,
    bool? isFavorite,
    int? categoryId,
    String? categoryName,
    Card? card,
    List<CardField>? fields,
  }) {
    return Flashcard(
      id: id ?? this.id,
      kana: kana ?? this.kana,
      hiragana: hiragana ?? this.hiragana,
      english: english ?? this.english,
      romaji: romaji ?? this.romaji,
      scriptType: scriptType ?? this.scriptType,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      card: card ?? this._card,
      fields: fields ?? this._fields,
    );
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

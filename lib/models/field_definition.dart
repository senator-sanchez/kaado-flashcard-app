/// Represents a field definition that defines what fields are available for cards in a deck
/// For example: 'kana', 'hiragana', 'english', 'romaji' for Japanese cards
class FieldDefinition {
  final int id;
  final int deckId;
  final String fieldType; // e.g., 'kana', 'hiragana', 'english', 'romaji'
  final bool isFront; // Whether this field is shown on the front of the card
  final bool isBack; // Whether this field is shown on the back of the card
  final int sortOrder;
  final bool isDirty;
  final int? updatedAt;

  FieldDefinition({
    required this.id,
    required this.deckId,
    required this.fieldType,
    this.isFront = false,
    this.isBack = false,
    this.sortOrder = 0,
    this.isDirty = false,
    this.updatedAt,
  });

  /// Create a FieldDefinition from a database map
  factory FieldDefinition.fromMap(Map<String, dynamic> map) {
    return FieldDefinition(
      id: map['id'] ?? 0,
      deckId: map['deck_id'] ?? 0,
      fieldType: map['field_type'] ?? '',
      isFront: (map['is_front'] ?? 0) == 1,
      isBack: (map['is_back'] ?? 0) == 1,
      sortOrder: map['sort_order'] ?? 0,
      isDirty: (map['is_dirty'] ?? 0) == 1,
      updatedAt: map['updated_at'],
    );
  }

  /// Convert FieldDefinition to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'field_type': fieldType,
      'is_front': isFront ? 1 : 0,
      'is_back': isBack ? 1 : 0,
      'sort_order': sortOrder,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  /// Create a copy with updated values
  FieldDefinition copyWith({
    int? id,
    int? deckId,
    String? fieldType,
    bool? isFront,
    bool? isBack,
    int? sortOrder,
    bool? isDirty,
    int? updatedAt,
  }) {
    return FieldDefinition(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      fieldType: fieldType ?? this.fieldType,
      isFront: isFront ?? this.isFront,
      isBack: isBack ?? this.isBack,
      sortOrder: sortOrder ?? this.sortOrder,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FieldDefinition(id: $id, deckId: $deckId, fieldType: $fieldType, isFront: $isFront, isBack: $isBack)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldDefinition &&
        other.id == id &&
        other.deckId == deckId &&
        other.fieldType == fieldType;
  }

  @override
  int get hashCode => id.hashCode ^ deckId.hashCode ^ fieldType.hashCode;
}

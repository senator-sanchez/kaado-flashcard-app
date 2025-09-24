/// Represents a single field value for a card
/// Links a card to its field values through the field definition
class CardField {
  final int id;
  final int cardId;
  final int fieldDefinitionId;
  final String fieldValue;
  final bool isDirty;
  final int? updatedAt;

  // Computed fields (not stored in database)
  final String? fieldType; // From FieldDefinition
  final bool? isFront; // From FieldDefinition
  final bool? isBack; // From FieldDefinition

  CardField({
    required this.id,
    required this.cardId,
    required this.fieldDefinitionId,
    required this.fieldValue,
    this.isDirty = false,
    this.updatedAt,
    this.fieldType,
    this.isFront,
    this.isBack,
  });

  /// Create a CardField from a database map
  factory CardField.fromMap(Map<String, dynamic> map) {
    return CardField(
      id: map['id'] ?? 0,
      cardId: map['card_id'] ?? 0,
      fieldDefinitionId: map['field_definition_id'] ?? 0,
      fieldValue: map['field_value'] ?? '',
      isDirty: (map['is_dirty'] ?? 0) == 1,
      updatedAt: map['updated_at'],
      fieldType: map['field_type'], // From JOIN with FieldDefinition
      isFront: map['is_front'] != null ? (map['is_front'] == 1) : null,
      isBack: map['is_back'] != null ? (map['is_back'] == 1) : null,
    );
  }

  /// Convert CardField to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'field_definition_id': fieldDefinitionId,
      'field_value': fieldValue,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  /// Create a copy with updated values
  CardField copyWith({
    int? id,
    int? cardId,
    int? fieldDefinitionId,
    String? fieldValue,
    bool? isDirty,
    int? updatedAt,
    String? fieldType,
    bool? isFront,
    bool? isBack,
  }) {
    return CardField(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      fieldDefinitionId: fieldDefinitionId ?? this.fieldDefinitionId,
      fieldValue: fieldValue ?? this.fieldValue,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
      fieldType: fieldType ?? this.fieldType,
      isFront: isFront ?? this.isFront,
      isBack: isBack ?? this.isBack,
    );
  }

  @override
  String toString() {
    return 'CardField(id: $id, cardId: $cardId, fieldType: $fieldType, fieldValue: $fieldValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardField &&
        other.id == id &&
        other.cardId == cardId &&
        other.fieldDefinitionId == fieldDefinitionId;
  }

  @override
  int get hashCode => id.hashCode ^ cardId.hashCode ^ fieldDefinitionId.hashCode;
}

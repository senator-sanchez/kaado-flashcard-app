import 'card_field.dart';

/// Represents a flashcard with metadata only
/// Field values are stored separately in CardField table
class Card {
  final int id;
  final int deckId;
  final String? notes;
  final bool isFavorite;
  final bool isDirty;
  final int? updatedAt;

  // Computed fields (not stored in database)
  final String? deckName; // From Deck table
  final List<CardField>? fields; // From CardField table

  Card({
    required this.id,
    required this.deckId,
    this.notes,
    this.isFavorite = false,
    this.isDirty = false,
    this.updatedAt,
    this.deckName,
    this.fields,
  });

  /// Create a Card from a database map
  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'] ?? 0,
      deckId: map['deck_id'] ?? 0,
      notes: map['notes'],
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      isDirty: (map['is_dirty'] ?? 0) == 1,
      updatedAt: map['updated_at'] != null ? int.tryParse(map['updated_at'].toString()) : null,
      deckName: map['deck_name'], // From JOIN with Deck
      fields: map['fields'] != null 
          ? (map['fields'] as List<dynamic>).map((f) => CardField.fromMap(f)).toList()
          : null,
    );
  }

  /// Convert Card to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'notes': notes,
      'is_favorite': isFavorite ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  /// Get field value by field type (e.g., 'kana', 'english')
  String? getFieldValue(String fieldType) {
    if (fields == null) return null;
    
    for (final field in fields!) {
      if (field.fieldType == fieldType) {
        return field.fieldValue;
      }
    }
    return null;
  }

  /// Get all front fields (fields to show on card front)
  List<CardField> getFrontFields() {
    if (fields == null) return [];
    return fields!.where((field) => field.isFront == true).toList();
  }

  /// Get all back fields (fields to show on card back)
  List<CardField> getBackFields() {
    if (fields == null) return [];
    return fields!.where((field) => field.isBack == true).toList();
  }

  /// Get the primary display text (first front field or first field)
  String get displayText {
    final frontFields = getFrontFields();
    if (frontFields.isNotEmpty) {
      return frontFields.first.fieldValue;
    }
    
    if (fields != null && fields!.isNotEmpty) {
      return fields!.first.fieldValue;
    }
    
    return '';
  }

  /// Get the reading guide (hiragana field if available)
  String get reading {
    return getFieldValue('hiragana') ?? '';
  }

  /// Get the English translation
  String get english {
    return getFieldValue('english') ?? '';
  }

  /// Get the kana text
  String get kana {
    return getFieldValue('kana') ?? '';
  }

  /// Get the romaji reading
  String get romaji {
    return getFieldValue('romaji') ?? '';
  }

  /// Create a copy with updated values
  Card copyWith({
    int? id,
    int? deckId,
    String? notes,
    bool? isFavorite,
    bool? isDirty,
    int? updatedAt,
    String? deckName,
    List<CardField>? fields,
  }) {
    return Card(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
      deckName: deckName ?? this.deckName,
      fields: fields ?? this.fields,
    );
  }

  @override
  String toString() {
    return 'Card(id: $id, deckId: $deckId, displayText: $displayText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Card && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

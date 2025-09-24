/// Represents a deck (previously category) in the language learning hierarchy
/// Decks can have parent-child relationships and contain flashcards
class Deck {
  final int id;
  final String name;
  final String? language;
  final int? parentId;
  final int sortOrder;
  final bool isDirty;
  final int? updatedAt;
  
  // Computed fields (not stored in database)
  final bool hasChildren;
  final int cardCount;
  final String? fullPath;
  List<Deck>? children; // Mutable for building hierarchy

  Deck({
    required this.id,
    required this.name,
    this.language,
    this.parentId,
    this.sortOrder = 0,
    this.isDirty = false,
    this.updatedAt,
    this.hasChildren = false,
    this.cardCount = 0,
    this.fullPath,
    this.children,
  });

  /// Create a Deck from a database map
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: (map['id'] ?? 0) is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      name: map['name']?.toString() ?? '',
      language: map['language']?.toString(),
      parentId: map['parent_id'] != null ? (map['parent_id'] is int ? map['parent_id'] : int.tryParse(map['parent_id'].toString())) : null,
      sortOrder: (map['sort_order'] ?? 0) is int ? map['sort_order'] : int.tryParse(map['sort_order'].toString()) ?? 0,
      isDirty: (map['is_dirty'] ?? 0) == 1 || map['is_dirty'] == true,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()).millisecondsSinceEpoch : null,
      hasChildren: (map['has_children'] ?? 0) == 1 || map['has_children'] == true,
      cardCount: (map['card_count'] ?? 0) is int ? map['card_count'] : int.tryParse(map['card_count'].toString()) ?? 0,
      fullPath: map['full_path']?.toString().isEmpty == true ? null : map['full_path']?.toString(),
      children: (map['children'] as List<dynamic>?)?.map((item) => Deck.fromMap(item)).toList(),
    );
  }

  /// Convert Deck to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_dirty': isDirty ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  /// Create a copy with updated values
  Deck copyWith({
    int? id,
    String? name,
    String? language,
    int? parentId,
    int? sortOrder,
    bool? isDirty,
    int? updatedAt,
    bool? hasChildren,
    int? cardCount,
    String? fullPath,
    List<Deck>? children,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isDirty: isDirty ?? this.isDirty,
      updatedAt: updatedAt ?? this.updatedAt,
      hasChildren: hasChildren ?? this.hasChildren,
      cardCount: cardCount ?? this.cardCount,
      fullPath: fullPath ?? this.fullPath,
      children: children ?? this.children,
    );
  }

  @override
  String toString() {
    return 'Deck(id: $id, name: $name, parentId: $parentId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deck && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

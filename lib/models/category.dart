/// Represents a category in the Japanese language learning hierarchy
/// Categories can have parent-child relationships and contain flashcards
class Category {
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final int sortOrder;
  final bool hasChildren;
  final bool isCardCategory;
  final int cardCount;
  final String? fullPath;
  List<Category>? children; // Mutable for building hierarchy

  Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.sortOrder = 0,
    this.hasChildren = false,
    this.isCardCategory = false,
    this.cardCount = 0,
    this.fullPath,
    this.children,
  });

  /// Create a Category from a database map
  /// Handles both direct column names and computed field names
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? map['category_id'] ?? 0,
      name: map['name'] ?? '',
      description: map['description'],
      parentId: map['parent_id'],
      sortOrder: map['sort_order'] ?? 0,
      hasChildren: map['has_children'] == 1,
      isCardCategory: map['is_card_category'] == 1,
      cardCount: map['card_count'] ?? 0,
      fullPath: map['full_path'],
      children: (map['children'] as List<dynamic>?)?.map((item) => Category.fromMap(item)).toList(),
    );
  }

  /// Convert Category to a database map
  /// Note: children is not a database column, it's built in memory
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'has_children': hasChildren ? 1 : 0,
      'is_card_category': isCardCategory ? 1 : 0,
      'card_count': cardCount,
      'full_path': fullPath,
      // Note: children is not a database column, it's built in memory
    };
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, parentId: $parentId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

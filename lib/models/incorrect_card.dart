/// Represents a card that was answered incorrectly and needs review
class IncorrectCard {
  final int cardId;
  final int categoryId;
  final String categoryName;
  final DateTime lastIncorrect;
  final int incorrectCount;
  final bool isReviewed;
  final DateTime? lastReviewed;

  IncorrectCard({
    required this.cardId,
    required this.categoryId,
    required this.categoryName,
    required this.lastIncorrect,
    this.incorrectCount = 1,
    this.isReviewed = false,
    this.lastReviewed,
  });

  /// Create an IncorrectCard from a database map
  factory IncorrectCard.fromMap(Map<String, dynamic> map) {
    return IncorrectCard(
      cardId: map['card_id'] ?? 0,
      categoryId: map['category_id'] ?? 0,
      categoryName: map['category_name'] ?? '',
      lastIncorrect: DateTime.fromMillisecondsSinceEpoch(map['last_incorrect'] ?? 0),
      incorrectCount: map['incorrect_count'] ?? 1,
      isReviewed: map['is_reviewed'] == 1,
      lastReviewed: map['last_reviewed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_reviewed'])
          : null,
    );
  }

  /// Convert IncorrectCard to a database map
  Map<String, dynamic> toMap() {
    return {
      'card_id': cardId,
      'category_id': categoryId,
      'category_name': categoryName,
      'last_incorrect': lastIncorrect.millisecondsSinceEpoch,
      'incorrect_count': incorrectCount,
      'is_reviewed': isReviewed ? 1 : 0,
      'last_reviewed': lastReviewed?.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with updated values
  IncorrectCard copyWith({
    int? cardId,
    int? categoryId,
    String? categoryName,
    DateTime? lastIncorrect,
    int? incorrectCount,
    bool? isReviewed,
    DateTime? lastReviewed,
  }) {
    return IncorrectCard(
      cardId: cardId ?? this.cardId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      lastIncorrect: lastIncorrect ?? this.lastIncorrect,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      isReviewed: isReviewed ?? this.isReviewed,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  @override
  String toString() {
    return 'IncorrectCard(cardId: $cardId, categoryId: $categoryId, incorrectCount: $incorrectCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncorrectCard && other.cardId == cardId;
  }

  @override
  int get hashCode => cardId.hashCode;
}

/// Represents a deck that has incorrect cards available for review
class ReviewDeck {
  final int categoryId;
  final String categoryName;
  final int totalCards;
  final int incorrectCards;
  final int reviewedCards;
  final DateTime? lastReviewed;
  final double reviewProgress; // 0.0 to 1.0

  ReviewDeck({
    required this.categoryId,
    required this.categoryName,
    required this.totalCards,
    required this.incorrectCards,
    required this.reviewedCards,
    this.lastReviewed,
    required this.reviewProgress,
  });

  /// Create a ReviewDeck from a database map
  factory ReviewDeck.fromMap(Map<String, dynamic> map) {
    final incorrectCards = map['incorrect_cards'] ?? 0;
    final reviewedCards = map['reviewed_cards'] ?? 0;
    
    return ReviewDeck(
      categoryId: map['category_id'] ?? 0,
      categoryName: map['category_name'] ?? '',
      totalCards: map['total_cards'] ?? 0,
      incorrectCards: incorrectCards,
      reviewedCards: reviewedCards,
      lastReviewed: map['last_reviewed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_reviewed'])
          : null,
      reviewProgress: incorrectCards > 0 ? reviewedCards / incorrectCards : 0.0,
    );
  }

  /// Check if this deck has any incorrect cards to review
  bool get hasIncorrectCards => incorrectCards > 0;

  /// Check if all incorrect cards have been reviewed
  bool get isFullyReviewed => incorrectCards > 0 && reviewedCards >= incorrectCards;

  @override
  String toString() {
    return 'ReviewDeck(categoryId: $categoryId, incorrectCards: $incorrectCards, reviewedCards: $reviewedCards)';
  }
}

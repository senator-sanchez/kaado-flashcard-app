/// Spaced Repetition System Models
/// 
/// This file contains data models for implementing a spaced repetition system
/// that helps users learn more effectively by scheduling cards for review
/// based on their performance and forgetting curves.


/// Represents the spaced repetition data for a single card
class SpacedRepetitionCard {
  final int cardId;
  final int categoryId;
  final int interval; // Days until next review
  final int repetitions; // Number of times reviewed correctly
  final double easeFactor; // Difficulty multiplier (2.5 = default)
  final int lastReviewed; // Timestamp of last review
  final int nextReview; // Timestamp of next scheduled review
  final int streak; // Consecutive correct answers
  final int totalReviews; // Total number of reviews

  const SpacedRepetitionCard({
    required this.cardId,
    required this.categoryId,
    required this.interval,
    required this.repetitions,
    required this.easeFactor,
    required this.lastReviewed,
    required this.nextReview,
    required this.streak,
    required this.totalReviews,
  });

  /// Create from database map
  factory SpacedRepetitionCard.fromMap(Map<String, dynamic> map) {
    return SpacedRepetitionCard(
      cardId: map['card_id'] as int,
      categoryId: map['category_id'] as int,
      interval: map['interval'] as int,
      repetitions: map['repetitions'] as int,
      easeFactor: (map['ease_factor'] as num).toDouble(),
      lastReviewed: map['last_reviewed'] as int,
      nextReview: map['next_review'] as int,
      streak: map['streak'] as int,
      totalReviews: map['total_reviews'] as int,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'card_id': cardId,
      'category_id': categoryId,
      'interval': interval,
      'repetitions': repetitions,
      'ease_factor': easeFactor,
      'last_reviewed': lastReviewed,
      'next_review': nextReview,
      'streak': streak,
      'total_reviews': totalReviews,
    };
  }

  /// Create a copy with updated values
  SpacedRepetitionCard copyWith({
    int? cardId,
    int? categoryId,
    int? interval,
    int? repetitions,
    double? easeFactor,
    int? lastReviewed,
    int? nextReview,
    int? streak,
    int? totalReviews,
  }) {
    return SpacedRepetitionCard(
      cardId: cardId ?? this.cardId,
      categoryId: categoryId ?? this.categoryId,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      streak: streak ?? this.streak,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }

  @override
  String toString() {
    return 'SpacedRepetitionCard(cardId: $cardId, interval: $interval, repetitions: $repetitions, easeFactor: $easeFactor, nextReview: $nextReview)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpacedRepetitionCard &&
        other.cardId == cardId &&
        other.categoryId == categoryId &&
        other.interval == interval &&
        other.repetitions == repetitions &&
        other.easeFactor == easeFactor &&
        other.lastReviewed == lastReviewed &&
        other.nextReview == nextReview &&
        other.streak == streak &&
        other.totalReviews == totalReviews;
  }

  @override
  int get hashCode {
    return cardId.hashCode ^
        categoryId.hashCode ^
        interval.hashCode ^
        repetitions.hashCode ^
        easeFactor.hashCode ^
        lastReviewed.hashCode ^
        nextReview.hashCode ^
        streak.hashCode ^
        totalReviews.hashCode;
  }
}

/// Represents a review session with spaced repetition data
class ReviewSession {
  final int totalCards;
  final int newCards;
  final int reviewCards;
  final int overdueCards;
  final int completedCards;
  final DateTime sessionDate;

  const ReviewSession({
    required this.totalCards,
    required this.newCards,
    required this.reviewCards,
    required this.overdueCards,
    required this.completedCards,
    required this.sessionDate,
  });

  /// Create from database map
  factory ReviewSession.fromMap(Map<String, dynamic> map) {
    return ReviewSession(
      totalCards: map['total_cards'] as int,
      newCards: map['new_cards'] as int,
      reviewCards: map['review_cards'] as int,
      overdueCards: map['overdue_cards'] as int,
      completedCards: map['completed_cards'] as int,
      sessionDate: DateTime.fromMillisecondsSinceEpoch(map['session_date'] as int),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'total_cards': totalCards,
      'new_cards': newCards,
      'review_cards': reviewCards,
      'overdue_cards': overdueCards,
      'completed_cards': completedCards,
      'session_date': sessionDate.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'ReviewSession(totalCards: $totalCards, newCards: $newCards, reviewCards: $reviewCards, overdueCards: $overdueCards, completedCards: $completedCards)';
  }
}

/// Spaced repetition intervals in days
class SpacedRepetitionIntervals {
  static const int newCardInterval = 1; // 1 day for new cards
  static const int learningInterval1 = 1; // 1 day
  static const int learningInterval2 = 3; // 3 days
  static const int learningInterval3 = 7; // 1 week
  static const int learningInterval4 = 14; // 2 weeks
  static const int learningInterval5 = 30; // 1 month
  static const int learningInterval6 = 90; // 3 months
  static const int learningInterval7 = 180; // 6 months

  /// Get the next interval based on current repetitions
  static int getNextInterval(int repetitions) {
    switch (repetitions) {
      case 0:
        return newCardInterval;
      case 1:
        return learningInterval1;
      case 2:
        return learningInterval2;
      case 3:
        return learningInterval3;
      case 4:
        return learningInterval4;
      case 5:
        return learningInterval5;
      case 6:
        return learningInterval6;
      default:
        return learningInterval7; // Max interval
    }
  }

  /// Get the interval name for display
  static String getIntervalName(int interval) {
    if (interval < 7) {
      return '$interval day${interval > 1 ? 's' : ''}';
    } else if (interval < 30) {
      final weeks = (interval / 7).round();
      return '$weeks week${weeks > 1 ? 's' : ''}';
    } else if (interval < 365) {
      final months = (interval / 30).round();
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = (interval / 365).round();
      return '$years year${years > 1 ? 's' : ''}';
    }
  }
}

/// Spaced repetition algorithm constants
class SpacedRepetitionConstants {
  static const double defaultEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const double maxEaseFactor = 3.0;
  static const double easeFactorDecrease = 0.15;
  static const double easeFactorIncrease = 0.1;
  static const int maxStreak = 100; // Cap streak to prevent overflow
}

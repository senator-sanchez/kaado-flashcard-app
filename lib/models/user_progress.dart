/// Represents user progress for a single card, including spaced repetition data
/// Combines the old SpacedRepetition and IncorrectCards functionality
class UserProgress {
  final int id;
  final int cardId;
  final String userId; // Could be device ID for offline app
  final int timesSeen;
  final int timesCorrect;
  final String? lastReviewed; // ISO 8601 timestamp
  final String? nextReview; // ISO 8601 timestamp for SRS
  final int difficultyLevel; // 1-5 scale
  final bool isMastered;
  final String? createdAt; // ISO 8601 timestamp
  final String? updatedAt; // ISO 8601 timestamp
  
  // Spaced repetition fields
  final int interval; // Days until next review
  final int repetitions; // Number of times reviewed correctly
  final double easeFactor; // Difficulty multiplier (2.5 = default)
  final int streak; // Consecutive correct answers
  final int totalReviews; // Total number of reviews
  
  // Sync fields
  final bool isDirty;

  UserProgress({
    required this.id,
    required this.cardId,
    required this.userId,
    this.timesSeen = 0,
    this.timesCorrect = 0,
    this.lastReviewed,
    this.nextReview,
    this.difficultyLevel = 1,
    this.isMastered = false,
    this.createdAt,
    this.updatedAt,
    this.interval = 1,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.streak = 0,
    this.totalReviews = 0,
    this.isDirty = false,
  });

  /// Create a UserProgress from a database map
  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      id: map['id'] ?? 0,
      cardId: map['card_id'] ?? 0,
      userId: map['user_id'] ?? '',
      timesSeen: map['times_seen'] ?? 0,
      timesCorrect: map['times_correct'] ?? 0,
      lastReviewed: map['last_reviewed'],
      nextReview: map['next_review'],
      difficultyLevel: map['difficulty_level'] ?? 1,
      isMastered: (map['is_mastered'] ?? 0) == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      interval: map['interval'] ?? 1,
      repetitions: map['repetitions'] ?? 0,
      easeFactor: (map['ease_factor'] ?? 2.5).toDouble(),
      streak: map['streak'] ?? 0,
      totalReviews: map['total_reviews'] ?? 0,
      isDirty: (map['is_dirty'] ?? 0) == 1,
    );
  }

  /// Convert UserProgress to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'user_id': userId,
      'times_seen': timesSeen,
      'times_correct': timesCorrect,
      'last_reviewed': lastReviewed,
      'next_review': nextReview,
      'difficulty_level': difficultyLevel,
      'is_mastered': isMastered ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'interval': interval,
      'repetitions': repetitions,
      'ease_factor': easeFactor,
      'streak': streak,
      'total_reviews': totalReviews,
      'is_dirty': isDirty ? 1 : 0,
    };
  }

  /// Check if this card is due for review
  bool get isDue {
    if (nextReview == null) return true;
    
    try {
      final nextReviewDate = DateTime.parse(nextReview!);
      return DateTime.now().isAfter(nextReviewDate);
    } catch (e) {
      return true; // If we can't parse the date, assume it's due
    }
  }

  /// Check if this is a new card (never reviewed)
  bool get isNew => repetitions == 0;

  /// Check if this card is overdue
  bool get isOverdue {
    if (nextReview == null || isNew) return false;
    
    try {
      final nextReviewDate = DateTime.parse(nextReview!);
      final now = DateTime.now();
      return now.isAfter(nextReviewDate.add(Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  /// Get accuracy percentage
  double get accuracy {
    if (timesSeen == 0) return 0.0;
    return (timesCorrect / timesSeen) * 100;
  }

  /// Create a copy with updated values
  UserProgress copyWith({
    int? id,
    int? cardId,
    String? userId,
    int? timesSeen,
    int? timesCorrect,
    String? lastReviewed,
    String? nextReview,
    int? difficultyLevel,
    bool? isMastered,
    String? createdAt,
    String? updatedAt,
    int? interval,
    int? repetitions,
    double? easeFactor,
    int? streak,
    int? totalReviews,
    bool? isDirty,
  }) {
    return UserProgress(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      timesSeen: timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      isMastered: isMastered ?? this.isMastered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      streak: streak ?? this.streak,
      totalReviews: totalReviews ?? this.totalReviews,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  String toString() {
    return 'UserProgress(id: $id, cardId: $cardId, interval: $interval, repetitions: $repetitions, easeFactor: $easeFactor, nextReview: $nextReview)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.id == id &&
        other.cardId == cardId &&
        other.userId == userId;
  }

  @override
  int get hashCode => id.hashCode ^ cardId.hashCode ^ userId.hashCode;
}

/// Review session statistics
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

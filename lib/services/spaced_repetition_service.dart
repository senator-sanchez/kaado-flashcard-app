import 'dart:math';
import '../models/spaced_repetition.dart';
import '../models/spaced_repetition_settings.dart';

/// Service for managing spaced repetition logic
class SpacedRepetitionService {
  static final SpacedRepetitionService _instance = SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  // User settings (default to standard preset)
  SpacedRepetitionSettings _settings = SpacedRepetitionPresets.standard;

  /// Update the spaced repetition settings
  void updateSettings(SpacedRepetitionSettings settings) {
    _settings = settings;
  }

  /// Get current settings
  SpacedRepetitionSettings get settings => _settings;

  /// Calculate the next review date based on performance
  /// 
  /// [card] - The current spaced repetition card data
  /// [isCorrect] - Whether the user answered correctly
  /// [responseTime] - Time taken to answer (optional, for future use)
  /// 
  /// Returns updated SpacedRepetitionCard with new interval and next review date
  SpacedRepetitionCard calculateNextReview(
    SpacedRepetitionCard card,
    bool isCorrect, {
    int? responseTime,
  }) {
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;

    if (isCorrect) {
      return _handleCorrectAnswer(card, nowMillis);
    } else {
      return _handleIncorrectAnswer(card, nowMillis);
    }
  }

  /// Handle correct answer - increase interval and ease factor
  SpacedRepetitionCard _handleCorrectAnswer(SpacedRepetitionCard card, int nowMillis) {
    int newInterval;
    double newEaseFactor = card.easeFactor;
    int newRepetitions = card.repetitions + 1;
    int newStreak = min(card.streak + 1, _settings.maxStreak);

    if (card.repetitions == 0) {
      // First correct answer - use learning interval
      newInterval = _settings.learningInterval1;
    } else if (card.repetitions == 1) {
      // Second correct answer - use learning interval
      newInterval = _settings.learningInterval2;
    } else {
      // Subsequent correct answers - use spaced repetition formula
      newInterval = (card.interval * card.easeFactor).round();
      
      // Increase ease factor slightly for good performance
      if (_settings.enableEaseFactorAdjustment) {
        newEaseFactor = min(
          card.easeFactor + _settings.easeFactorIncrease,
          _settings.maxEaseFactor,
        );
      }
    }

    // Calculate next review date
    final nextReviewDate = nowMillis + (newInterval * 24 * 60 * 60 * 1000);

    return card.copyWith(
      interval: newInterval,
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      lastReviewed: nowMillis,
      nextReview: nextReviewDate,
      streak: newStreak,
      totalReviews: card.totalReviews + 1,
    );
  }

  /// Handle incorrect answer - reset interval and decrease ease factor
  SpacedRepetitionCard _handleIncorrectAnswer(SpacedRepetitionCard card, int nowMillis) {
    // Reset to learning phase
    final newInterval = _settings.newCardInterval;
    final newRepetitions = 0; // Reset repetitions
    final newStreak = 0; // Reset streak
    
    // Decrease ease factor for poor performance
    double newEaseFactor = card.easeFactor;
    if (_settings.enableEaseFactorAdjustment) {
      newEaseFactor = max(
        card.easeFactor - _settings.easeFactorDecrease,
        _settings.minEaseFactor,
      );
    }

    // Calculate next review date
    final nextReviewDate = nowMillis + (newInterval * 24 * 60 * 60 * 1000);

    return card.copyWith(
      interval: newInterval,
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      lastReviewed: nowMillis,
      nextReview: nextReviewDate,
      streak: newStreak,
      totalReviews: card.totalReviews + 1,
    );
  }

  /// Create a new spaced repetition card for a new card
  SpacedRepetitionCard createNewCard(int cardId, int categoryId) {
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;
    final nextReviewDate = nowMillis + (_settings.newCardInterval * 24 * 60 * 60 * 1000);

    return SpacedRepetitionCard(
      cardId: cardId,
      categoryId: categoryId,
      interval: _settings.newCardInterval,
      repetitions: 0,
      easeFactor: _settings.defaultEaseFactor,
      lastReviewed: 0, // Never reviewed
      nextReview: nextReviewDate,
      streak: 0,
      totalReviews: 0,
    );
  }

  /// Check if a card is due for review
  bool isCardDue(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= card.nextReview;
  }

  /// Check if a card is overdue (past due date)
  bool isCardOverdue(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now > card.nextReview;
  }

  /// Get the number of days until next review
  int getDaysUntilReview(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysUntil = (card.nextReview - now) / (24 * 60 * 60 * 1000);
    return daysUntil.ceil();
  }

  /// Get the number of days overdue
  int getDaysOverdue(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysOverdue = (now - card.nextReview) / (24 * 60 * 60 * 1000);
    return daysOverdue.ceil();
  }

  /// Calculate review statistics for a set of cards
  Map<String, int> calculateReviewStats(List<SpacedRepetitionCard> cards) {
    int newCards = 0;
    int reviewCards = 0;
    int overdueCards = 0;
    int totalCards = cards.length;

    for (final card in cards) {
      if (card.repetitions == 0) {
        newCards++;
      } else if (isCardOverdue(card)) {
        overdueCards++;
      } else if (isCardDue(card)) {
        reviewCards++;
      }
    }

    return {
      'total': totalCards,
      'new': newCards,
      'review': reviewCards,
      'overdue': overdueCards,
    };
  }

  /// Get the next review date as a readable string
  String getNextReviewDateString(SpacedRepetitionCard card) {
    final nextReviewDate = DateTime.fromMillisecondsSinceEpoch(card.nextReview);
    final now = DateTime.now();
    final difference = nextReviewDate.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays > 1) {
      return 'In ${difference.inDays} days';
    } else {
      // Overdue
      final overdueDays = -difference.inDays;
      return 'Overdue by $overdueDays day${overdueDays > 1 ? 's' : ''}';
    }
  }

  /// Get the difficulty level based on ease factor
  String getDifficultyLevel(SpacedRepetitionCard card) {
    if (card.easeFactor >= 2.5) {
      return 'Easy';
    } else if (card.easeFactor >= 2.0) {
      return 'Medium';
    } else {
      return 'Hard';
    }
  }

  /// Get the learning stage based on repetitions
  String getLearningStage(SpacedRepetitionCard card) {
    if (card.repetitions == 0) {
      return 'New';
    } else if (card.repetitions <= 2) {
      return 'Learning';
    } else if (card.repetitions <= 5) {
      return 'Reviewing';
    } else {
      return 'Mastered';
    }
  }
}

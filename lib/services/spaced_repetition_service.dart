import 'dart:math';
import '../models/spaced_repetition.dart';
import '../models/spaced_repetition_settings.dart';
import '../models/user_progress.dart';

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

  /// Calculate the next review date based on performance (legacy method)
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

  /// Calculate the next review date based on performance (new schema)
  /// 
  /// [progress] - The current user progress data
  /// [isCorrect] - Whether the user answered correctly
  /// [responseTime] - Time taken to answer (optional, for future use)
  /// 
  /// Returns updated UserProgress with new interval and next review date
  UserProgress calculateNextReviewFromProgress(
    UserProgress progress,
    bool isCorrect, {
    int? responseTime,
  }) {
    final now = DateTime.now();

    if (isCorrect) {
      return _handleCorrectAnswerProgress(progress, now);
    } else {
      return _handleIncorrectAnswerProgress(progress, now);
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

  /// Handle correct answer for UserProgress - increase interval and ease factor
  UserProgress _handleCorrectAnswerProgress(UserProgress progress, DateTime now) {
    int newInterval;
    double newEaseFactor = progress.easeFactor;
    int newRepetitions = progress.repetitions + 1;
    int newStreak = min(progress.streak + 1, _settings.maxStreak);

    if (progress.repetitions == 0) {
      // First correct answer - use first learning interval
      newInterval = _settings.learningInterval1;
    } else if (progress.repetitions == 1) {
      // Second correct answer - use learning interval
      newInterval = _settings.learningInterval2;
    } else {
      // Subsequent correct answers - use spaced repetition formula
      newInterval = (progress.interval * progress.easeFactor).round();
      
      // Increase ease factor slightly for good performance
      if (_settings.enableEaseFactorAdjustment) {
        newEaseFactor = min(
          progress.easeFactor + _settings.easeFactorIncrease,
          _settings.maxEaseFactor,
        );
      }
    }

    // Calculate next review date
    final nextReviewDate = now.add(Duration(days: newInterval));

    return progress.copyWith(
      interval: newInterval,
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      lastReviewed: now.toIso8601String(),
      nextReview: nextReviewDate.toIso8601String(),
      streak: newStreak,
      totalReviews: progress.totalReviews + 1,
      timesSeen: progress.timesSeen + 1,
      timesCorrect: progress.timesCorrect + 1,
      isDirty: true,
    );
  }

  /// Handle incorrect answer for UserProgress - reset interval and decrease ease factor
  UserProgress _handleIncorrectAnswerProgress(UserProgress progress, DateTime now) {
    // Reset to learning phase
    final newInterval = _settings.newCardInterval;
    final newRepetitions = 0; // Reset repetitions
    final newStreak = 0; // Reset streak
    
    // Decrease ease factor for poor performance
    double newEaseFactor = progress.easeFactor;
    if (_settings.enableEaseFactorAdjustment) {
      newEaseFactor = max(
        progress.easeFactor - _settings.easeFactorDecrease,
        _settings.minEaseFactor,
      );
    }

    // Calculate next review date
    final nextReviewDate = now.add(Duration(days: newInterval));

    return progress.copyWith(
      interval: newInterval,
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      lastReviewed: now.toIso8601String(),
      nextReview: nextReviewDate.toIso8601String(),
      streak: newStreak,
      totalReviews: progress.totalReviews + 1,
      timesSeen: progress.timesSeen + 1,
      timesCorrect: progress.timesCorrect, // Don't increment for incorrect
      isDirty: true,
    );
  }

  /// Create a new user progress for a new card (new schema)
  UserProgress createNewUserProgress(int cardId, String userId) {
    final now = DateTime.now();
    final nextReviewDate = now.add(Duration(days: _settings.newCardInterval));

    return UserProgress(
      id: 0, // Will be set by database
      cardId: cardId,
      userId: userId,
      interval: _settings.newCardInterval,
      repetitions: 0,
      easeFactor: _settings.defaultEaseFactor,
      lastReviewed: null, // Never reviewed
      nextReview: nextReviewDate.toIso8601String(),
      streak: 0,
      totalReviews: 0,
      timesSeen: 0,
      timesCorrect: 0,
      isDirty: true,
    );
  }

  /// Create a new spaced repetition card for a new card (legacy method)
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

  /// Check if a card is due for review (legacy method)
  bool isCardDue(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= card.nextReview;
  }

  /// Check if a card is overdue (past due date) (legacy method)
  bool isCardOverdue(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now > card.nextReview;
  }

  /// Get the number of days until next review (legacy method)
  int getDaysUntilReview(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysUntil = (card.nextReview - now) / (24 * 60 * 60 * 1000);
    return daysUntil.ceil();
  }

  /// Get the number of days overdue (legacy method)
  int getDaysOverdue(SpacedRepetitionCard card) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysOverdue = (now - card.nextReview) / (24 * 60 * 60 * 1000);
    return daysOverdue.ceil();
  }

  /// Check if a card is due for review (new schema)
  bool isProgressDue(UserProgress progress) {
    return progress.isDue;
  }

  /// Check if a card is overdue (past due date) (new schema)
  bool isProgressOverdue(UserProgress progress) {
    return progress.isOverdue;
  }

  /// Get the number of days until next review (new schema)
  int getDaysUntilReviewFromProgress(UserProgress progress) {
    if (progress.nextReview == null) return 0;
    
    try {
      final nextReviewDate = DateTime.parse(progress.nextReview!);
      final now = DateTime.now();
      final daysUntil = nextReviewDate.difference(now).inDays;
      return daysUntil;
    } catch (e) {
      return 0;
    }
  }

  /// Get the number of days overdue (new schema)
  int getDaysOverdueFromProgress(UserProgress progress) {
    if (progress.nextReview == null) return 0;
    
    try {
      final nextReviewDate = DateTime.parse(progress.nextReview!);
      final now = DateTime.now();
      final daysOverdue = now.difference(nextReviewDate).inDays;
      return daysOverdue > 0 ? daysOverdue : 0;
    } catch (e) {
      return 0;
    }
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

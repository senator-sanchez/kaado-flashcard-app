import '../models/user_progress.dart';

/// SuperMemo 2 (SM-2) Spaced Repetition Algorithm
/// 
/// This algorithm calculates optimal review intervals based on user performance.
/// Quality scale: 0-5 (0=blackout, 5=perfect)
/// 
/// Algorithm details:
/// - Failed cards (quality < 3) reset to beginning
/// - Successful cards get increasing intervals
/// - Ease factor adjusts based on performance
/// - Intervals: 1 day, 6 days, then calculated intervals
class SRSAlgorithm {
  static const double _initialEaseFactor = 2.5;
  static const int _initialInterval = 1;
  static const double _minEaseFactor = 1.3;
  static const double _maxEaseFactor = 2.5;

  /// Calculate next review based on current progress and quality rating
  /// 
  /// [current] - Current user progress for the card
  /// [quality] - Quality rating from 0-5 (0=blackout, 5=perfect)
  /// Returns updated UserProgress with new review schedule
  static UserProgress calculateNextReview({
    required UserProgress current,
    required int quality,
  }) {
    // Validate quality input
    if (quality < 0 || quality > 5) {
      throw ArgumentError('Quality must be between 0 and 5, got $quality');
    }

    // If quality is less than 3 (failed), reset to beginning
    if (quality < 3) {
      return current.copyWith(
        repetitions: 0,
        interval: _initialInterval,
        easeFactor: current.easeFactor, // Keep current ease factor
        lastReviewed: DateTime.now().toIso8601String(),
        nextReview: DateTime.now().add(Duration(days: _initialInterval)).toIso8601String(),
        timesSeen: current.timesSeen + 1,
        totalReviews: current.totalReviews + 1,
        streak: 0, // Reset streak on failure
        isMastered: false,
        isDirty: true,
        updatedAt: DateTime.now().toIso8601String(),
      );
    }

    // Calculate new ease factor
    double newEaseFactor = current.easeFactor + 
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    
    // Clamp ease factor to reasonable bounds
    newEaseFactor = newEaseFactor.clamp(_minEaseFactor, _maxEaseFactor);

    // Calculate new interval based on repetitions
    int newInterval;
    if (current.repetitions == 0) {
      newInterval = _initialInterval; // 1 day
    } else if (current.repetitions == 1) {
      newInterval = 6; // 6 days
    } else {
      newInterval = (current.interval * newEaseFactor).round();
    }

    // Calculate new repetitions and mastery status
    int newRepetitions = current.repetitions + 1;
    bool isMastered = newRepetitions >= 5 && newInterval >= 30; // Mastered after 5 reps and 30+ day interval

    // Calculate next review date
    DateTime nextReview = DateTime.now().add(Duration(days: newInterval));

    return current.copyWith(
      repetitions: newRepetitions,
      interval: newInterval,
      easeFactor: newEaseFactor,
      lastReviewed: DateTime.now().toIso8601String(),
      nextReview: nextReview.toIso8601String(),
      timesSeen: current.timesSeen + 1,
      timesCorrect: current.timesCorrect + 1,
      totalReviews: current.totalReviews + 1,
      streak: current.streak + 1,
      isMastered: isMastered,
      isDirty: true,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Get quality rating from swipe gesture
  /// 
  /// [swipeDirection] - Direction of swipe gesture
  /// Returns quality rating (0-5)
  static int getQualityFromSwipe(String swipeDirection) {
    switch (swipeDirection.toLowerCase()) {
      case 'left':
        return 0; // Blackout - completely forgot
      case 'right':
        return 5; // Perfect - immediate recall
      case 'up':
        return -1; // Skip - no quality change
      case 'down':
        return -1; // Go back - no quality change
      default:
        throw ArgumentError('Invalid swipe direction: $swipeDirection');
    }
  }

  /// Check if a card is due for review
  /// 
  /// [progress] - User progress for the card
  /// Returns true if card should be reviewed now
  static bool isCardDue(UserProgress progress) {
    if (progress.nextReview == null) return true;
    return DateTime.now().isAfter(DateTime.parse(progress.nextReview!));
  }

  /// Get cards due for review from a list of progress records
  /// 
  /// [progressList] - List of user progress records
  /// Returns list of progress records that are due for review
  static List<UserProgress> getCardsDue(List<UserProgress> progressList) {
    return progressList.where((progress) => isCardDue(progress)).toList();
  }

  /// Calculate overall learning progress
  /// 
  /// [progressList] - List of user progress records
  /// Returns progress statistics
  static Map<String, dynamic> calculateProgressStats(List<UserProgress> progressList) {
    if (progressList.isEmpty) {
      return {
        'totalCards': 0,
        'masteredCards': 0,
        'dueCards': 0,
        'masteryPercentage': 0.0,
        'averageEaseFactor': 0.0,
      };
    }

    int totalCards = progressList.length;
    int masteredCards = progressList.where((p) => p.isMastered).length;
    int dueCards = getCardsDue(progressList).length;
    double masteryPercentage = (masteredCards / totalCards) * 100;
    double averageEaseFactor = progressList
        .map((p) => p.easeFactor)
        .reduce((a, b) => a + b) / totalCards;

    return {
      'totalCards': totalCards,
      'masteredCards': masteredCards,
      'dueCards': dueCards,
      'masteryPercentage': masteryPercentage,
      'averageEaseFactor': averageEaseFactor,
    };
  }

  /// Initialize progress for a new card
  /// 
  /// [cardId] - ID of the card
  /// [userId] - ID of the user (default: 'default')
  /// Returns new UserProgress instance
  static UserProgress initializeProgress(int cardId, {String userId = 'default'}) {
    final now = DateTime.now();
    return UserProgress(
      id: 0, // Will be set by database
      cardId: cardId,
      userId: userId,
      timesSeen: 0,
      timesCorrect: 0,
      lastReviewed: null,
      nextReview: now.toIso8601String(), // Start immediately
      difficultyLevel: 0,
      isMastered: false,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
      interval: _initialInterval,
      repetitions: 0,
      easeFactor: _initialEaseFactor,
      streak: 0,
      totalReviews: 0,
      isDirty: false,
    );
  }
}

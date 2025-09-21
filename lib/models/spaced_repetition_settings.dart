/// Spaced Repetition Settings Model
/// 
/// This model represents user-customizable settings for the spaced repetition system.
/// Allows users to personalize their learning experience based on their preferences
/// and learning style.

/// User-customizable settings for spaced repetition
class SpacedRepetitionSettings {
  // === Interval Settings ===
  final int newCardInterval; // Days for first review of new cards
  final int learningInterval1; // First learning interval
  final int learningInterval2; // Second learning interval
  final int learningInterval3; // Third learning interval
  final int learningInterval4; // Fourth learning interval
  final int learningInterval5; // Fifth learning interval
  final int learningInterval6; // Sixth learning interval
  final int maxInterval; // Maximum interval between reviews

  // === Ease Factor Settings ===
  final double defaultEaseFactor; // Starting ease factor for new cards
  final double minEaseFactor; // Minimum ease factor
  final double maxEaseFactor; // Maximum ease factor
  final double easeFactorDecrease; // How much to decrease on incorrect
  final double easeFactorIncrease; // How much to increase on correct

  // === Daily Limits ===
  final int dailyNewCardsLimit; // Maximum new cards per day
  final int dailyReviewLimit; // Maximum reviews per day (0 = unlimited)

  // === Review Order ===
  final ReviewOrder reviewOrder; // Order of new cards vs reviews
  final bool mixNewAndReview; // Whether to mix new cards with reviews

  // === Advanced Settings ===
  final bool enableGraduatedIntervals; // Use graduated intervals for learning
  final bool enableEaseFactorAdjustment; // Allow ease factor to change
  final int maxStreak; // Maximum streak count

  const SpacedRepetitionSettings({
    // Default intervals (in days)
    this.newCardInterval = 1,
    this.learningInterval1 = 1,
    this.learningInterval2 = 3,
    this.learningInterval3 = 7,
    this.learningInterval4 = 14,
    this.learningInterval5 = 30,
    this.learningInterval6 = 90,
    this.maxInterval = 180,

    // Default ease factor settings
    this.defaultEaseFactor = 2.5,
    this.minEaseFactor = 1.3,
    this.maxEaseFactor = 3.0,
    this.easeFactorDecrease = 0.15,
    this.easeFactorIncrease = 0.1,

    // Default daily limits
    this.dailyNewCardsLimit = 20,
    this.dailyReviewLimit = 0, // 0 = unlimited

    // Default review order
    this.reviewOrder = ReviewOrder.newCardsFirst,
    this.mixNewAndReview = false,

    // Default advanced settings
    this.enableGraduatedIntervals = true,
    this.enableEaseFactorAdjustment = true,
    this.maxStreak = 100,
  });

  /// Create from database map
  factory SpacedRepetitionSettings.fromMap(Map<String, dynamic> map) {
    return SpacedRepetitionSettings(
      newCardInterval: map['new_card_interval'] as int? ?? 1,
      learningInterval1: map['learning_interval_1'] as int? ?? 1,
      learningInterval2: map['learning_interval_2'] as int? ?? 3,
      learningInterval3: map['learning_interval_3'] as int? ?? 7,
      learningInterval4: map['learning_interval_4'] as int? ?? 14,
      learningInterval5: map['learning_interval_5'] as int? ?? 30,
      learningInterval6: map['learning_interval_6'] as int? ?? 90,
      maxInterval: map['max_interval'] as int? ?? 180,
      defaultEaseFactor: (map['default_ease_factor'] as num?)?.toDouble() ?? 2.5,
      minEaseFactor: (map['min_ease_factor'] as num?)?.toDouble() ?? 1.3,
      maxEaseFactor: (map['max_ease_factor'] as num?)?.toDouble() ?? 3.0,
      easeFactorDecrease: (map['ease_factor_decrease'] as num?)?.toDouble() ?? 0.15,
      easeFactorIncrease: (map['ease_factor_increase'] as num?)?.toDouble() ?? 0.1,
      dailyNewCardsLimit: map['daily_new_cards_limit'] as int? ?? 20,
      dailyReviewLimit: map['daily_review_limit'] as int? ?? 0,
      reviewOrder: ReviewOrder.values[map['review_order'] as int? ?? 0],
      mixNewAndReview: (map['mix_new_and_review'] as int? ?? 0) == 1,
      enableGraduatedIntervals: (map['enable_graduated_intervals'] as int? ?? 1) == 1,
      enableEaseFactorAdjustment: (map['enable_ease_factor_adjustment'] as int? ?? 1) == 1,
      maxStreak: map['max_streak'] as int? ?? 100,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'new_card_interval': newCardInterval,
      'learning_interval_1': learningInterval1,
      'learning_interval_2': learningInterval2,
      'learning_interval_3': learningInterval3,
      'learning_interval_4': learningInterval4,
      'learning_interval_5': learningInterval5,
      'learning_interval_6': learningInterval6,
      'max_interval': maxInterval,
      'default_ease_factor': defaultEaseFactor,
      'min_ease_factor': minEaseFactor,
      'max_ease_factor': maxEaseFactor,
      'ease_factor_decrease': easeFactorDecrease,
      'ease_factor_increase': easeFactorIncrease,
      'daily_new_cards_limit': dailyNewCardsLimit,
      'daily_review_limit': dailyReviewLimit,
      'review_order': reviewOrder.index,
      'mix_new_and_review': mixNewAndReview ? 1 : 0,
      'enable_graduated_intervals': enableGraduatedIntervals ? 1 : 0,
      'enable_ease_factor_adjustment': enableEaseFactorAdjustment ? 1 : 0,
      'max_streak': maxStreak,
    };
  }

  /// Create a copy with updated values
  SpacedRepetitionSettings copyWith({
    int? newCardInterval,
    int? learningInterval1,
    int? learningInterval2,
    int? learningInterval3,
    int? learningInterval4,
    int? learningInterval5,
    int? learningInterval6,
    int? maxInterval,
    double? defaultEaseFactor,
    double? minEaseFactor,
    double? maxEaseFactor,
    double? easeFactorDecrease,
    double? easeFactorIncrease,
    int? dailyNewCardsLimit,
    int? dailyReviewLimit,
    ReviewOrder? reviewOrder,
    bool? mixNewAndReview,
    bool? enableGraduatedIntervals,
    bool? enableEaseFactorAdjustment,
    int? maxStreak,
  }) {
    return SpacedRepetitionSettings(
      newCardInterval: newCardInterval ?? this.newCardInterval,
      learningInterval1: learningInterval1 ?? this.learningInterval1,
      learningInterval2: learningInterval2 ?? this.learningInterval2,
      learningInterval3: learningInterval3 ?? this.learningInterval3,
      learningInterval4: learningInterval4 ?? this.learningInterval4,
      learningInterval5: learningInterval5 ?? this.learningInterval5,
      learningInterval6: learningInterval6 ?? this.learningInterval6,
      maxInterval: maxInterval ?? this.maxInterval,
      defaultEaseFactor: defaultEaseFactor ?? this.defaultEaseFactor,
      minEaseFactor: minEaseFactor ?? this.minEaseFactor,
      maxEaseFactor: maxEaseFactor ?? this.maxEaseFactor,
      easeFactorDecrease: easeFactorDecrease ?? this.easeFactorDecrease,
      easeFactorIncrease: easeFactorIncrease ?? this.easeFactorIncrease,
      dailyNewCardsLimit: dailyNewCardsLimit ?? this.dailyNewCardsLimit,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      reviewOrder: reviewOrder ?? this.reviewOrder,
      mixNewAndReview: mixNewAndReview ?? this.mixNewAndReview,
      enableGraduatedIntervals: enableGraduatedIntervals ?? this.enableGraduatedIntervals,
      enableEaseFactorAdjustment: enableEaseFactorAdjustment ?? this.enableEaseFactorAdjustment,
      maxStreak: maxStreak ?? this.maxStreak,
    );
  }

  /// Get the next interval based on current repetitions
  int getNextInterval(int repetitions) {
    if (!enableGraduatedIntervals) {
      return newCardInterval;
    }

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
        return maxInterval;
    }
  }

  /// Get the interval name for display
  String getIntervalName(int interval) {
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

  /// Validate settings
  bool isValid() {
    return newCardInterval > 0 &&
        learningInterval1 > 0 &&
        learningInterval2 > learningInterval1 &&
        learningInterval3 > learningInterval2 &&
        learningInterval4 > learningInterval3 &&
        learningInterval5 > learningInterval4 &&
        learningInterval6 > learningInterval5 &&
        maxInterval > learningInterval6 &&
        defaultEaseFactor > 0 &&
        minEaseFactor > 0 &&
        maxEaseFactor > minEaseFactor &&
        easeFactorDecrease > 0 &&
        easeFactorIncrease > 0 &&
        dailyNewCardsLimit >= 0 &&
        dailyReviewLimit >= 0 &&
        maxStreak > 0;
  }

  @override
  String toString() {
    return 'SpacedRepetitionSettings(newCardInterval: $newCardInterval, dailyNewCardsLimit: $dailyNewCardsLimit, reviewOrder: $reviewOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpacedRepetitionSettings &&
        other.newCardInterval == newCardInterval &&
        other.learningInterval1 == learningInterval1 &&
        other.learningInterval2 == learningInterval2 &&
        other.learningInterval3 == learningInterval3 &&
        other.learningInterval4 == learningInterval4 &&
        other.learningInterval5 == learningInterval5 &&
        other.learningInterval6 == learningInterval6 &&
        other.maxInterval == maxInterval &&
        other.defaultEaseFactor == defaultEaseFactor &&
        other.minEaseFactor == minEaseFactor &&
        other.maxEaseFactor == maxEaseFactor &&
        other.easeFactorDecrease == easeFactorDecrease &&
        other.easeFactorIncrease == easeFactorIncrease &&
        other.dailyNewCardsLimit == dailyNewCardsLimit &&
        other.dailyReviewLimit == dailyReviewLimit &&
        other.reviewOrder == reviewOrder &&
        other.mixNewAndReview == mixNewAndReview &&
        other.enableGraduatedIntervals == enableGraduatedIntervals &&
        other.enableEaseFactorAdjustment == enableEaseFactorAdjustment &&
        other.maxStreak == maxStreak;
  }

  @override
  int get hashCode {
    return newCardInterval.hashCode ^
        learningInterval1.hashCode ^
        learningInterval2.hashCode ^
        learningInterval3.hashCode ^
        learningInterval4.hashCode ^
        learningInterval5.hashCode ^
        learningInterval6.hashCode ^
        maxInterval.hashCode ^
        defaultEaseFactor.hashCode ^
        minEaseFactor.hashCode ^
        maxEaseFactor.hashCode ^
        easeFactorDecrease.hashCode ^
        easeFactorIncrease.hashCode ^
        dailyNewCardsLimit.hashCode ^
        dailyReviewLimit.hashCode ^
        reviewOrder.hashCode ^
        mixNewAndReview.hashCode ^
        enableGraduatedIntervals.hashCode ^
        enableEaseFactorAdjustment.hashCode ^
        maxStreak.hashCode;
  }
}

/// Review order options
enum ReviewOrder {
  newCardsFirst, // Show new cards before reviews
  reviewsFirst, // Show reviews before new cards
  mixed, // Mix new cards and reviews together
}

/// Preset configurations for different learning styles
class SpacedRepetitionPresets {
  static const SpacedRepetitionSettings beginner = SpacedRepetitionSettings(
    newCardInterval: 1,
    learningInterval1: 1,
    learningInterval2: 2,
    learningInterval3: 4,
    learningInterval4: 7,
    learningInterval5: 14,
    learningInterval6: 30,
    maxInterval: 60,
    dailyNewCardsLimit: 10,
    reviewOrder: ReviewOrder.newCardsFirst,
  );

  static const SpacedRepetitionSettings standard = SpacedRepetitionSettings(
    newCardInterval: 1,
    learningInterval1: 1,
    learningInterval2: 3,
    learningInterval3: 7,
    learningInterval4: 14,
    learningInterval5: 30,
    learningInterval6: 90,
    maxInterval: 180,
    dailyNewCardsLimit: 20,
    reviewOrder: ReviewOrder.newCardsFirst,
  );

  static const SpacedRepetitionSettings intensive = SpacedRepetitionSettings(
    newCardInterval: 1,
    learningInterval1: 1,
    learningInterval2: 2,
    learningInterval3: 3,
    learningInterval4: 5,
    learningInterval5: 7,
    learningInterval6: 14,
    maxInterval: 30,
    dailyNewCardsLimit: 50,
    reviewOrder: ReviewOrder.mixed,
  );

  static const SpacedRepetitionSettings relaxed = SpacedRepetitionSettings(
    newCardInterval: 2,
    learningInterval1: 3,
    learningInterval2: 7,
    learningInterval3: 14,
    learningInterval4: 30,
    learningInterval5: 60,
    learningInterval6: 120,
    maxInterval: 365,
    dailyNewCardsLimit: 5,
    reviewOrder: ReviewOrder.reviewsFirst,
  );
}

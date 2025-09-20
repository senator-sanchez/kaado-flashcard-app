// Dart imports
import 'dart:math' as math;

// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/flashcard.dart';

// Project imports - Services
import '../services/database_service.dart';
import '../services/card_display_service.dart';

// Project imports - Utils
import '../utils/constants.dart';
import '../utils/theme_colors.dart';
import '../utils/animation_constants.dart';

// Project imports - Constants
import '../constants/app_colors.dart';

// Project imports - Widgets
import '../widgets/flashcard_widget.dart';
import '../widgets/progress_bar.dart';
import '../widgets/fab_menu.dart';
import '../widgets/text_with_background.dart';
import '../widgets/quick_edit_card_dialog.dart';

/// Screen for reviewing incorrect cards from a specific deck
class ReviewScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final DatabaseService databaseService;

  const ReviewScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.databaseService,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with TickerProviderStateMixin {
  // === Services ===
  final CardDisplayService _cardDisplayService = CardDisplayService.instance;
  
  // === UI State Management ===
  final GlobalKey<FabMenuState> _fabMenuKey = GlobalKey<FabMenuState>();
  List<Flashcard> _incorrectCards = [];
  int _currentCardIndex = 0;
  bool _isLoading = false;
  bool _showAnswer = false;
  
  // === Progress Tracking ===
  int _cardsLearned = 0; // Cards marked as correct during review
  
  // === Animation Controllers ===
  late AnimationController _swipeAnimationController;
  
  // === Drag Gesture Tracking ===
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  Offset _dragStartPosition = Offset.zero;
  bool _hasReachedThreshold = false;
  bool _isAnimationBlocked = false;
  
  // === Animation Constants ===
  static const double _maxDragDistance = AnimationConstants.maxDragDistance;
  static const double _thresholdValue = AnimationConstants.thresholdValue;

  @override
  void initState() {
    super.initState();
    _loadIncorrectCards();
    _cardDisplayService.loadSettings();
    
    // Initialize animation controllers
    _swipeAnimationController = AnimationController(
      duration: AnimationConstants.swipeDuration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cards when screen becomes visible (e.g., when returning from another screen)
    _loadIncorrectCards();
  }

  /// Load incorrect cards for the selected category
  Future<void> _loadIncorrectCards() async {
    setState(() => _isLoading = true);
    try {
      final incorrectCards = await widget.databaseService.getIncorrectCards(widget.categoryId);
      
      // Convert incorrect cards to flashcards
      final List<Flashcard> flashcards = [];
      for (final incorrectCard in incorrectCards) {
        final flashcard = await widget.databaseService.getCardById(incorrectCard.cardId);
        if (flashcard != null) {
          flashcards.add(flashcard);
        }
      }
      
      
      setState(() {
        _incorrectCards = flashcards;
        _currentCardIndex = 0;
        _showAnswer = false;
        _cardsLearned = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // In a production app, you might want to show an error message to the user
    }
  }

  /// Mark current card as learned (correct) and remove from review list
  Future<void> _markAsLearned() async {
    final currentCard = _getCurrentFlashcard();
    if (currentCard.id > 0) {
      try {
        await widget.databaseService.markCardCorrect(currentCard.id, widget.categoryId);
        setState(() {
          _cardsLearned++;
        });
        _advanceToNextCard();
      } catch (e) {
      }
    }
  }

  /// Mark current card as reviewed but keep in incorrect list
  Future<void> _markAsReviewed() async {
    final currentCard = _getCurrentFlashcard();
    if (currentCard.id > 0) {
      try {
        await widget.databaseService.markCardReviewed(currentCard.id, widget.categoryId);
        _advanceToNextCard();
      } catch (e) {
      }
    }
  }

  /// Skip current card (keep as incorrect)
  void _skipCard() {
    _advanceToNextCard();
  }

  /// Go back to previous card
  void _goBackToPreviousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
        _showAnswer = false;
      });
    }
  }

  /// Shuffle remaining incorrect cards
  void _shuffleCards() {
    if (_incorrectCards.isEmpty || _currentCardIndex >= _incorrectCards.length) {
      return;
    }
    
    setState(() {
      // Only shuffle the remaining cards (from current position onwards)
      final remainingCards = _incorrectCards.sublist(_currentCardIndex);
      remainingCards.shuffle();
      
      // Replace the remaining cards with shuffled version
      _incorrectCards = [
        ..._incorrectCards.sublist(0, _currentCardIndex), // Keep already seen cards
        ...remainingCards, // Add shuffled remaining cards
      ];
      
      _showAnswer = false;
    });
  }

  /// Reset review session
  void _resetReview() {
    setState(() {
      _currentCardIndex = 0;
      _cardsLearned = 0;
      _showAnswer = false;
      // Reset drag-related states
      _dragOffset = Offset.zero;
      _isDragging = false;
      _hasReachedThreshold = false;
      _isAnimationBlocked = false;
    });
  }

  /// Close the FAB menu
  void _closeFabMenu() {
    _fabMenuKey.currentState?.closeMenu();
  }

  /// Show the quick edit card dialog
  void _showEditCardDialog() async {
    if (_incorrectCards.isEmpty) return;
    
    final currentCard = _getCurrentFlashcard();
    
    // Fetch the latest card data from database to ensure notes are included
    final latestCard = await widget.databaseService.getCardById(currentCard.id);
    if (latestCard == null) return;
    
    showDialog(
      context: context,
      builder: (context) => QuickEditCardDialog(
        card: latestCard,
        onCardUpdated: () {
          // Refresh the incorrect cards to include notes field
          _refreshIncorrectCards();
        },
      ),
    );
  }

  /// Refresh incorrect cards to include notes field
  Future<void> _refreshIncorrectCards() async {
    if (_incorrectCards.isEmpty) return;
    
    try {
      // Reload incorrect cards with notes field included
      await _loadIncorrectCards();
      // Reset answer visibility to ensure card shows front side
      setState(() {
        _showAnswer = false;
      });
    } catch (e) {
      // If refresh fails, continue with existing cards
    }
  }

  /// Toggle answer visibility
  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
    _closeFabMenu();
  }

  /// Get the current flashcard
  Flashcard _getCurrentFlashcard() {
    if (_incorrectCards.isEmpty) {
      return Flashcard(id: 0, kana: '', english: '', categoryId: 0);
    }
    return _currentCardIndex < _incorrectCards.length 
        ? _incorrectCards[_currentCardIndex] 
        : _incorrectCards.last;
  }

  /// Check if review is completed
  bool _isReviewCompleted() {
    return _incorrectCards.isEmpty || _currentCardIndex >= _incorrectCards.length;
  }

  /// Advance to the next card
  void _advanceToNextCard() {
    _currentCardIndex++;
    _showAnswer = false;
  }

  /// Build the card widget
  Widget _buildCard() {
    final cardWidget = FlashcardWidget(
      flashcard: _getCurrentFlashcard(),
      showAnswer: _showAnswer,
      isCompleted: _isReviewCompleted(),
      onTap: _isReviewCompleted() ? _resetReview : _toggleAnswer,
      displaySettings: _cardDisplayService.currentSettings,
      onEdit: _showEditCardDialog,
    );

    return _buildSwipeableCard(cardWidget);
  }

  /// Build the swipeable card with drag animations
  Widget _buildSwipeableCard(Widget cardWidget) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: _isReviewCompleted() ? _resetReview : _toggleAnswer,
      behavior: HitTestBehavior.deferToChild,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _dragOffset.dx * AppConstants.swipeRotationMultiplier,
          child: AnimatedOpacity(
            opacity: _hasReachedThreshold ? AppConstants.swipeThresholdOpacity : 1.0,
            duration: Duration(milliseconds: AppConstants.swipeOpacityAnimationDuration),
            child: cardWidget,
          ),
        ),
      ),
    );
  }

  /// Handle pan start
  void _onPanStart(DragStartDetails details) {
    if (_incorrectCards.isEmpty || _isAnimationBlocked) return;
    
    _closeFabMenu();
    
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _hasReachedThreshold = false;
    });
    
    _stopAllAnimations();
  }

  /// Handle pan update
  void _onPanUpdate(DragUpdateDetails details) {
    if (_incorrectCards.isEmpty || !_isDragging || _isAnimationBlocked) return;
    
    final delta = details.globalPosition - _dragStartPosition;
    final absDx = delta.dx.abs();
    final absDy = delta.dy.abs();
    
    setState(() {
      if (absDx > absDy) {
        // Primarily horizontal movement
        _dragOffset = Offset(delta.dx, 0);
        
        if (absDx >= _maxDragDistance * _thresholdValue && !_hasReachedThreshold) {
          _hasReachedThreshold = true;
        }
      } else {
        // Primarily vertical movement
        _dragOffset = Offset(0, delta.dy);
        
        if (absDy >= _maxDragDistance * _thresholdValue && !_hasReachedThreshold) {
          _hasReachedThreshold = true;
        }
      }
    });
  }

  /// Handle pan end
  void _onPanEnd(DragEndDetails details) {
    if (_incorrectCards.isEmpty || !_isDragging || _isAnimationBlocked) return;
    
    setState(() {
      _isDragging = false;
    });
    
    final velocity = details.velocity.pixelsPerSecond;
    final dragDistance = _dragOffset.distance;
    
    if (_hasReachedThreshold || dragDistance >= _maxDragDistance * _thresholdValue) {
      _completeSwipeAction(velocity);
    } else {
      _returnCardToCenter();
    }
  }

  /// Complete the swipe action based on direction
  void _completeSwipeAction(Offset velocity) {
    final delta = _dragOffset;
    final absDx = delta.dx.abs();
    final absDy = delta.dy.abs();
    final isLastCard = _currentCardIndex >= _incorrectCards.length - 1;
    
    if (absDx > absDy) {
      // Horizontal swipe
      if (delta.dx > 0) {
        // Swipe right - mark as learned
        _markAsLearned();
        _animateCardExit(true); // Always animate exit, even for last card
      } else {
        // Swipe left - mark as reviewed but keep incorrect
        _markAsReviewed();
        _animateCardExit(false); // Always animate exit, even for last card
      }
    } else {
      // Vertical swipe
      if (delta.dy < 0) {
        // Swipe up - skip (keep as incorrect)
        if (isLastCard) {
          _skipCard();
        } else {
          _animateCardExit(null);
          _skipCard();
        }
      } else {
        // Swipe down - go back to previous card
        if (_currentCardIndex > 0) {
          _goBackToPreviousCard();
        } else {
          _returnCardToCenter();
        }
      }
    }
  }

  /// Animate card exit
  void _animateCardExit(bool? isLearned) {
    setState(() {
      _isAnimationBlocked = true;
    });
    
    final screenWidth = MediaQuery.of(context).size.width;
    final exitDistance = screenWidth * AppConstants.swipeExitDistanceMultiplier;
    
    Offset exitOffset;
    if (isLearned == true) {
      exitOffset = Offset(exitDistance, _dragOffset.dy);
    } else if (isLearned == false) {
      exitOffset = Offset(-exitDistance, _dragOffset.dy);
    } else {
      exitOffset = Offset(_dragOffset.dx, -exitDistance);
    }
    
    _animateToPosition(exitOffset, Duration(milliseconds: AppConstants.swipeExitAnimationDuration)).then((_) {
      _resetCardPosition();
      setState(() {});
    });
  }

  /// Return card to center
  void _returnCardToCenter() {
    setState(() {
      _isAnimationBlocked = true;
    });
    
    _animateToPosition(Offset.zero, Duration(milliseconds: AppConstants.swipeReturnAnimationDuration)).then((_) {
      _resetCardPosition();
    });
  }

  /// Animate to a specific position
  Future<void> _animateToPosition(Offset targetOffset, Duration duration) async {
    final startOffset = _dragOffset;
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < duration) {
      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      final easedProgress = 1.0 - math.pow(1.0 - progress, 3);
      
      setState(() {
        _dragOffset = Offset.lerp(startOffset, targetOffset, easedProgress)!;
      });
      
      await Future.delayed(Duration(milliseconds: AppConstants.swipeAnimationFrameRate));
    }
    
    setState(() {
      _dragOffset = targetOffset;
    });
  }

  /// Reset card position
  void _resetCardPosition() {
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
      _hasReachedThreshold = false;
      _isAnimationBlocked = false;
    });
    _resetAllAnimations();
  }

  /// Reset all animation controllers
  void _resetAllAnimations() {
    _swipeAnimationController.reset();
  }

  /// Stop all ongoing animations
  void _stopAllAnimations() {
    _swipeAnimationController.stop(canceled: false);
  }

  /// Build swipe hint widget
  Widget _buildSwipeHint(String arrow, String label, Color color) {
    return Column(
      children: [
        TextWithBackground(
          arrow,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * AppConstants.swipeHintArrowSizeMultiplier,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          isTopText: false,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * AppConstants.swipeHintSpacingMultiplier),
        TextWithBackground(
          label,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * AppConstants.swipeHintLabelSizeMultiplier,
            color: color,
            fontWeight: AppConstants.cardTitleWeight,
          ),
          isTopText: false,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.instance;
    
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.appBarBackground,
        foregroundColor: colors.appBarIcon,
        elevation: 0,
        title: Text(
          'Review: ${widget.categoryName}',
          style: TextStyle(
            color: colors.appBarIcon,
            fontSize: AppConstants.englishTextSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.appBarIcon),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: _closeFabMenu,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Progress Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.cardPadding),
                    child: Builder(
                      builder: (context) {
                        final progressText = _incorrectCards.isEmpty 
                            ? '0/0' 
                            : _currentCardIndex >= _incorrectCards.length 
                                ? '${_incorrectCards.length}/${_incorrectCards.length}'
                                : '${_currentCardIndex + 1}/${_incorrectCards.length}';
                        final scoreText = _incorrectCards.isEmpty 
                            ? 'No Cards' 
                            : '$_cardsLearned Learned';
                        final progressValue = _incorrectCards.isEmpty 
                            ? 0.0 
                            : _currentCardIndex / _incorrectCards.length;
                        final isCompleted = _isReviewCompleted();
                        
                        return ProgressBar(
                          progressText: progressText,
                          scoreText: scoreText,
                          progressValue: progressValue,
                          isCompleted: isCompleted,
                        );
                      },
                    ),
                  ),

                  SizedBox(height: AppConstants.mediumSpacing),

                  // Flashcard
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppConstants.cardPadding),
                        child: _isLoading 
                            ? _buildLoadingCard()
                            : _incorrectCards.isEmpty 
                                ? _buildNoCardsPlaceholder()
                                : _buildCard()
                      ),
                    ),
                  ),

                  // Swipe Instructions
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.cardPadding),
                    child: _incorrectCards.isEmpty 
                        ? SizedBox.shrink()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSwipeHint('←', 'Keep Incorrect', colors.incorrectButton),
                                  _buildSwipeHint('↑', 'Skip', colors.skipButton),
                                  _buildSwipeHint('↓', 'Back', colors.actionButtonBackground),
                                  _buildSwipeHint('→', 'Learned', colors.correctButton),
                                ],
                              ),
                            ],
                          ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * AppConstants.instructionSpacingMultiplier),
                ],
              ),
            ),
            
            // FAB positioned above the swipe hints
            Positioned(
              bottom: 120,
              right: 16,
              child: FabMenu(
                key: _fabMenuKey,
                onShuffle: _shuffleCards,
                onReset: _resetReview,
                isEnabled: _incorrectCards.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    final colors = ThemeColors.instance;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * AppConstants.cardHeightMultiplier;
    
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardAnimationBorderRadius),
        border: Border.all(color: colors.divider, width: AppConstants.cardBorderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.cardAnimationShadowBlur,
            offset: Offset(0, AppConstants.cardAnimationShadowOffset),
            spreadRadius: AppConstants.cardAnimationShadowSpread,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppConstants.cardAnimationSpacing),
            Text(
              'Loading review cards...',
              style: TextStyle(
                fontSize: AppConstants.cardAnimationTextSize,
                color: colors.secondaryText,
                fontWeight: AppConstants.cardTitleWeight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCardsPlaceholder() {
    final colors = ThemeColors.instance;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * AppConstants.cardHeightMultiplier;
    
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardAnimationBorderRadius),
        border: Border.all(color: colors.divider, width: AppConstants.cardBorderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: AppConstants.shadowOpacity),
            blurRadius: AppConstants.cardAnimationShadowBlur,
            offset: Offset(0, AppConstants.cardAnimationShadowOffset),
            spreadRadius: AppConstants.cardAnimationShadowSpread,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: AppConstants.emptyStateIconSize,
              color: AppColors.success,
            ),
            SizedBox(height: AppConstants.cardAnimationSpacing),
            Text(
              'No incorrect cards to review!',
              style: TextStyle(
                fontSize: AppConstants.cardAnimationTextSize,
                color: colors.secondaryText,
                fontWeight: AppConstants.cardTitleWeight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.cardAnimationSubtextSpacing),
            Text(
              'Great job! All cards in this deck are correct.',
              style: TextStyle(
                fontSize: AppConstants.cardAnimationSubtextSize,
                color: colors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

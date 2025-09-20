// Dart imports
import 'dart:async';
import 'dart:math' as math;

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports - Models
import '../models/flashcard.dart';
import '../models/category.dart';
import '../models/spaced_repetition.dart';

// Project imports - Services
import '../services/database_service.dart';
import '../services/card_display_service.dart';
import '../services/theme_service.dart';
import '../services/background_photo_service.dart';
import '../services/spaced_repetition_service.dart';

// Project imports - Constants
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../utils/animation_constants.dart';

// Project imports - Widgets
import '../widgets/flashcard_widget.dart';
import '../widgets/fab_menu.dart';
import '../widgets/progress_bar.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/quick_edit_card_dialog.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // === Services ===
  late DatabaseService _databaseService;
  final CardDisplayService _cardDisplayService = CardDisplayService.instance;
  final SpacedRepetitionService _spacedRepetitionService = SpacedRepetitionService();
  
  // === UI State Management ===
  final GlobalKey<FabMenuState> _fabMenuKey = GlobalKey<FabMenuState>();
  List<Flashcard> _currentCards = [];
  int _currentCardIndex = 0;
  bool _isLoading = false;
  bool _showAnswer = false;
  int _currentCategoryId = 0;
  bool _isReviewMode = false;
  List<Flashcard> _originalDeck = []; // Store original deck when entering review mode
  
  // === Progress Tracking ===
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  
  // === Previous Card History ===
  List<Map<String, dynamic>> _cardHistory = []; // List of {index, answer} maps
  
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
  
  // === Debouncing ===
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _loadInitialCards();
    _cardDisplayService.loadSettings();
    
    // Initialize animation controllers
    _swipeAnimationController = AnimationController(
      duration: AnimationConstants.swipeDuration,
      vsync: this,
    );
    
    // Initialize background photo service
    BackgroundPhotoService.instance.initialize();
    
    // Listen to theme changes
    ThemeService().addListener(_onThemeChanged);
    
    // Listen to background photo changes
    BackgroundPhotoService.instance.addListener(_onBackgroundPhotoChanged);
    
    // Clean up any orphaned cards on app start
    _cleanupOrphanedCards();
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _debounceTimer?.cancel();
    // Remove theme change listener
    ThemeService().removeListener(_onThemeChanged);
    
    // Remove background photo change listener
    BackgroundPhotoService.instance.removeListener(_onBackgroundPhotoChanged);
    
    super.dispose();
  }

  /// Clean up orphaned cards that no longer exist in the main Card table
  Future<void> _cleanupOrphanedCards() async {
    try {
      final deletedCount = await _databaseService.cleanupOrphanedCards();
      if (deletedCount > 0) {
        // Cleaned up $deletedCount orphaned cards from IncorrectCards table
      }
    } catch (e) {
      // Error cleaning up orphaned cards: $e
    }
  }

  /// Load initial cards by finding the first available category with cards
  Future<void> _loadInitialCards() async {
    setState(() => _isLoading = true);
    try {
      // Find a category that has cards to load initially
      final categories = await _databaseService.getCategoryTree();
      
      if (categories.isNotEmpty) {
        // Look for the first category that has cards
        Category? defaultCategory;
        for (final category in categories) {
          if (category.isCardCategory && category.cardCount > 0) {
            defaultCategory = category;
            break;
          }
        }
        
        if (defaultCategory != null) {
          final cards = await _databaseService.getCardsByCategory(defaultCategory.id);
          setState(() {
            _currentCards = cards;
            _currentCardIndex = 0;
            _showAnswer = false; // Reset answer visibility for new cards
            _cardHistory.clear(); // Clear card history
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Load cards for a specific category when selected from navigation
  Future<void> _loadCardsForCategory(int categoryId) async {
    setState(() => _isLoading = true);
    try {
      final cards = await _databaseService.getCardsByCategory(categoryId);
      
      setState(() {
        _currentCards = cards;
        _currentCardIndex = 0;
        _correctAnswers = 0;
        _totalAnswers = 0;
        _showAnswer = false; // Reset answer visibility for new cards
        _cardHistory.clear(); // Clear card history
        _isLoading = false;
        _currentCategoryId = categoryId;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Records an answer (correct/incorrect) and advances to the next card.
  void _recordAnswer({required bool isCorrect}) async {
    final currentCard = _getCurrentFlashcard();
    
    // Handle spaced repetition tracking
    if (currentCard.id > 0) {
      try {
        // Get or create spaced repetition data for this card
        SpacedRepetitionCard? spacedCard = await _databaseService.getSpacedRepetitionCard(
          currentCard.id,
          currentCard.categoryId,
        );
        
        if (spacedCard == null) {
          // Create new spaced repetition card
          spacedCard = _spacedRepetitionService.createNewCard(
            currentCard.id,
            currentCard.categoryId,
          );
        }
        
        // Calculate next review based on performance
        final updatedCard = _spacedRepetitionService.calculateNextReview(
          spacedCard,
          isCorrect,
        );
        
        // Save updated spaced repetition data
        await _databaseService.upsertSpacedRepetitionCard(updatedCard);
        
      } catch (e) {
        // Handle error silently - don't interrupt the user experience
      }
    }
    
    // Track incorrect cards for review system (legacy system)
    if (!isCorrect && currentCard.id > 0) {
      try {
        await _databaseService.markCardIncorrect(
          currentCard.id,
          currentCard.categoryId,
          currentCard.categoryName ?? 'Unknown Category',
        );
      } catch (e) {
        // Handle error silently - don't interrupt the user experience
      }
    } else if (isCorrect && currentCard.id > 0) {
      try {
        // Remove from incorrect cards if it was previously marked incorrect
        await _databaseService.markCardCorrect(
          currentCard.id,
          currentCard.categoryId,
        );
      } catch (e) {
        // Handle error silently
      }
    }
    
    setState(() {
      // Add current card to history before advancing
      _cardHistory.add({
        'index': _currentCardIndex,
        'answer': isCorrect,
      });
      
      _correctAnswers += isCorrect ? 1 : 0;
      _totalAnswers++;
      _advanceToNextCard();
    });
  }

  /// Skips the current card without recording an answer.
  void _skipCard() {
    setState(() {
      // Add current card to history before advancing
      _cardHistory.add({
        'index': _currentCardIndex,
        'answer': null, // null indicates skip
      });
      
      _advanceToNextCard();
    });
  }

  /// Goes back to the previous card and undoes the last answer.
  void _goBackToPreviousCard() {
    if (_cardHistory.isEmpty) {
      return; // No previous cards to go back to
    }
    
    // Get the last entry from history
    final lastEntry = _cardHistory.removeLast();
    final previousIndex = lastEntry['index'] as int;
    final previousAnswer = lastEntry['answer'] as bool?;
    
    setState(() {
      // Undo the previous answer from statistics
      if (previousAnswer != null) {
        _correctAnswers -= previousAnswer ? 1 : 0;
        _totalAnswers--;
      }
      
      // Go back to previous card
      _currentCardIndex = previousIndex;
      _showAnswer = false; // Reset answer visibility
    });
    
    // Return card to center position after going back
    _returnCardToCenter();
  }

  /// Advance to the next card (helper function)
  void _advanceToNextCard() {
    _currentCardIndex++;
    _showAnswer = false; // Reset answer visibility for new card
  }

  /// Get the current flashcard or empty placeholder
  Flashcard _getCurrentFlashcard() {
    if (_currentCards.isEmpty) {
      return Flashcard(id: 0, kana: '', english: '', categoryId: 0);
    }
    // When deck is completed, return the last card for completion display
    if (_currentCardIndex >= _currentCards.length) {
      return _currentCards.last;
    }
    return _currentCards[_currentCardIndex];
  }

  /// Check if deck is completed
  bool _isDeckCompleted() {
    return _currentCards.isEmpty || _currentCardIndex >= _currentCards.length;
  }

  double _getCorrectPercentage() {
    if (_currentCards.isEmpty) return 0.0;
    final correctCount = _currentCards.length - _currentCardIndex;
    return (correctCount / _currentCards.length) * 100;
  }
  
  void _closeFabMenu() {
    _fabMenuKey.currentState?.closeMenu();
  }

  void _shuffleCards() {
    if (_currentCards.length > 1) {
    setState(() {
        _currentCards.shuffle();
          _currentCardIndex = 0;
          _showAnswer = false;
        });
    }
  }

  void _resetCards() {
    setState(() {
        _currentCardIndex = 0;
        _showAnswer = false;
    });
  }
  
  void _showEditCardDialog() async {
    if (_currentCards.isEmpty) return;
    
    final currentCard = _getCurrentFlashcard();
    final latestCard = await _databaseService.getCardById(currentCard.id);
    if (latestCard == null) return;
    
    showDialog(
      context: context,
      builder: (context) => QuickEditCardDialog(
        card: latestCard,
        onCardUpdated: () {
          _refreshCurrentCards();
        },
        ),
    );
  }

  Future<void> _refreshCurrentCards() async {
    if (_currentCards.isEmpty) return;
    
    try {
      final categoryId = _currentCards.first.categoryId;
      final refreshedCards = await _databaseService.getCardsByCategory(categoryId);
    
    setState(() {
        _currentCards = refreshedCards;
    if (_currentCardIndex >= _currentCards.length) {
          _currentCardIndex = _currentCards.length - 1;
        }
        _showAnswer = false;
      });
    } catch (e) {
      // Continue with existing cards
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
    
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      drawer: KaadoNavigationDrawer(
        databaseService: _databaseService,
        onCategorySelected: _loadCardsForCategory,
        onResetDatabase: () {
          _loadInitialCards();
        },
        onThemeChanged: (themeMode) => _onThemeChangedFromDrawer(themeMode),
        onCloseFab: _closeFabMenu,
      ),
      appBar: AppBar(
        backgroundColor: appTheme.appBarBackground,
        foregroundColor: appTheme.appBarIcon,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: appTheme.appBarIcon),
            onPressed: () {
              _closeFabMenu();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          _isReviewMode ? AppStrings.reviewMode : AppStrings.appName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: appTheme.appBarIcon,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _closeFabMenu,
            child: Column(
          children: [
            // Progress Section (fixed at top)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
              child: ProgressBar(
                progressText: _currentCards.isEmpty ? '0/0' : '${_currentCardIndex + 1}/${_currentCards.length}',
                scoreText: _currentCards.isEmpty ? 'No Cards' : '${_getCorrectPercentage().toInt()}% Correct',
                progressValue: _currentCards.isEmpty ? 0.0 : _currentCardIndex / _currentCards.length,
                isCompleted: _currentCards.isEmpty || _currentCardIndex >= _currentCards.length,
              ),
            ),

            SizedBox(height: AppSizes.spacingMedium),

            // Card and Review Section Container with proper z-index
            Stack(
              children: [
                Column(
                  children: [
                    // Card space placeholder
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                    ),

                    SizedBox(height: 8.0),

                    // Incorrect Cards Review Row (behind the card)
                FutureBuilder<int>(
                  future: _getIncorrectCardsCount(),
                  builder: (context, snapshot) {
                    final incorrectCount = snapshot.data ?? 0;
                    if (incorrectCount > 0 && !_isReviewMode) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                        child: Container(
                          margin: EdgeInsets.only(top: 4.0), // Close to main card
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0, // Using v10.2 reviewSectionPaddingHorizontal
                            vertical: 12.0    // Using v10.2 reviewSectionPaddingVertical
                          ),
                          decoration: BoxDecoration(
                            color: appTheme.cardBackground.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12.0), // Using v10.2 reviewSectionBorderRadius
                            border: Border.all(color: appTheme.divider, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: appTheme.secondaryText,
                                size: 20,
                              ),
                              SizedBox(width: AppSizes.spacingSmall),
                              Expanded(
                                child: Text(
                                  '$incorrectCount card${incorrectCount == 1 ? '' : 's'} wrong',
                                  style: TextStyle(
                                    color: appTheme.secondaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _closeFabMenu();
                                  _startIncorrectCardsReview();
                                },
                                child: Text(
                                  'Review',
                                  style: TextStyle(
                                    color: appTheme.buttonTextOnColored,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: appTheme.buttonTextOnColored,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0, // Using v10.2 reviewButtonPaddingHorizontal
                                    vertical: 8.0     // Using v10.2 reviewButtonPaddingVertical
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0), // Using v10.2 reviewButtonBorderRadius
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

                // Spaced Repetition Review Row (for cards due for review)
                if (!_isReviewMode && _currentCategoryId > 0)
                  FutureBuilder<Map<String, int>>(
                    future: _getSpacedRepetitionStats(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {};
                      final reviewCount = stats['review'] ?? 0;
                      final overdueCount = stats['overdue'] ?? 0;
                      final totalDue = reviewCount + overdueCount;
                      
                      if (totalDue > 0) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                          child: Container(
                            margin: EdgeInsets.only(top: 4.0), // Close to main card
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0, // Using v10.2 reviewSectionPaddingHorizontal
                              vertical: 12.0    // Using v10.2 reviewSectionPaddingVertical
                            ),
                            decoration: BoxDecoration(
                              color: appTheme.cardBackground.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12.0), // Using v10.2 reviewSectionBorderRadius
                              border: Border.all(color: appTheme.divider, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: theme.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: AppSizes.spacingSmall),
                                Expanded(
                                  child: Text(
                                    '$totalDue card${totalDue == 1 ? '' : 's'} due',
                                    style: TextStyle(
                                      color: appTheme.secondaryText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _closeFabMenu();
                                    _startSpacedRepetitionReview();
                                  },
                                  child: Text(
                                    'Review',
                                    style: TextStyle(
                                      color: appTheme.buttonTextOnColored,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: appTheme.buttonTextOnColored,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, // Using v10.2 reviewButtonPaddingHorizontal
                                      vertical: 8.0     // Using v10.2 reviewButtonPaddingVertical
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0), // Using v10.2 reviewButtonBorderRadius
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),

                // Back to Deck button (when in review mode)
                if (_isReviewMode)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                    child: Container(
                      margin: EdgeInsets.only(top: 4.0), // Close to main card
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0, // Using v10.2 mediumSpacing
                        vertical: 12.0    // Using v10.2 mediumSpacing
                      ),
                      decoration: BoxDecoration(
                        color: colors.cardBackground.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12.0), // Using v10.2 reviewSectionBorderRadius
                        border: Border.all(color: colors.divider, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Reviewing incorrect cards',
                              style: TextStyle(
                                color: appTheme.secondaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _closeFabMenu();
                              _backToOriginalDeck();
                            },
                            child: Text(
                              'Back',
                              style: TextStyle(
                                color: colors.buttonTextOnColored,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryBlue,
                              foregroundColor: colors.buttonTextOnColored,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0, // Using v10.2 reviewButtonPaddingHorizontal
                                vertical: 8.0     // Using v10.2 reviewButtonPaddingVertical
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0), // Using v10.2 reviewButtonBorderRadius
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
                
                // Positioned card (above review boxes)
                Positioned(
                  top: 0,
                  left: AppSizes.paddingLarge,
                  right: AppSizes.paddingLarge,
                  child: _isLoading 
                    ? _buildLoadingCard()
                    : _currentCards.isEmpty 
                      ? _buildBlankCardPlaceholder()
                      : _buildCard()
                ),
              ],
            ),


            // Spacer to push content to bottom
            Spacer(),
            
            // Swipe instructions - at the very bottom
            if (_currentCards.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: AppSizes.paddingLarge,
                  right: AppSizes.paddingLarge,
                  bottom: 20, // Small space above bottom navigation
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSwipeHint(AppStrings.swipeLeft, AppStrings.incorrect, appTheme.incorrectButton),
                    _buildSwipeHint(AppStrings.swipeUp, AppStrings.skip, appTheme.skipButton),
                    _buildSwipeHint(AppStrings.swipeDown, AppStrings.back, appTheme.actionButtonBackground),
                    _buildSwipeHint(AppStrings.swipeRight, AppStrings.correct, appTheme.correctButton),
                  ],
                ),
              ),
          ],
            ),
          ),
          
          // FAB positioned following Material Design guidelines
          Positioned(
            bottom: 80, // Above the swipe hints
            right: 16, // Standard Material Design FAB margin from edge
            child: FabMenu(
              key: _fabMenuKey,
              onShuffle: _shuffleCards,
              onReset: _isReviewMode ? _backToOriginalDeck : _resetCards,
              isEnabled: _currentCards.isNotEmpty,
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  /// Build the card widget - always the same structure
  Widget _buildCard() {
    final cardWidget = FlashcardWidget(
      flashcard: _getCurrentFlashcard(),
      showAnswer: _showAnswer,
      isCompleted: _isDeckCompleted(),
      onTap: _isDeckCompleted() ? _resetCards : _toggleAnswer,
      onEdit: _showEditCardDialog,
    );

    return _buildSwipeableCard(cardWidget);
  }

  /// Build the swipeable card with drag animations - wraps the static card widget
  Widget _buildSwipeableCard(Widget cardWidget) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: _isDeckCompleted() ? _resetCards : _toggleAnswer,
      behavior: HitTestBehavior.deferToChild,
        child: Transform.translate(
          offset: _dragOffset,
          child: Transform.rotate(
          angle: _dragOffset.dx * 0.0003, // Very subtle rotation like reference
            child: AnimatedOpacity(
            opacity: _hasReachedThreshold ? 0.7 : 1.0,
            duration: Duration(milliseconds: 200),
              child: cardWidget,
            ),
          ),
        ),
    );
  }

  /// Toggle the answer visibility on the current card and close the FAB menu
  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
    _closeFabMenu();
  }

  Widget _buildSwipeHint(String direction, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          direction,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Future<int> _getIncorrectCardsCount() async {
    return await _databaseService.getTotalIncorrectCards();
  }
  
  Future<Map<String, int>> _getSpacedRepetitionStats() async {
    return await _databaseService.getReviewStatsForCategory(_currentCategoryId);
  }
  
  void _startIncorrectCardsReview() async {
    // Load incorrect cards for the current category
    final incorrectCards = await _databaseService.getIncorrectCardsForCategory(_currentCategoryId);
    
    if (incorrectCards.isNotEmpty) {
      setState(() {
        _isReviewMode = true;
        _currentCards = incorrectCards;
        _currentCardIndex = 0;
        _showAnswer = false;
      });
    }
  }
  
  void _startSpacedRepetitionReview() {
    // TODO: Implement spaced repetition review
  }
  
  void _backToOriginalDeck() async {
    // Load the original cards for the current category
    final originalCards = await _databaseService.getCardsByCategory(_currentCategoryId);
    
    setState(() {
      _isReviewMode = false;
      _currentCards = originalCards;
      _currentCardIndex = 0;
      _showAnswer = false;
    });
  }
  
  
  /// Handle card tap to flip
  void _onCardTap() {
    if (_isDeckCompleted()) {
      _resetCards();
    } else {
      setState(() {
        _showAnswer = !_showAnswer;
      });
    }
  }

  /// Handle pan start
  void _onPanStart(DragStartDetails details) {
    if (_currentCards.isEmpty || _isAnimationBlocked) return;
    
    _closeFabMenu(); // Close FAB when starting to swipe
    
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _hasReachedThreshold = false;
    });
  }

  /// Handle pan update - Tinder-like drag handling
  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentCards.isEmpty || !_isDragging || _isAnimationBlocked) return;
    
    final delta = details.globalPosition - _dragStartPosition;
    final absDx = delta.dx.abs();
    final absDy = delta.dy.abs();
    
    setState(() {
      if (absDx > absDy) {
        // Primarily horizontal movement
        _dragOffset = Offset(delta.dx, 0);
        
        // Check threshold based on drag distance
        if (absDx >= _maxDragDistance * _thresholdValue && !_hasReachedThreshold) {
          _hasReachedThreshold = true;
          HapticFeedback.mediumImpact();
        }
      } else {
        // Primarily vertical movement (up for skip, down for back)
        _dragOffset = Offset(0, delta.dy);
        
        // Check threshold for vertical swipes
        if (absDy >= _maxDragDistance * _thresholdValue && !_hasReachedThreshold) {
          if (delta.dy < 0) {
            // Swipe up - skip
            _hasReachedThreshold = true;
            HapticFeedback.mediumImpact();
          } else if (delta.dy > 0 && _cardHistory.isNotEmpty) {
            // Swipe down - go back (only if there's history)
            _hasReachedThreshold = true;
            HapticFeedback.mediumImpact();
          }
        }
      }
    });
  }

  /// Handle pan end - determine swipe action with improved logic
  void _onPanEnd(DragEndDetails details) {
    if (_currentCards.isEmpty || !_isDragging || _isAnimationBlocked) return;
    
    setState(() {
      _isDragging = false;
    });
    
    final velocity = details.velocity.pixelsPerSecond;
    final dragDistance = _dragOffset.distance;
    
    // Check if swipe was far enough or fast enough
    final isSwipeFarEnough = dragDistance >= _maxDragDistance * 0.3; // Lower threshold
    final isSwipeFastEnough = velocity.distance > 500; // Fast swipe
    
    if (isSwipeFarEnough || isSwipeFastEnough) {
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
    final isLastCard = _currentCardIndex >= _currentCards.length - 1;
    
    if (absDx > absDy) {
      // Horizontal swipe
      if (delta.dx > 0) {
        // Swipe right - correct
        _recordAnswer(isCorrect: true);
        _animateCardExit(true);
      } else {
        // Swipe left - incorrect
        _recordAnswer(isCorrect: false);
        _animateCardExit(false);
      }
    } else {
      // Vertical swipe
      if (delta.dy < 0) {
        // Swipe up - skip
        if (isLastCard) {
          _skipCard();
        } else {
          _animateCardExit(null);
          _skipCard();
        }
      } else {
        // Swipe down - go back to previous card
        if (_cardHistory.isNotEmpty) {
          _goBackToPreviousCard();
        } else {
          // No previous card - return to center
          _returnCardToCenter();
        }
      }
    }
  }

  /// Animate card exit in the swipe direction
  void _animateCardExit(bool? isCorrect) {
    setState(() {
      _isAnimationBlocked = true;
    });
    
    // Determine exit direction and distance
    final screenWidth = MediaQuery.of(context).size.width;
    final exitDistance = screenWidth * 1.5; // Exit far off screen
    
    Offset exitOffset;
    if (isCorrect == true) {
      // Swipe right for correct
      exitOffset = Offset(exitDistance, _dragOffset.dy);
    } else if (isCorrect == false) {
      // Swipe left for incorrect
      exitOffset = Offset(-exitDistance, _dragOffset.dy);
    } else {
      // Skip - exit up
      exitOffset = Offset(_dragOffset.dx, -exitDistance);
    }
    
    // Animate to exit position
    _animateToPosition(exitOffset, Duration(milliseconds: 300)).then((_) {
      _resetCardPosition();
      setState(() {});
    });
  }

  /// Return card to center position
  void _returnCardToCenter() {
    setState(() {
      _isAnimationBlocked = true;
    });
    
    // Animate back to center with spring-like animation
    _animateToPosition(Offset.zero, Duration(milliseconds: 400)).then((_) {
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
      
      // Use a smooth easing curve (ease-out)
      final easedProgress = 1.0 - math.pow(1.0 - progress, 3);
      
      setState(() {
        _dragOffset = Offset.lerp(startOffset, targetOffset, easedProgress)!;
      });
      
      await Future.delayed(Duration(milliseconds: 16)); // ~60fps
    }
    
    // Ensure we end exactly at the target
    setState(() {
      _dragOffset = targetOffset;
    });
  }

  /// Reset card position after animation
  void _resetCardPosition() {
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
      _hasReachedThreshold = false;
      _isAnimationBlocked = false;
    });
  }

  /// Reset all animations
  void _resetAllAnimations() {
    _resetCardPosition();
  }
  
  
  /// Build blank card placeholder
  Widget _buildBlankCardPlaceholder() {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.3, // Same height as normal cards
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: AppSizes.shadowBlurMedium,
            offset: Offset(0, AppSizes.shadowOffsetSmall),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No cards available',
              style: TextStyle(
                fontSize: AppSizes.fontXLarge,
                color: appTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              'Add cards to get started',
              style: TextStyle(
                fontSize: AppSizes.fontMedium,
                color: appTheme.secondaryText,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading card
  Widget _buildLoadingCard() {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: AppSizes.shadowBlurMedium,
            offset: Offset(0, AppSizes.shadowOffsetSmall),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      ),
    );
  }

  /// Theme change handler
  void _onThemeChanged() {
    setState(() {});
  }
  
  /// Background photo change handler
  void _onBackgroundPhotoChanged() {
    setState(() {});
  }
  
  /// Theme change handler from drawer
  void _onThemeChangedFromDrawer(AppThemeMode theme) {
    // Update the theme service and colors
    ThemeService().setTheme(theme);
    // Force a complete rebuild to apply the new theme
    setState(() {
      // The theme change will be picked up by ThemeColors.instance
      // which will automatically update all colors
    });
  }
  
  /// Card swipe vibration handler
  void _onCardSwipeVibration() {
    HapticFeedback.mediumImpact();
  }
  
  /// Load current category
  Future<void> _loadCurrentCategory() async {
    if (_currentCategoryId > 0) {
      await _loadCardsForCategory(_currentCategoryId);
    }
  }
  
  /// Get current category name
  String get _currentCategoryName {
    // This would need to be tracked separately or retrieved from database
    return 'Current Category';
  }
}

// Dart imports
import 'dart:async';
import 'dart:math' as math;

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports - Models
import '../models/flashcard.dart';
import '../models/category.dart' as app_models;
import '../models/spaced_repetition.dart';
import '../models/user_progress.dart';

// Project imports - Services
import '../services/database_service.dart';
import '../services/app_logger.dart';
import '../services/card_display_service.dart';
import '../services/theme_service.dart';
import '../services/background_photo_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/srs_algorithm.dart';

// Project imports - Screens
import 'card_display_settings_screen.dart';
import 'spaced_repetition_settings_screen.dart';

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
  int _correctAnswers = 0; // Track correct answers
  int _totalAttempts = 0; // Track actual attempts (not including skips)
  bool _isLoading = false;
  bool _showAnswer = false;
  int _currentCategoryId = 0;
  bool _isReviewMode = false;
  // Note: _showReviewPrompt is now determined by database query results // Show review prompt after left swipe
  
  // Review-specific score tracking
  int _reviewCorrectAnswers = 0;
  int _reviewTotalAttempts = 0;
  
  // Note: Incorrect cards are now stored in the IncorrectCards database table
  
  // === Previous Card History ===
  final List<Map<String, dynamic>> _cardHistory = []; // List of {index, answer} maps
  
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
    
    // Initialize app asynchronously to avoid blocking main thread
    _initializeAppAsync();
  }

  /// Initialize app components asynchronously to prevent main thread blocking
  Future<void> _initializeAppAsync() async {
    try {
      // Ensure database is fully initialized first
      await _databaseService.ensureDatabaseInitialized();
      
      // Load settings first (lightweight operation)
      _cardDisplayService.getDisplaySettings();
      
      // Clean up orphaned cards in background
      _cleanupOrphanedCards();
      
      // Load initial cards in background
      await _loadInitialCards();
    } catch (e) {
      AppLogger.error('Error initializing app: $e');
      setState(() => _isLoading = false);
    }
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
      // Use compute to run database operations in background
      final result = await _loadCardsInBackground();
      
      if (result != null) {
        setState(() {
          _currentCards = result['cards'] as List<Flashcard>;
          _currentCardIndex = 0;
          _correctAnswers = 0; // Reset correct answers count
          _totalAttempts = 0; // Reset attempts count
          _showAnswer = false; // Reset answer visibility for new cards
          _cardHistory.clear(); // Clear card history
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error loading initial cards: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Load cards in background thread to prevent main thread blocking
  Future<Map<String, dynamic>?> _loadCardsInBackground() async {
    try {
      // Find a category that has cards to load initially using database thread service
      final categories = await _databaseService.getCategoryTree();
      
      if (categories.isNotEmpty) {
        // Look for the first category that has cards
        app_models.Category? defaultCategory;
        for (final category in categories) {
          if (category.isCardCategory && category.cardCount > 0) {
            defaultCategory = category;
            break;
          }
        }
        
        if (defaultCategory != null) {
          final cards = await _databaseService.getCardsByCategory(defaultCategory.id);
          return {'cards': cards};
        }
      }
      return null;
    } catch (e) {
      AppLogger.error('Error in background card loading: $e');
      return null;
    }
  }

  /// Load cards for a specific category when selected from navigation
  Future<void> _loadCardsForCategory(int categoryId) async {
    setState(() => _isLoading = true);
    try {
      List<Flashcard> cards;
      
      // Check if this is the Favorites deck by getting the category name
      final category = await _databaseService.getCategoryById(categoryId);
      if (category != null && category.name.toLowerCase() == 'favorites') {
        // Special case for Favorites - use getFavoriteCards
        cards = await _databaseService.getFavoriteCards();
      } else {
        // Use getCardsByCategory for regular decks
        cards = await _databaseService.getCardsByCategory(categoryId);
      }
      
      setState(() {
        _currentCards = cards;
        _currentCardIndex = 0;
        _correctAnswers = 0; // Reset correct answers count
        _totalAttempts = 0; // Reset attempts count
        _showAnswer = false; // Reset answer visibility for new cards
        _cardHistory.clear(); // Clear card history
        _isLoading = false;
        _currentCategoryId = categoryId;
        // Note: Review prompt visibility is now determined by database query
        
        // Exit review mode when navigating to a different deck
        if (_isReviewMode) {
          _isReviewMode = false;
          _reviewCorrectAnswers = 0;
          _reviewTotalAttempts = 0;
        }
      });
      
      // Note: Review prompt visibility is now determined by database query in UI
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
        
        spacedCard ??= _spacedRepetitionService.createNewCard(
            currentCard.id,
            currentCard.categoryId,
          );
        
        // Calculate next review based on performance
        final updatedCard = _spacedRepetitionService.calculateNextReview(
          spacedCard,
          isCorrect,
        );
        
        // Save updated spaced repetition data
        await _databaseService.upsertSpacedRepetitionCard(updatedCard);
        
    // If answered correctly, mark as correct in database (regardless of mode)
    if (isCorrect) {
          
          // Mark card as correct in database
          await _databaseService.markCardCorrectInDatabase(currentCard.id);
          
          // Update UI to reflect the change
          setState(() {
            // Update progress counters
            if (!_isReviewMode) {
              _correctAnswers++;
              _totalAttempts++;
            } else {
              _reviewCorrectAnswers++;
              _reviewTotalAttempts++;
            }
          });
        }
        
      } catch (e) {
        AppLogger.error('Error in spaced repetition tracking: $e');
        // Handle error silently - don't interrupt the user experience
      }
    }
    
    // Track incorrect cards for review system
    if (!isCorrect && currentCard.id > 0) {
      try {
        if (_isInFavoritesDeck()) {
          // For Favorites deck, mark as incorrect in the original deck
          await _databaseService.markCardIncorrectInDatabase(currentCard.id, currentCard.categoryId);
        } else {
          // For regular decks, use the normal logic
          await _databaseService.markCardIncorrect(
            currentCard.id,
            currentCard.categoryId,
            currentCard.categoryName ?? 'Unknown Category',
          );
        }
      } catch (e) {
        // Handle error silently - don't interrupt the user experience
      }
    } else if (isCorrect && currentCard.id > 0) {
      try {
        if (_isInFavoritesDeck()) {
          // For Favorites deck, mark as correct in the original deck
          await _databaseService.markCardCorrectInDatabase(currentCard.id);
        } else {
          // For regular decks, use the normal logic
          await _databaseService.markCardCorrect(
            currentCard.id,
            currentCard.categoryId,
          );
        }
      } catch (e) {
        // Handle error silently
      }
    }
    
    setState(() {
      // Track score based on mode
      if (_isReviewMode) {
        // Review mode: use review-specific tracking
        _reviewTotalAttempts++;
        if (isCorrect) {
          _reviewCorrectAnswers++;
        }
      } else {
        // Main deck: use main deck tracking
        _totalAttempts++;
        if (isCorrect) {
          _correctAnswers++;
        }
      }
      
      // Add current card to history before advancing
      _cardHistory.add({
        'index': _currentCardIndex,
        'answer': isCorrect,
      });
      
      _advanceToNextCard();
    });
    
    // Note: Swipe operation flag will be cleared by _completeSwipeAction when animation completes
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
    
    // Note: Swipe operation flag will be cleared by _animateCardExit() after animation completes
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
        // This was an attempt (not a skip), so decrement attempts
        _totalAttempts = (_totalAttempts - 1).clamp(0, _currentCardIndex);
        if (previousAnswer == true) {
          _correctAnswers = (_correctAnswers - 1).clamp(0, _totalAttempts);
        }
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
    if (_currentCards.isEmpty || _totalAttempts == 0) return 0.0;
    return (_correctAnswers / _totalAttempts) * 100;
  }
  
  double _getReviewCorrectPercentage() {
    if (_currentCards.isEmpty || _reviewTotalAttempts == 0) return 0.0;
    return (_reviewCorrectAnswers / _reviewTotalAttempts) * 100;
  }
  
  void _closeFabMenu() {
    _fabMenuKey.currentState?.closeMenu();
  }
  
  /// Exit review mode and return to main deck
  void _exitReviewMode() {
    
    setState(() {
      _isReviewMode = false;
      _reviewCorrectAnswers = 0;
      _reviewTotalAttempts = 0;
    });
    
    // Check if there are still incorrect cards in database
    _checkForRemainingIncorrectCards();
  }

  void _shuffleCards() {
    if (_currentCards.length > 1) {
    setState(() {
        _currentCards.shuffle();
          _currentCardIndex = 0;
          _correctAnswers = 0; // Reset correct answers count
        _totalAttempts = 0; // Reset attempts count
          _showAnswer = false;
          _cardHistory.clear(); // Clear card history
        });
    }
  }

  void _resetCards() {
    setState(() {
        _currentCardIndex = 0;
        _correctAnswers = 0; // Reset correct answers count
        _totalAttempts = 0; // Reset attempts count
        _showAnswer = false;
        _cardHistory.clear(); // Clear card history
    });
  }
  
  void _showEditCardDialog() async {
    if (_currentCards.isEmpty) return;
    
    final currentCard = _getCurrentFlashcard();
    final latestCard = await _databaseService.getCardById(currentCard.id);
    if (latestCard == null || !mounted) return;
    
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
      List<Flashcard> refreshedCards;
      
      // Check if this is the Favorites deck
      final category = await _databaseService.getCategoryById(categoryId);
      if (category != null && category.name.toLowerCase() == 'favorites') {
        refreshedCards = await _databaseService.getFavoriteCards();
      } else {
        refreshedCards = await _databaseService.getCardsByCategory(categoryId);
      }
      
      if (refreshedCards.isNotEmpty) {
      }
    
    setState(() {
        _currentCards = refreshedCards;
    if (_currentCardIndex >= _currentCards.length) {
          _currentCardIndex = _currentCards.length - 1;
        }
        // Preserve the current flip state instead of resetting to false
      });
    } catch (e) {
      // Continue with existing cards
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
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
        onTriggerIncorrectCardsReview: _startIncorrectCardsReview,
        onTriggerSpacedRepetitionReview: _startSpacedRepetitionReview,
      ),
      appBar: AppBar(
        backgroundColor: appTheme.appBarBackground,
        foregroundColor: appTheme.appBarIcon,
        elevation: 0,
        leading: _isReviewMode 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: appTheme.appBarIcon),
              onPressed: () {
                _exitReviewMode();
              },
            )
          : Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: appTheme.appBarIcon),
                onPressed: () {
                  _closeFabMenu();
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
        title: Text(
          _isReviewMode ? AppStrings.reviewMode : _getCurrentCategoryTitle(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: appTheme.appBarIcon,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: appTheme.appBarIcon),
            onSelected: (value) {
              switch (value) {
                case 'card_settings':
                  _openCardDisplaySettings();
                  break;
                case 'spaced_repetition':
                  _openSpacedRepetitionSettings();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'card_settings',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: appTheme.primaryText),
                    SizedBox(width: 8),
                    Text('Card Display Settings'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'spaced_repetition',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: appTheme.primaryText),
                    SizedBox(width: 8),
                    Text('Spaced Repetition Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                progressText: _currentCards.isEmpty ? '0/0' : '${math.min(_currentCardIndex + 1, _currentCards.length)}/${_currentCards.length}',
                scoreText: _currentCards.isEmpty ? 'No Cards' : _isReviewMode ? '${_getReviewCorrectPercentage().toInt()}% Correct' : '${_getCorrectPercentage().toInt()}% Correct',
                progressValue: _currentCards.isEmpty ? 0.0 : math.min(_currentCardIndex / _currentCards.length, 1.0),
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
                      height: MediaQuery.of(context).size.height * 0.3,
                    ),

                    SizedBox(height: 8.0),

                    // Incorrect Cards Review Row (behind the card)
                    if (!_isReviewMode)
                      FutureBuilder<int>(
                        future: _getIncorrectCardsCountFromDatabase(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data! > 0) {
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
                                        '${snapshot.data} card${snapshot.data == 1 ? '' : 's'} wrong',
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
                                      child: Text(
                                        'Review',
                                        style: TextStyle(
                                          color: appTheme.buttonTextOnColored,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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
                                  child: Text(
                                    'Review',
                                    style: TextStyle(
                                      color: appTheme.buttonTextOnColored,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                        color: appTheme.cardBackground.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12.0), // Using v10.2 reviewSectionBorderRadius
                        border: Border.all(color: appTheme.divider, width: 1),
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
                            child: Text(
                              'Back',
                              style: TextStyle(
                                color: appTheme.buttonTextOnColored,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
  }

  /// Build the card widget - always the same structure
  Widget _buildCard() {
    final cardWidget = FlashcardWidget(
      flashcard: _getCurrentFlashcard(),
      showAnswer: _showAnswer,
      isCompleted: _isDeckCompleted(),
      onTap: _isDeckCompleted() ? _resetCards : _toggleAnswer,
      onEdit: _showEditCardDialog,
      onToggleFavorite: _toggleFavorite,
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
  
  // Note: _hasIncorrectCardsInDatabase method removed - now using _getIncorrectCardsCountFromDatabase
  
  /// Get count of incorrect cards for current deck from database
  Future<int> _getIncorrectCardsCountFromDatabase() async {
    try {
      // For Favorites deck, we need to get incorrect cards from the original decks
      if (_isInFavoritesDeck()) {
        // Get all favorite cards and check which ones are marked incorrect in their original decks
        final favoriteCards = await _databaseService.getFavoriteCards();
        int incorrectCount = 0;
        for (final card in favoriteCards) {
          // Check if this card is marked incorrect in its original deck
          final originalDeckId = card.categoryId;
          if (originalDeckId > 0) {
            final incorrectCards = await _databaseService.getIncorrectCardsFromDatabase(originalDeckId);
            if (incorrectCards.contains(card.id)) {
              incorrectCount++;
            }
          }
        }
        return incorrectCount;
      } else {
        // For regular decks, use the normal logic
        final incorrectCards = await _databaseService.getIncorrectCardsFromDatabase(_currentCategoryId);
        return incorrectCards.length;
      }
    } catch (e) {
      AppLogger.error('Error getting incorrect cards count: $e');
      return 0;
    }
  }
  
  /// Check for remaining incorrect cards and exit review mode if none
  Future<void> _checkForRemainingIncorrectCards() async {
    try {
      final incorrectCards = await _databaseService.getIncorrectCardsFromDatabase(_currentCategoryId);
      
      if (incorrectCards.isEmpty) {
        // Don't automatically exit review mode - let user manually return to main deck
        // This allows the user to try again and again until satisfied
      }
    } catch (e) {
      AppLogger.error('Error checking remaining incorrect cards: $e');
    }
  }
  
  // Note: _getIncorrectCardsCount method removed - now using _getIncorrectCardsCountFromDatabase

  String _getCurrentCategoryTitle() {
    if (_currentCategoryId == 0) {
      return AppStrings.appName;
    } else {
      if (_currentCards.isNotEmpty) {
        return _currentCards.first.categoryName ?? AppStrings.appName;
      }
      return AppStrings.appName;
    }
  }
  
  Future<Map<String, int>> _getSpacedRepetitionStats() async {
    return await _databaseService.getReviewStatsForCategory(_currentCategoryId);
  }
  
  void _startIncorrectCardsReview() async {
    // Prevent multiple simultaneous calls
    if (_isReviewMode) {
      return;
    }
    
    try {
      List<Flashcard> incorrectCards = [];
      
      if (_isInFavoritesDeck()) {
        // For Favorites deck, get cards that are marked incorrect in their original decks
        final favoriteCards = await _databaseService.getFavoriteCards();
        for (final card in favoriteCards) {
          final originalDeckId = card.categoryId;
          if (originalDeckId > 0) {
            final incorrectCardIds = await _databaseService.getIncorrectCardsFromDatabase(originalDeckId);
            if (incorrectCardIds.contains(card.id)) {
              incorrectCards.add(card);
            }
          }
        }
      } else {
        // For regular decks, use the normal logic
        final incorrectCardIds = await _databaseService.getIncorrectCardsFromDatabase(_currentCategoryId);
        
        if (incorrectCardIds.isNotEmpty) {
          // Load the actual card objects for the incorrect card IDs
          final allCards = await _databaseService.getCardsByCategory(_currentCategoryId);
          incorrectCards = allCards.where((card) => incorrectCardIds.contains(card.id)).toList();
        }
      }
      
      if (incorrectCards.isNotEmpty) {
        setState(() {
          _isReviewMode = true;
          _currentCards = incorrectCards;
          _currentCardIndex = 0;
          _showAnswer = false;
          _reviewCorrectAnswers = 0;
          _reviewTotalAttempts = 0;
        });
      } else {
        // Show message that no incorrect cards are available for review
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No incorrect cards to review. Try studying some cards first!'),
              backgroundColor: context.appTheme.primaryBlue,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error starting incorrect cards review: $e');
    }
  }
  
  void _startSpacedRepetitionReview() async {
    // Load cards due for spaced repetition review
    final dueCards = await _databaseService.getFlashcardsDueForReview(_currentCategoryId);
    
    if (dueCards.isNotEmpty) {
      setState(() {
        _isReviewMode = true;
        _currentCards = dueCards;
        _currentCardIndex = 0;
        _showAnswer = false;
      });
    } else {
      // Show message that no cards are due for review
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No cards are due for review right now.'),
            backgroundColor: context.appTheme.primaryBlue,
          ),
        );
      }
    }
  }
  
  void _backToOriginalDeck() async {
    // Load the original cards for the current category
    List<Flashcard> originalCards;
    
    if (_isInFavoritesDeck()) {
      // For Favorites deck, use getFavoriteCards
      originalCards = await _databaseService.getFavoriteCards();
    } else {
      // For regular decks, use getCardsByCategory
      originalCards = await _databaseService.getCardsByCategory(_currentCategoryId);
    }
    
    setState(() {
      _isReviewMode = false;
      _currentCards = originalCards;
      _currentCardIndex = 0;
      _showAnswer = false;
    });
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
    if (_currentCards.isEmpty || !_isDragging) return;
    
    // Block additional pan end events immediately
    if (_isAnimationBlocked) return;
    
    setState(() {
      _isDragging = false;
      _isAnimationBlocked = true; // Block immediately to prevent multiple calls
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
  Future<void> _completeSwipeAction(Offset velocity) async {
    // Set swipe operation flag to prevent database calls during swipe
    KaadoNavigationDrawer.setSwipeOperation(true);
    
    final delta = _dragOffset;
    final absDx = delta.dx.abs();
    final absDy = delta.dy.abs();
    // final isLastCard = _currentCardIndex >= _currentCards.length - 1; // Unused variable
    
    if (absDx > absDy) {
      // Horizontal swipe
      if (delta.dx > 0) {
        // Swipe right - correct (quality 5)
        await _handleSwipeGesture('right');
        _recordAnswer(isCorrect: true); // Record correct answer and advance to next card
        _animateCardExit(true);
      } else {
        // Swipe left - incorrect (quality 0)
        await _handleSwipeGesture('left');
        _recordAnswer(isCorrect: false); // Record incorrect answer and advance to next card
        
        // Mark card as incorrect in database (persistent storage)
        final currentCard = _getCurrentFlashcard();
        if (currentCard.id > 0) {
          if (_isInFavoritesDeck()) {
            // For Favorites deck, mark as incorrect in the original deck
            await _databaseService.markCardIncorrectInDatabase(currentCard.id, currentCard.categoryId);
          } else {
            // For regular decks, mark as incorrect in current deck
            await _databaseService.markCardIncorrectInDatabase(currentCard.id, _currentCategoryId);
          }
        }
        
        // Note: Review prompt visibility is now determined by database query
        _animateCardExit(false);
      }
    } else {
      // Vertical swipe
      if (delta.dy < 0) {
        // Swipe up - skip (no quality change)
        _animateCardExit(null);
        _skipCard();
      } else {
        // Swipe down - go back to previous card (no quality change)
        if (_cardHistory.isNotEmpty) {
          _goBackToPreviousCard();
        } else {
          // No previous card - return to center
          _returnCardToCenter();
        }
      }
    }
    
    // Clear swipe operation flag after entire swipe process completes
    KaadoNavigationDrawer.setSwipeOperation(false);
  }

  /// Animate card exit in the swipe direction
  void _animateCardExit(bool? isCorrect) {
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
      // Note: Swipe operation flag will be cleared by _recordAnswer when it completes
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

  
  
  /// Build blank card placeholder
  Widget _buildBlankCardPlaceholder() {
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
        minHeight: MediaQuery.of(context).size.height * 0.3,
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

  /// Toggle favorite status of the current card
  Future<void> _toggleFavorite() async {
    if (_currentCards.isEmpty) return;
    
    try {
      final currentCard = _getCurrentFlashcard();
      await _databaseService.toggleFavorite(currentCard.id);
      
      // Refresh the card from the database to get the latest favorite status
      final refreshedCard = await _databaseService.getCardById(currentCard.id);
      if (refreshedCard != null) {
        setState(() {
          _currentCards[_currentCardIndex] = refreshedCard;
        });
        
        // If we're in the Favorites deck and the card is no longer favorited, remove it
        if (_isInFavoritesDeck() && !refreshedCard.isFavorite) {
          _removeCardFromFavoritesDeck();
        }
        
        // Refresh navigation drawer to update card counts
        KaadoNavigationDrawer.forceRefreshCategoriesStatic();
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      AppLogger.error('Error toggling favorite', e);
    }
  }

  /// Check if we're currently in the Favorites deck
  bool _isInFavoritesDeck() {
    if (_currentCards.isEmpty) return false;
    
    // Simple check: if we're in the Favorites deck, all cards should be favorites
    // and we should have loaded them via getFavoriteCards()
    return _currentCards.every((card) => card.isFavorite);
  }

  /// Remove the current card from the Favorites deck when unstarred
  void _removeCardFromFavoritesDeck() {
    if (_currentCards.isEmpty) return;
    
    setState(() {
      // Remove the current card from the list
      _currentCards.removeAt(_currentCardIndex);
      
      // Adjust the index if we're at the end
      if (_currentCardIndex >= _currentCards.length) {
        _currentCardIndex = _currentCards.length - 1;
      }
      
      // If no more cards, reset to show placeholder
      if (_currentCards.isEmpty) {
        _currentCardIndex = 0;
        _showAnswer = false;
      }
    });
  }

  /// Handle swipe gesture with SRS algorithm integration
  Future<void> _handleSwipeGesture(String direction) async {
    if (_currentCards.isEmpty) return;
    
    try {
      final currentCard = _getCurrentFlashcard();
      final quality = SRSAlgorithm.getQualityFromSwipe(direction);
      
      // Skip if no quality change (up/down swipes)
      if (quality == -1) {
        return;
      }
      
      // Get or create user progress for this card
      UserProgress? progress = await _databaseService.getUserProgress(currentCard.id);
      if (progress == null) {
        // Initialize progress for new card
        progress = SRSAlgorithm.initializeProgress(currentCard.id);
      }
      
      // Calculate new progress using SRS algorithm
      final updatedProgress = SRSAlgorithm.calculateNextReview(
        current: progress,
        quality: quality,
      );
      
      // Save updated progress to database
      await _databaseService.saveUserProgress(updatedProgress);
      
      // Update local statistics only for main deck, not review mode
      if (!_isReviewMode) {
        if (quality >= 3) {
          _correctAnswers++;
        }
        _totalAttempts++;
      }
      
    } catch (e) {
      AppLogger.error('Error handling swipe gesture', e);
    }
  }

  /// Open card display settings
  void _openCardDisplaySettings() async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CardDisplaySettingsScreen(),
        ),
      );
    } catch (e) {
      AppLogger.error('Error opening card display settings', e);
    }
  }

  /// Open spaced repetition settings
  void _openSpacedRepetitionSettings() async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SpacedRepetitionSettingsScreen(),
        ),
      );
    } catch (e) {
      AppLogger.error('Error opening spaced repetition settings', e);
    }
  }
  
  
  
}

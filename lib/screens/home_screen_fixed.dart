import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/spaced_repetition_service.dart';
import '../utils/theme_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_colors.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/fab_menu.dart';
import '../widgets/progress_bar.dart';
import '../widgets/quick_edit_card_dialog.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final SpacedRepetitionService _spacedRepetitionService = SpacedRepetitionService();
  final GlobalKey<FabMenuState> _fabMenuKey = GlobalKey<FabMenuState>();
  
  List<Flashcard> _currentCards = [];
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;
  bool _isReviewMode = false;
  int _currentCategoryId = 0;
  String _currentCategoryName = '';
  
  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _flipController;
  
  // Animation values
  late Animation<double> _swipeAnimation;
  late Animation<double> _flipAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentCategory();
  }
  
  void _initializeAnimations() {
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _swipeController.dispose();
    _flipController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCurrentCategory() async {
    try {
      setState(() => _isLoading = true);
      
      // Get the first category with cards
      final categories = await _databaseService.getCategoriesWithCards();
      if (categories.isNotEmpty) {
        final category = categories.first;
        await _loadCardsForCategory(category.id, category.name);
      } else {
        setState(() {
          _currentCards = [];
          _currentCategoryId = 0;
          _currentCategoryName = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadCardsForCategory(int categoryId, String categoryName) async {
    try {
      final cards = await _databaseService.getCardsByCategory(categoryId);
      setState(() {
        _currentCards = cards;
        _currentCardIndex = 0;
        _currentCategoryId = categoryId;
        _currentCategoryName = categoryName;
        _showAnswer = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  void _onCardTap() {
    if (!_showAnswer) {
      setState(() => _showAnswer = true);
      _flipController.forward();
    }
  }
  
  void _onSwipeLeft() {
    _handleCardResult('wrong');
  }
  
  void _onSwipeRight() {
    _handleCardResult('correct');
  }
  
  void _onSwipeUp() {
    _handleCardResult('skip');
  }
  
  void _onSwipeDown() {
    _handleCardResult('back');
  }
  
  void _handleCardResult(String result) {
    if (_currentCards.isEmpty) return;
    
    final currentCard = _getCurrentFlashcard();
    
    if (result == 'wrong') {
      _databaseService.addIncorrectCard(currentCard.id);
    } else if (result == 'correct') {
      _databaseService.removeIncorrectCard(currentCard.id);
      _spacedRepetitionService.recordCardResult(currentCard.id, true);
    }
    
    _nextCard();
  }
  
  void _nextCard() {
    if (_currentCardIndex < _currentCards.length - 1) {
      setState(() {
        _currentCardIndex++;
        _showAnswer = false;
      });
      _flipController.reset();
    } else {
      // Deck completed
      setState(() {
        _showAnswer = true;
      });
    }
  }
  
  Flashcard _getCurrentFlashcard() {
    return _currentCards[_currentCardIndex];
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
      _flipController.reset();
    }
  }
  
  void _resetCards() {
    setState(() {
      _currentCardIndex = 0;
      _showAnswer = false;
    });
    _flipController.reset();
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
    final colors = ThemeColors.instance;
    
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: GestureDetector(
        onTap: _closeFabMenu,
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Progress bar
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
                
                // Card area
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: colors.primaryBlue))
                        : _currentCards.isEmpty
                            ? Center(
                                child: Text(
                                  'No cards available',
                                  style: TextStyle(
                                    color: colors.secondaryText,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : FlashcardWidget(
                                flashcard: _getCurrentFlashcard(),
                                showAnswer: _showAnswer,
                                isCompleted: _currentCardIndex >= _currentCards.length,
                                onTap: _onCardTap,
                                onEdit: _showEditCardDialog,
                              ),
                  ),
                ),
                
                // Review boxes at bottom
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
                  child: Column(
                    children: [
                      // Incorrect cards review
                      FutureBuilder<int>(
                        future: _getIncorrectCardsCount(),
                        builder: (context, snapshot) {
                          final incorrectCount = snapshot.data ?? 0;
                          if (incorrectCount > 0 && !_isReviewMode) {
                            return Container(
                              margin: EdgeInsets.only(bottom: AppSizes.spacingMedium),
                              padding: EdgeInsets.all(AppSizes.paddingMedium),
                              decoration: BoxDecoration(
                                color: colors.cardBackground.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                                border: Border.all(color: colors.divider),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: colors.incorrectButton),
                                  SizedBox(width: AppSizes.spacingSmall),
                                  Expanded(
                                    child: Text(
                                      '!$incorrectCount card${incorrectCount == 1 ? '' : 's'} wrong',
                                      style: TextStyle(
                                        color: colors.secondaryText,
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
                                    child: Text('Review'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.incorrectButton,
                                      foregroundColor: colors.buttonTextOnColored,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                      
                      // Spaced repetition review
                      if (!_isReviewMode && _currentCategoryId > 0)
                        FutureBuilder<Map<String, int>>(
                          future: _getSpacedRepetitionStats(),
                          builder: (context, snapshot) {
                            final stats = snapshot.data ?? {};
                            final reviewCount = stats['review'] ?? 0;
                            final overdueCount = stats['overdue'] ?? 0;
                            final totalDue = reviewCount + overdueCount;
                            
                            if (totalDue > 0) {
                              return Container(
                                margin: EdgeInsets.only(bottom: AppSizes.spacingMedium),
                                padding: EdgeInsets.all(AppSizes.paddingMedium),
                                decoration: BoxDecoration(
                                  color: colors.cardBackground.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                                  border: Border.all(color: colors.divider),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: colors.primaryBlue),
                                    SizedBox(width: AppSizes.spacingSmall),
                                    Expanded(
                                      child: Text(
                                        '!$totalDue card${totalDue == 1 ? '' : 's'} due',
                                        style: TextStyle(
                                          color: colors.secondaryText,
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
                                      child: Text('Review'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primaryBlue,
                                        foregroundColor: colors.buttonTextOnColored,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      
                      // Swipe instructions
                      if (_currentCards.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSwipeHint('←', 'Wrong', colors.incorrectButton),
                            _buildSwipeHint('↑', 'Skip', colors.skipButton),
                            _buildSwipeHint('↓', 'Back', colors.actionButtonBackground),
                            _buildSwipeHint('→', 'Correct', colors.correctButton),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // FAB positioned above the review boxes
            Positioned(
              bottom: 140,
              right: 32,
              child: FabMenu(
                key: _fabMenuKey,
                onShuffle: _shuffleCards,
                onReset: _isReviewMode ? _backToOriginalDeck : _resetCards,
                isEnabled: _currentCards.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwipeHint(String direction, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              direction,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    return await _databaseService.getIncorrectCardsCount();
  }
  
  Future<Map<String, int>> _getSpacedRepetitionStats() async {
    return await _spacedRepetitionService.getReviewStats(_currentCategoryId);
  }
  
  void _startIncorrectCardsReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          databaseService: _databaseService,
          onBack: () {
            _loadCurrentCategory();
          },
        ),
      ),
    );
  }
  
  void _startSpacedRepetitionReview() {
    // TODO: Implement spaced repetition review
  }
  
  void _backToOriginalDeck() {
    setState(() {
      _isReviewMode = false;
    });
    _loadCurrentCategory();
  }
}

// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/category.dart';
import '../models/flashcard.dart';

// Project imports - Services
import '../services/database_service.dart';

// Project imports - Utils
import '../utils/theme_colors.dart';
import '../utils/constants.dart';

// Project imports - Constants
import '../constants/app_sizes.dart';

// Project imports - Constants
import '../constants/app_colors.dart';

// Project imports - Widgets
import '../widgets/card_item.dart';
import '../widgets/card_edit_dialog.dart';

/// Category detail screen for viewing and managing cards within a category
/// 
/// This screen provides:
/// - List of all cards in the category
/// - Card editing, adding, and deleting functionality
/// - Search and filtering capabilities
/// - Clean card display with all fields visible
class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final DatabaseService databaseService;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.databaseService,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<Flashcard> _cards = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  /// Load all cards for this category
  Future<void> _loadCards() async {
    try {
      setState(() => _isLoading = true);
      final cards = await widget.databaseService.getCardsByCategory(widget.category.id);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cards: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Filter cards based on search query
  List<Flashcard> get _filteredCards {
    if (_searchQuery.isEmpty) return _cards;
    
    return _cards.where((card) {
      return card.kana.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             card.hiragana?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
             card.english.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             card.romaji?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
    }).toList();
  }

  /// Show add card dialog
  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) => CardEditDialog(
        categoryId: widget.category.id,
        onCardSaved: () {
          _loadCards();
        },
      ),
    );
  }

  /// Show edit card dialog
  void _showEditCardDialog(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => CardEditDialog(
        categoryId: widget.category.id,
        card: card,
        onCardSaved: () {
          _loadCards();
        },
      ),
    );
  }

  /// Show delete card dialog
  void _showDeleteCardDialog(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.instance.surface,
        title: Text(
          'Delete Card',
          style: TextStyle(
            color: ThemeColors.instance.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this card?',
          style: TextStyle(color: ThemeColors.instance.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ThemeColors.instance.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await widget.databaseService.deleteCard(card.id);
                _loadCards();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Card deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting card: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
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
          widget.category.name,
          style: TextStyle(
            color: colors.appBarIcon,
            fontSize: AppConstants.englishTextSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colors.appBarIcon),
            onPressed: _showAddCardDialog,
            tooltip: 'Add Card',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category info and search
          Container(
            padding: EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category description
                if (widget.category.description?.isNotEmpty == true) ...[
                  Text(
                    widget.category.description!,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: AppSizes.spacingMedium),
                ],

                // Card count
                Text(
                  '${_cards.length} cards',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: AppSizes.spacingMedium),

                // Search bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search cards...',
                    hintStyle: TextStyle(color: colors.secondaryText),
                    prefixIcon: Icon(Icons.search, color: colors.primaryIcon),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: colors.primaryIcon),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: colors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: colors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: colors.primaryBlue, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colors.primaryText),
                ),
              ],
            ),
          ),

          // Cards list
          Expanded(
            child: _isLoading
                ? _buildLoadingState(colors)
                : _filteredCards.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildCardsList(colors),
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.primaryBlue,
          ),
          SizedBox(height: AppSizes.spacingMedium),
          Text(
            'Loading cards...',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 64,
            color: colors.secondaryText,
          ),
          SizedBox(height: AppSizes.spacingMedium),
          Text(
            _searchQuery.isEmpty ? 'No cards in this category' : 'No matching cards',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSizes.spacingSmall),
          Text(
            _searchQuery.isEmpty 
                ? 'Add your first card to get started'
                : 'Try a different search term',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: AppSizes.spacingLarge),
            ElevatedButton.icon(
              onPressed: _showAddCardDialog,
              icon: Icon(Icons.add),
              label: Text('Add Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: colors.buttonTextOnColored,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingLarge,
                  vertical: AppSizes.spacingMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build cards list
  Widget _buildCardsList(ThemeColors colors) {
    return RefreshIndicator(
      onRefresh: _loadCards,
      color: colors.primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppConstants.cardPadding),
        itemCount: _filteredCards.length,
        itemBuilder: (context, index) {
          final card = _filteredCards[index];
          return CardItem(
            card: card,
            onTap: () => _showEditCardDialog(card),
            onDelete: () => _showDeleteCardDialog(card),
          );
        },
      ),
    );
  }
}

// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/category.dart' as app_models;
import '../models/flashcard.dart';

// Project imports - Services
import '../services/database_service.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
import '../utils/constants.dart';

// Project imports - Constants

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
  final app_models.Category category;
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
      // Use database thread service to prevent main thread blocking
      final cards = await DatabaseService().getCardsByCategory(widget.category.id);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cards: $e'),
            backgroundColor: theme.colorScheme.error,
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
      builder: (context) {
        final theme = Theme.of(context);
        final appTheme = context.appTheme;
        return AlertDialog(
        backgroundColor: appTheme.surface,
        title: Text(
          'Delete Card',
          style: TextStyle(
            color: appTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this card?',
          style: TextStyle(color: appTheme.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: appTheme.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                await widget.databaseService.deleteCard(card.id);
                _loadCards();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Card deleted successfully'),
                      backgroundColor: theme.primaryColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting card: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.appBarBackground,
        foregroundColor: appTheme.appBarIcon,
        elevation: 0,
        title: Text(
          widget.category.name,
          style: TextStyle(
            color: appTheme.appBarIcon,
            fontSize: AppConstants.englishTextSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appTheme.appBarIcon),
            onPressed: _showAddCardDialog,
            tooltip: 'Add Card',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
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
                      color: appTheme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: AppSizes.spacingMedium),
                ],

                // Card count
                Text(
                  '${_cards.length} cards',
                  style: TextStyle(
                    color: appTheme.primaryText,
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
                    hintStyle: TextStyle(color: appTheme.secondaryText),
                    prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.primaryColor),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: appTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: appTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: appTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                      borderSide: BorderSide(color: theme.primaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(color: appTheme.primaryText),
                ),
              ],
            ),
          ),

          // Cards list
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredCards.isEmpty
                    ? _buildEmptyState()
                    : _buildCardsList(),
          ),
        ],
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
          ),
          SizedBox(height: AppSizes.spacingMedium),
          Text(
            'Loading cards...',
            style: TextStyle(
              color: appTheme.secondaryText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 64,
            color: appTheme.secondaryText,
          ),
          SizedBox(height: AppSizes.spacingMedium),
          Text(
            _searchQuery.isEmpty ? 'No cards in this category' : 'No matching cards',
            style: TextStyle(
              color: appTheme.primaryText,
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
              color: appTheme.secondaryText,
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
                backgroundColor: theme.primaryColor,
                foregroundColor: appTheme.buttonTextOnColored,
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
  Widget _buildCardsList() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _loadCards,
      color: theme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: AppConstants.cardPadding,
          right: AppConstants.cardPadding,
          bottom: MediaQuery.of(context).padding.bottom + 16, // Add padding for system UI
        ),
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

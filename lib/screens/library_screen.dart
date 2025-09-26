// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports - Models
import '../models/category.dart' as app_models;

// Project imports - Services
import '../services/database_service.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../utils/constants.dart';

// Project imports - Constants
import '../constants/app_sizes.dart';

// Project imports - Constants

// Project imports - Screens
import 'category_detail_screen.dart';

// Project imports - Widgets
import '../widgets/category_management_dialogs.dart';
import '../widgets/navigation_drawer.dart';

/// Library screen for browsing categories and managing cards
/// 
/// This screen provides:
/// - Category browsing with card counts
/// - Card management (view, edit, add, delete)
/// - Search and filtering capabilities
/// - Clean, intuitive UI for content management
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late DatabaseService _databaseService;
  List<app_models.Category> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _databaseService = ref.read(databaseServiceProvider);
    _loadCategories();
  }

  /// Load all categories from the database using the same method as navigation drawer
  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final categories = await _databaseService.getCategoryTree();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Filter categories based on search query
  List<app_models.Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return _getAllCategories();
    
    return _getAllCategories().where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             category.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
    }).toList();
  }

  /// Get all categories in a flat list (including nested categories)
  List<app_models.Category> _getAllCategories() {
    List<app_models.Category> allCategories = [];
    
    void addCategoryAndChildren(app_models.Category category) {
      allCategories.add(category);
      if (category.children != null) {
        for (final child in category.children!) {
          addCategoryAndChildren(child);
        }
      }
    }
    
    for (final category in _categories) {
      addCategoryAndChildren(category);
    }
    
    return allCategories;
  }

  /// Filter categories to show only meaningful ones (with content or meaningful children)
  List<app_models.Category> _getFilteredCategories() {
    if (_searchQuery.isEmpty) {
      return _filterCategoriesWithContent(_categories);
    }
    
    // For search, show all categories that match the query
    return _getAllCategories().where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             category.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
    }).toList();
  }

  /// Filter categories to only show those with content or meaningful children
  List<app_models.Category> _filterCategoriesWithContent(List<app_models.Category> categories) {
    List<app_models.Category> filtered = [];
    
    for (final category in categories) {
      if (_hasContentOrMeaningfulChildren(category)) {
        final filteredCategory = app_models.Category(
          id: category.id,
          name: category.name,
          description: category.description,
          parentId: category.parentId,
          sortOrder: category.sortOrder,
          hasChildren: category.hasChildren,
          isCardCategory: category.isCardCategory,
          cardCount: category.cardCount,
          fullPath: category.fullPath,
          children: category.children != null 
            ? _filterCategoriesWithContent(category.children!) 
            : null,
        );
        filtered.add(filteredCategory);
      }
    }
    
    return filtered;
  }

  /// Check if a category has content or meaningful children
  bool _hasContentOrMeaningfulChildren(app_models.Category category) {
    // If it's a card category with cards, show it
    if (category.isCardCategory && category.cardCount > 0) {
      return true;
    }
    
    // If it has children, check if any of them have content
    if (category.children != null && category.children!.isNotEmpty) {
      for (final child in category.children!) {
        if (_hasContentOrMeaningfulChildren(child)) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Navigate to category detail screen
  void _navigateToCategory(app_models.Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          category: category,
          databaseService: _databaseService,
        ),
      ),
    );
  }

  /// Show add category dialog
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        onCategoryAdded: () {
          _loadCategories();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      drawer: KaadoNavigationDrawer(
        databaseService: _databaseService,
        onCategorySelected: (categoryId) {
          // Navigate to category detail when selected from drawer
          final category = _categories.firstWhere(
            (cat) => cat.id == categoryId,
            orElse: () => _categories.first,
          );
          _navigateToCategory(category);
        },
        onResetDatabase: () {
          // Reload categories after database reset
          _loadCategories();
        },
        onThemeChanged: (theme) {
          // Theme change will be handled automatically by the app
        },
        onCloseFab: () {
          // No FAB to close in library screen
        },
      ),
      appBar: AppBar(
        backgroundColor: appTheme.appBarBackground,
        foregroundColor: appTheme.appBarIcon,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: appTheme.appBarIcon),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Library',
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
            onPressed: _showAddCategoryDialog,
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(AppConstants.cardPadding),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search categories...',
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
          ),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildCategoriesList(),
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
            'Loading categories...',
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
            Icons.library_books_outlined,
            size: 64,
            color: appTheme.secondaryText,
          ),
          SizedBox(height: AppSizes.spacingMedium),
          Text(
            _searchQuery.isEmpty ? 'No categories found' : 'No matching categories',
            style: TextStyle(
              color: appTheme.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSizes.spacingSmall),
          Text(
            _searchQuery.isEmpty 
                ? 'Add your first category to get started'
                : 'Try a different search term',
            style: TextStyle(
              color: appTheme.secondaryText,
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: AppSizes.spacingLarge),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: Icon(Icons.add),
              label: Text('Add Category'),
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

  /// Build categories list
  Widget _buildCategoriesList() {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: theme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16, // Add padding for system UI
        ),
        itemCount: _getFilteredCategories().length,
        itemBuilder: (context, index) {
          final category = _getFilteredCategories()[index];
          return _buildCategoryTile(category, theme, appTheme);
        },
      ),
    );
  }

  /// Build category tile with the same styling as navigation drawer
  Widget _buildCategoryTile(app_models.Category category, ThemeData theme, AppThemeExtension appTheme) {
    // If it has children, show as ExpansionTile
    if (category.children != null && category.children!.isNotEmpty) {
      return ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: appTheme.primaryText,
                ),
              ),
            ),
            if (category.cardCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.cardCount}',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        iconColor: theme.primaryColor,
        collapsedIconColor: theme.primaryColor,
        maintainState: true,
        initiallyExpanded: category.parentId == null, // Auto-expand top-level categories
        children: category.children!.map((subcategory) {
          return Padding(
            padding: EdgeInsets.only(left: AppSizes.spacingLarge),
            child: _buildCategoryTile(subcategory, theme, appTheme),
          );
        }).toList(),
      );
    }
    
    // Leaf category - show as ListTile with tap action and card count
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      tileColor: Colors.transparent,
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: appTheme.primaryText,
        ),
      ),
      trailing: category.cardCount > 0 
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${category.cardCount}',
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : null,
      onTap: () => _navigateToCategory(category),
    );
  }

}

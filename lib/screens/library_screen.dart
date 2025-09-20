// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/category.dart';

// Project imports - Services
import '../services/database_service.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../utils/constants.dart';

// Project imports - Constants
import '../constants/app_sizes.dart';
import '../constants/app_colors.dart';

// Project imports - Constants

// Project imports - Screens
import 'category_detail_screen.dart';

// Project imports - Widgets
import '../widgets/category_management_dialogs.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/category_tree_view.dart';

/// Library screen for browsing categories and managing cards
/// 
/// This screen provides:
/// - Category browsing with card counts
/// - Card management (view, edit, add, delete)
/// - Search and filtering capabilities
/// - Clean, intuitive UI for content management
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
  List<Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return _getAllCategories();
    
    return _getAllCategories().where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             category.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
    }).toList();
  }

  /// Get all categories in a flat list (including nested categories)
  List<Category> _getAllCategories() {
    List<Category> allCategories = [];
    
    void addCategoryAndChildren(Category category) {
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
  List<Category> _getFilteredCategories() {
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
  List<Category> _filterCategoriesWithContent(List<Category> categories) {
    List<Category> filtered = [];
    
    for (final category in categories) {
      if (_hasContentOrMeaningfulChildren(category)) {
        final filteredCategory = Category(
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
  bool _hasContentOrMeaningfulChildren(Category category) {
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
  void _navigateToCategory(Category category) {
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
      body: Column(
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
      child: CategoryTreeView(
        categories: _getFilteredCategories(),
        onCategoryTap: _navigateToCategory,
        onCategoryEdit: _showEditCategoryDialog,
        onCategoryDelete: _showDeleteCategoryDialog,
      ),
    );
  }

  /// Show edit category dialog
  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(
        category: category,
        onCategoryUpdated: () {
          _loadCategories();
        },
      ),
    );
  }

  /// Show delete category dialog
  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final appTheme = context.appTheme;
        return AlertDialog(
        backgroundColor: appTheme.surface,
        title: Text(
          'Delete Category',
          style: TextStyle(
            color: appTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This will also delete all cards in this category.',
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
              Navigator.of(context).pop();
              try {
                await _databaseService.deleteCategory(category.id);
                _loadCategories();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting category: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
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
}

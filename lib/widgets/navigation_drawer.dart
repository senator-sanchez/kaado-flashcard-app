// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Constants
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

// Project imports - Models
import '../models/category.dart' as app_models;

// Project imports - Services
import '../services/database_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/theme_service.dart';
import '../services/app_logger.dart';

// Project imports - Screens
import '../screens/spaced_repetition_settings_screen.dart';

// Project imports - Utils
import '../utils/app_theme.dart';

// Project imports - Widgets
import 'background_photo_settings_traditional.dart';
import 'shared/drawer_tile.dart';
import 'shared/section_header.dart';

class KaadoNavigationDrawer extends StatefulWidget {
  final DatabaseService databaseService;
  final Function(int categoryId)? onCategorySelected;
  final VoidCallback? onResetDatabase;
  final Function(AppThemeMode)? onThemeChanged;
  final VoidCallback? onCloseFab;

  const KaadoNavigationDrawer({
    super.key, 
    required this.databaseService,
    this.onCategorySelected,
    this.onResetDatabase,
    this.onThemeChanged,
    this.onCloseFab,
  });

  @override
  State<KaadoNavigationDrawer> createState() => _KaadoNavigationDrawerState();
}

enum DrawerView { main, cards, review, settings }

class _KaadoNavigationDrawerState extends State<KaadoNavigationDrawer> {
  DrawerView _currentView = DrawerView.main;
  List<app_models.Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Listen to theme changes
    ThemeService().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild when theme changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return Drawer(
        backgroundColor: appTheme.backgroundColor,
      child: Column(
        children: [
          // Compact header that matches theme
          Container(
            height: 100, // Increased height to prevent text obscuring
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingLarge, 
              MediaQuery.of(context).padding.top + AppSizes.paddingMedium, 
              AppSizes.paddingLarge, 
              AppSizes.paddingMedium
            ),
            decoration: BoxDecoration(color: appTheme.appBarBackground),
            child: Row(
              children: [
                if (_currentView != DrawerView.main)
                  GestureDetector(
                    onTap: () {
                      widget.onCloseFab?.call();
                      setState(() => _currentView = DrawerView.main);
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 4, right: 8), // Move closer to left
                      child: Icon(
                        Icons.arrow_back, 
                        color: appTheme.appBarIcon,
                        size: 24,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _currentView == DrawerView.main ? 'Kaado' : '',
                    style: TextStyle(
                      color: appTheme.appBarIcon,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ),
              ],
            ),
          ),
          // Show content based on current view
          Expanded(
            child: SafeArea(
              child: Container(
                color: appTheme.backgroundColor,
                child: _buildCurrentView(theme, appTheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(ThemeData theme, AppThemeExtension appTheme) {
    switch (_currentView) {
      case DrawerView.main:
        return _buildMainMenu(theme, appTheme);
      case DrawerView.cards:
        return _buildCardsView(theme, appTheme);
      case DrawerView.review:
        return _buildReviewView(theme, appTheme);
      case DrawerView.settings:
        return _buildSettingsContent(theme, appTheme);
    }
  }

  Widget _buildMainMenu(ThemeData theme, AppThemeExtension appTheme) {
    return ListView(
      padding: EdgeInsets.zero,
        children: [
        // Main navigation items
          DrawerTile(
            title: 'Decks',
            subtitle: 'Browse and select flashcard decks',
            icon: Icons.style,
            onTap: () {
            widget.onCloseFab?.call();
              setState(() => _currentView = DrawerView.cards);
            },
          ),
          
          DrawerTile(
            title: 'Review',
          subtitle: 'Practice incorrect cards and spaced repetition',
            icon: Icons.refresh,
            onTap: () {
            widget.onCloseFab?.call();
              setState(() => _currentView = DrawerView.review);
            },
          ),
          
          DrawerTile(
            title: 'Settings',
            subtitle: 'Customize app appearance and data',
            icon: Icons.settings,
            onTap: () {
            widget.onCloseFab?.call();
              setState(() => _currentView = DrawerView.settings);
            },
          ),
          
        // Bottom padding
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }


  Widget _buildCardsView(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                )
              : ListView(
          padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + AppSizes.spacingLarge,
                  ),
                  children: _buildCategoryList(_categories, theme, appTheme),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryList(List<app_models.Category> categories, ThemeData theme, AppThemeExtension appTheme) {
    if (categories.isEmpty) {
      return [
        ListTile(
          title: Text('No decks found'),
          subtitle: Text('Check database connection'),
        ),
      ];
    }
    
    return categories.map((category) {
      return _buildCategoryTile(category, theme, appTheme);
    }).toList();
  }

  Widget _buildCategoryTile(app_models.Category category, ThemeData theme, AppThemeExtension appTheme) {
    // If it's a bottom-level category (has cards), show as custom tile
    if (category.isCardCategory) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onCategorySelected?.call(category.id);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Leading icon (star for favorites, or empty space)
              SizedBox(
                width: 24,
                child: category.name.toLowerCase() == 'favorites'
                    ? Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      )
                    : null,
              ),
              SizedBox(width: 16),
              // Title and card count
              Expanded(
                child: Row(
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
                        margin: EdgeInsets.only(left: AppSizes.spacingSmall),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingSmall,
                          vertical: AppSizes.spacingXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                        child: Text(
                          '${category.cardCount}',
                          style: TextStyle(
                            color: appTheme.buttonTextOnColored,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

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
    
    // Fallback for categories with no children and no cards
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
      onTap: () {
        widget.onCategorySelected?.call(category.id);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildReviewView(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        const SectionHeader(title: 'Review Options'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            children: [
              // Incorrect Cards Review
              DrawerTile(
                title: 'Incorrect Cards',
                subtitle: 'Practice cards you got wrong',
                icon: Icons.error_outline,
                onTap: () {
                  // Navigate to incorrect cards review
                  Navigator.of(context).pop();
                  // Add navigation logic here
                },
              ),
              
              SizedBox(height: AppSizes.spacingSmall),
              
              // Spaced Repetition Review
              DrawerTile(
                title: 'Daily Review',
                subtitle: 'Cards due for spaced repetition',
                icon: Icons.schedule,
                onTap: () {
                  // Navigate to spaced repetition review
                  Navigator.of(context).pop();
                  // Add navigation logic here
                },
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildSettingsContent(ThemeData theme, AppThemeExtension appTheme) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Appearance section header
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
              children: [
                Icon(
                Icons.palette,
                size: 20,
                color: appTheme.secondaryIcon,
              ),
              SizedBox(width: 8),
                Text(
                'Appearance',
                  style: TextStyle(
                  color: appTheme.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                  ),
                ],
              ),
            ),
            
        // Theme Options
        DrawerTile(
          title: AppStrings.lightMode,
          subtitle: AppStrings.lightModeDescription,
          icon: Icons.light_mode,
          isSelected: ThemeService().currentTheme == AppThemeMode.light,
          onTap: () {
            ThemeService().setTheme(AppThemeMode.light);
            setState(() {});
          },
        ),
        
        DrawerTile(
          title: AppStrings.darkMode,
          subtitle: AppStrings.darkModeDescription,
          icon: Icons.dark_mode,
          isSelected: ThemeService().currentTheme == AppThemeMode.dark,
          onTap: () {
            ThemeService().setTheme(AppThemeMode.dark);
            setState(() {});
          },
        ),
        
        // Divider
        Divider(height: 1, color: appTheme.divider),
        
        // Background Photo Settings
        const BackgroundPhotoSettingsTraditional(),
        
        // Divider
        Divider(height: 1, color: appTheme.divider),
        
        // Learning section header
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.school,
                size: 20,
                color: appTheme.secondaryIcon,
              ),
              SizedBox(width: 8),
                  Text(
                'Learning Settings',
                    style: TextStyle(
                  color: appTheme.secondaryText,
                      fontSize: 14,
                  fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        
        // Spaced Repetition Settings
        DrawerTile(
          title: 'Spaced Repetition Settings',
          subtitle: 'Customize review intervals and learning pace',
          icon: Icons.schedule,
          onTap: () => _openSpacedRepetitionSettings(),
        ),
        
        // Bottom padding
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }




  void _openSpacedRepetitionSettings() async {
    // Close FAB first
    widget.onCloseFab?.call();
    
    // Close the drawer first
              Navigator.of(context).pop();
              
              // Load current settings from database
              final currentSettings = await widget.databaseService.loadSpacedRepetitionSettings();
              
    // Use a post-frame callback to ensure the drawer is fully closed
    WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SpacedRepetitionSettingsScreen(
                    initialSettings: currentSettings,
                    onSettingsChanged: (settings) async {
                      try {
                        await widget.databaseService.saveSpacedRepetitionSettings(settings);
                        // Update the spaced repetition service with new settings
                        final spacedRepetitionService = SpacedRepetitionService();
                        spacedRepetitionService.updateSettings(settings);
                      } catch (e) {
                        // Error saving spaced repetition settings: $e
                      }
                    },
                  ),
                ),
              );
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: _loadCategories - Starting to load categories');
      final categories = await widget.databaseService.getCategoryTree();
      print('DEBUG: _loadCategories - Loaded ${categories.length} categories');
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class ReviewDeck {
  final int categoryId;
  final String name;
  final int cardCount;

  const ReviewDeck({
    required this.categoryId,
    required this.name,
    required this.cardCount,
  });
}

// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Constants
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

// Project imports - Models
import '../models/category.dart';
import '../models/incorrect_card.dart';

// Project imports - Services
import '../services/database_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/theme_service.dart';

// Project imports - Screens
import '../screens/review_screen.dart';
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

enum DrawerView { main, cards, review, spacedRepetition, settings }

class _KaadoNavigationDrawerState extends State<KaadoNavigationDrawer> {
  DrawerView _currentView = DrawerView.main;
  List<Category> _categories = [];
  List<ReviewDeck> _reviewDecks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadReviewDecks();
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
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingLarge, 
              MediaQuery.of(context).padding.top + AppSizes.paddingLarge, 
              AppSizes.paddingLarge, 
              AppSizes.paddingLarge
            ),
            decoration: BoxDecoration(color: appTheme.appBarBackground),
            child: Row(
              children: [
                if (_currentView != DrawerView.main)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: appTheme.appBarIcon),
                    onPressed: () {
                      widget.onCloseFab?.call();
                      setState(() => _currentView = DrawerView.main);
                    },
                  ),
                Expanded(
                  child: Text(
                    'Kaado',
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
            child: _buildCurrentView(theme, appTheme),
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
      case DrawerView.spacedRepetition:
        return _buildSpacedRepetitionView(theme, appTheme);
      case DrawerView.settings:
        return _buildSettingsContent(theme, appTheme);
    }
  }

  Widget _buildMainMenu(ThemeData theme, AppThemeExtension appTheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSizes.spacingLarge,
      ),
      child: Column(
        children: [
          SizedBox(height: AppSizes.spacingMedium),
          
          // Cards Option
          DrawerTile(
            title: 'Cards',
            subtitle: 'Browse and select flashcard categories',
            icon: Icons.style,
            onTap: () {
              widget.onCloseFab?.call();
              setState(() => _currentView = DrawerView.cards);
            },
          ),
          
          SizedBox(height: AppSizes.spacingSmall),
          
          // Review Option
          DrawerTile(
            title: 'Review',
            subtitle: 'Practice incorrect cards',
            icon: Icons.refresh,
            onTap: () {
              widget.onCloseFab?.call();
              setState(() => _currentView = DrawerView.review);
            },
          ),
          
          SizedBox(height: AppSizes.spacingSmall),
          
          // Spaced Repetition Option
          DrawerTile(
            title: 'Daily Review',
            subtitle: 'Cards due for spaced repetition',
            icon: Icons.schedule,
            onTap: () {
              widget.onCloseFab?.call();
              setState(() => _currentView = DrawerView.spacedRepetition);
            },
          ),
          
          SizedBox(height: AppSizes.spacingSmall),
          
          // Settings Option
          DrawerTile(
            title: 'Settings',
            subtitle: 'Customize app appearance and data',
            icon: Icons.settings,
            onTap: () {
              widget.onCloseFab?.call();
              setState(() => _currentView = DrawerView.settings);
            },
          ),
          
          SizedBox(height: AppSizes.spacingLarge),
          
          // About section
          Divider(color: appTheme.divider),
          SectionHeader(title: 'About', icon: Icons.info_outline),
          
          _buildInfoTile(
            'Version',
            AppStrings.appVersion,
            Icons.info,
            theme,
            appTheme,
          ),
          
          _buildInfoTile(
            'Developer',
            'Kaado Team',
            Icons.person,
            theme,
            appTheme,
          ),
          
          _buildInfoTile(
            'Description',
            'Japanese Language Learning',
            Icons.school,
            theme,
            appTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String subtitle,
    IconData icon,
    ThemeData theme,
    AppThemeExtension appTheme,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: appTheme.surface, // Use surface color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appTheme.divider, // Use divider color for borders
          width: 1,
        ),
        // Subtle shadows like v10.2
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 4.0,
            offset: Offset(0, 2.0),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: appTheme.surface, // Use surface color like v10.2
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appTheme.divider, // Use divider color like v10.2
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: appTheme.primaryIcon, // Use primary icon color like v10.2
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: appTheme.primaryText, // Use primary text color (adapts to theme)
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: appTheme.secondaryText, // Use secondary text color (adapts to theme)
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCardsView(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        const SectionHeader(title: 'Select Category'),
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

  List<Widget> _buildCategoryList(List<Category> categories, ThemeData theme, AppThemeExtension appTheme) {
    return categories.map((category) {
      return _buildCategoryTile(category, theme, appTheme);
    }).toList();
  }

  Widget _buildCategoryTile(Category category, ThemeData theme, AppThemeExtension appTheme) {
    // If it's a bottom-level category (has cards), show as ListTile
    if (category.isCardCategory) {
      return ListTile(
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
        onTap: () {
          widget.onCategorySelected?.call(category.id);
          Navigator.of(context).pop();
        },
      );
    }
    
    // If it has children, show as ExpansionTile
    if (category.children != null && category.children!.isNotEmpty) {
      return ExpansionTile(
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: appTheme.primaryText,
          ),
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
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: appTheme.primaryText,
        ),
      ),
    );
  }

  Widget _buildReviewView(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        const SectionHeader(title: 'Review Decks'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: _reviewDecks.length,
            itemBuilder: (context, index) {
              final deck = _reviewDecks[index];
              return _buildReviewDeckTile(deck, theme, appTheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewDeckTile(
    ReviewDeck deck,
    ThemeData theme,
    AppThemeExtension appTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
      color: appTheme.cardBackground,
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(
          Icons.quiz,
          color: appTheme.primaryText,
          size: AppSizes.iconMedium,
        ),
        title: Text(
          deck.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: appTheme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${deck.cardCount} cards',
          style: theme.textTheme.bodySmall?.copyWith(
            color: appTheme.secondaryText,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: appTheme.secondaryText,
          size: AppSizes.iconSmall,
        ),
        onTap: () => _openReviewScreen(deck),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildSpacedRepetitionView(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        const SectionHeader(title: 'Spaced Repetition'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              children: [
                DrawerTile(
                  title: 'Spaced Repetition Settings',
                  subtitle: 'Configure learning intervals',
                  icon: Icons.settings,
                  onTap: () => _openSpacedRepetitionSettings(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        const SectionHeader(title: AppStrings.settings),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            children: [
              const SectionHeader(title: 'Theme'),
              _buildThemeTile(
                context,
                AppThemeMode.light,
                AppStrings.lightMode,
                AppStrings.lightModeDescription,
                Icons.light_mode,
                theme,
                appTheme,
              ),
              _buildThemeTile(
                context,
                AppThemeMode.dark,
                AppStrings.darkMode,
                AppStrings.darkModeDescription,
                Icons.dark_mode,
                theme,
                appTheme,
              ),
              const SizedBox(height: AppSizes.spacingLarge),
              const SectionHeader(title: 'Background'),
              const BackgroundPhotoSettingsTraditional(),
              const SizedBox(height: AppSizes.spacingLarge),
              const SectionHeader(title: 'Database'),
              _buildResetDatabaseTile(context, theme, appTheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    AppThemeMode themeMode,
    String title,
    String description,
    IconData icon,
    ThemeData theme,
    AppThemeExtension appTheme,
  ) {
    final isSelected = ThemeService().currentTheme == themeMode;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
      color: isSelected
          ? theme.primaryColor.withOpacity(0.15)
          : appTheme.cardBackground,
      elevation: isSelected ? AppSizes.elevationMedium : AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide(color: appTheme.divider, width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected 
                ? appTheme.buttonTextOnColored
                : appTheme.primaryText,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isSelected ? theme.primaryColor : appTheme.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: appTheme.secondaryText,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: AppSizes.iconSmall,
              )
            : null,
        onTap: () {
          ThemeService().setTheme(themeMode);
          widget.onThemeChanged?.call(themeMode);
          // Force rebuild to show selection change
          setState(() {});
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildResetDatabaseTile(
    BuildContext context,
    ThemeData theme,
    AppThemeExtension appTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
      color: appTheme.cardBackground,
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(
          Icons.refresh,
          color: AppColors.error,
          size: AppSizes.iconMedium,
        ),
        title: Text(
          'Reset Database',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Restore default cards and reset progress',
          style: theme.textTheme.bodySmall?.copyWith(
            color: appTheme.secondaryText,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: appTheme.secondaryText,
          size: AppSizes.iconSmall,
        ),
        onTap: () => _showResetConfirmation(context, theme, appTheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }



  void _showResetConfirmation(
    BuildContext context,
    ThemeData theme,
    AppThemeExtension appTheme,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appTheme.surface,
          title: Text(
            'Reset Database',
            style: theme.textTheme.titleLarge?.copyWith(
              color: appTheme.primaryText,
            ),
          ),
          content: Text(
            'This will delete all progress and restore the default cards. This action cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: appTheme.primaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(color: appTheme.secondaryText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onResetDatabase?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await widget.databaseService.getCategoryTree();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviewDecks() async {
    try {
      final decks = await _getReviewDecks();
      setState(() {
        _reviewDecks = decks;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<List<ReviewDeck>> _getReviewDecks() async {
    // This should be implemented based on your existing review deck logic
    return [];
  }

  void _openReviewScreen(ReviewDeck deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          databaseService: widget.databaseService,
          categoryId: deck.categoryId,
          categoryName: deck.name,
        ),
      ),
    );
  }

  void _openSpacedRepetitionSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpacedRepetitionSettingsScreen(),
      ),
    );
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

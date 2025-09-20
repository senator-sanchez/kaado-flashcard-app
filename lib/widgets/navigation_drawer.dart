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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Drawer(
      backgroundColor: appTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, appTheme),
            Expanded(
              child: _buildCurrentView(theme, appTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppThemeExtension appTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: appTheme.appBarBackground,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: AppSizes.shadowBlurSmall,
            offset: Offset(0, AppSizes.shadowOffsetSmall),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: appTheme.appBarIcon,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXSmall),
          Text(
            'v${AppStrings.appVersion}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: appTheme.appBarIcon.withOpacity(0.8),
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
      case DrawerView.spacedRepetition:
        return _buildSpacedRepetitionView(theme, appTheme);
      case DrawerView.settings:
        return _buildSettingsContent(theme, appTheme);
    }
  }

  Widget _buildMainMenu(ThemeData theme, AppThemeExtension appTheme) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      children: [
        _buildMenuTile(
          icon: Icons.library_books,
          title: 'Cards Browse and select category',
          onTap: () => _navigateToView(DrawerView.cards),
          theme: theme,
          appTheme: appTheme,
        ),
        _buildMenuTile(
          icon: Icons.quiz,
          title: 'Review',
          onTap: () => _navigateToView(DrawerView.review),
          theme: theme,
          appTheme: appTheme,
        ),
        _buildMenuTile(
          icon: Icons.schedule,
          title: 'Spaced Repetition',
          onTap: () => _navigateToView(DrawerView.spacedRepetition),
          theme: theme,
          appTheme: appTheme,
        ),
        const SizedBox(height: AppSizes.spacingLarge),
        _buildMenuTile(
          icon: Icons.settings,
          title: AppStrings.settings,
          onTap: () => _navigateToView(DrawerView.settings),
          theme: theme,
          appTheme: appTheme,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
    required AppThemeExtension appTheme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSmall),
      color: appTheme.cardBackground,
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: appTheme.primaryText,
          size: AppSizes.iconMedium,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: appTheme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: appTheme.secondaryText,
          size: AppSizes.iconSmall,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildCardsView(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        _buildBackButton(theme, appTheme),
        const SectionHeader(title: 'Select Category'),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryTile(category, theme, appTheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
    Category category,
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
        title: Text(
          category.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: appTheme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: category.description != null
            ? Text(
                category.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: appTheme.secondaryText,
                ),
              )
            : null,
        trailing: Text(
          '${category.cardCount} cards',
          style: theme.textTheme.bodySmall?.copyWith(
            color: appTheme.secondaryText,
          ),
        ),
        onTap: () {
          widget.onCategorySelected?.call(category.id);
          Navigator.of(context).pop();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildReviewView(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      children: [
        _buildBackButton(theme, appTheme),
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
        _buildBackButton(theme, appTheme),
        const SectionHeader(title: 'Spaced Repetition'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              children: [
                _buildMenuTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () => _openSpacedRepetitionSettings(),
                  theme: theme,
                  appTheme: appTheme,
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
        _buildBackButton(theme, appTheme),
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
          ? appTheme.primaryText.withOpacity(0.1)
          : appTheme.cardBackground,
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.primaryColor : appTheme.primaryText,
          size: AppSizes.iconMedium,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isSelected ? theme.primaryColor : appTheme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: appTheme.secondaryText,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: AppSizes.iconSmall,
              )
            : null,
        onTap: () {
          widget.onThemeChanged?.call(themeMode);
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

  Widget _buildBackButton(ThemeData theme, AppThemeExtension appTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: appTheme.surface,
        border: Border(
          bottom: BorderSide(
            color: appTheme.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _navigateToView(DrawerView.main),
            icon: Icon(
              Icons.arrow_back,
              color: appTheme.primaryText,
              size: AppSizes.iconMedium,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: AppSizes.spacingSmall),
          Text(
            AppStrings.back,
            style: theme.textTheme.titleMedium?.copyWith(
              color: appTheme.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToView(DrawerView view) {
    setState(() {
      _currentView = view;
    });
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

// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/category.dart';
import '../models/incorrect_card.dart';

// Project imports - Services
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/spaced_repetition_service.dart';

// Project imports - Utils
import '../utils/constants.dart';
import '../utils/theme_colors.dart';

// Project imports - Constants
import '../constants/app_colors.dart';

// Project imports - Screens
import '../screens/review_screen.dart';
import '../screens/spaced_repetition_settings_screen.dart';

// Project imports - Widgets
import 'shared/drawer_tile.dart';
import 'shared/section_header.dart';
import 'background_photo_settings_traditional.dart';

class KaadoNavigationDrawer extends StatefulWidget {
  final DatabaseService databaseService;
  final Function(int categoryId)? onCategorySelected;
  final VoidCallback? onResetDatabase;
  final Function(AppTheme)? onThemeChanged;
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

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.instance;
    
    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        children: [
          // Compact header that matches theme
          Container(
            padding: EdgeInsets.fromLTRB(AppConstants.themeTilePadding, MediaQuery.of(context).padding.top + AppConstants.themeTileTopPadding, AppConstants.themeTilePadding, AppConstants.themeTilePadding),
            decoration: BoxDecoration(color: colors.backgroundColor),
            child: Row(
              children: [
                if (_currentView != DrawerView.main)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.primaryIcon),
                    onPressed: () {
                      widget.onCloseFab?.call(); // Close FAB when going back
                      setState(() => _currentView = DrawerView.main);
                    },
                  ),
                Expanded(
                  child: Text(
                    'Kaado',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: AppConstants.themeTitleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show content based on current view
          Expanded(
            child: _buildCurrentView(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(ThemeColors colors) {
    switch (_currentView) {
      case DrawerView.main:
        return _buildMainMenu(colors);
      case DrawerView.cards:
        return _buildCardsView(colors);
      case DrawerView.review:
        return _buildReviewView(colors);
      case DrawerView.spacedRepetition:
        return _buildSpacedRepetitionView(colors);
      case DrawerView.settings:
        return _buildSettingsContent(colors);
    }
  }

  Widget _buildMainMenu(ThemeColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppConstants.categorySpacingLarge,
      ),
      child: Column(
        children: [
          SizedBox(height: AppConstants.categorySpacing),
          
          // Cards Option
          DrawerTile(
            title: 'Cards',
            subtitle: 'Browse and select flashcard categories',
            icon: Icons.style,
            onTap: () {
              widget.onCloseFab?.call(); // Close FAB when navigating to cards
              setState(() => _currentView = DrawerView.cards);
            },
          ),
          
          SizedBox(height: AppConstants.categorySpacingSmall),
          
          // Review Option
          DrawerTile(
            title: 'Review',
            subtitle: 'Practice incorrect cards',
            icon: Icons.refresh,
            onTap: () {
              widget.onCloseFab?.call(); // Close FAB when navigating to review
              setState(() => _currentView = DrawerView.review);
            },
          ),
          
          SizedBox(height: AppConstants.categorySpacingSmall),
          
          // Spaced Repetition Option
          DrawerTile(
            title: 'Daily Review',
            subtitle: 'Cards due for spaced repetition',
            icon: Icons.schedule,
            onTap: () {
              widget.onCloseFab?.call(); // Close FAB when navigating to spaced repetition
              setState(() => _currentView = DrawerView.spacedRepetition);
            },
          ),
          
          SizedBox(height: AppConstants.categorySpacingSmall),
          
          // Settings Option
          DrawerTile(
            title: 'Settings',
            subtitle: 'Customize app appearance and data',
            icon: Icons.settings,
            onTap: () {
              widget.onCloseFab?.call(); // Close FAB when navigating to settings
              setState(() => _currentView = DrawerView.settings);
            },
          ),
          
          SizedBox(height: AppConstants.categorySpacingLarge),
          
          // About section
          Divider(color: colors.divider),
          SectionHeader(title: 'About', icon: Icons.info_outline),
          
          _buildInfoTile(
            'Version',
            AppConstants.appVersion,
            Icons.info,
            colors,
          ),
          
          _buildInfoTile(
            'Developer',
            'Kaado Team',
            Icons.person,
            colors,
          ),
          
          _buildInfoTile(
            'Description',
            'Japanese Language Learning',
            Icons.school,
            colors,
          ),
        ],
      ),
    );
  }


  Widget _buildCardsView(ThemeColors colors) {
    return FutureBuilder<List<Category>>(
      future: widget.databaseService.getCategoryTree(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading categories'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No categories found'));
        }
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppConstants.categorySpacingLarge,
          ),
          children: _buildCategoryList(snapshot.data!),
        );
      },
    );
  }

  Widget _buildReviewView(ThemeColors colors) {
    return FutureBuilder<List<ReviewDeck>>(
      future: widget.databaseService.getReviewDecks(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading review decks'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: AppConstants.drawerIconSize,
                  color: colors.secondaryIcon,
                ),
                SizedBox(height: AppConstants.drawerSpacingMedium),
                Text(
                  'No incorrect cards to review!',
                  style: TextStyle(
                    fontSize: AppConstants.drawerTitleSize,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryText,
                  ),
                ),
                SizedBox(height: AppConstants.drawerSpacingSmall),
                Text(
                  'Great job! All your cards are correct.',
                  style: TextStyle(
                    fontSize: AppConstants.drawerSubtitleSize,
                    color: colors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppConstants.categorySpacingLarge,
          ),
          children: [
            // Header with total incorrect cards
            Container(
              margin: EdgeInsets.all(AppConstants.categorySpacing),
              padding: EdgeInsets.all(AppConstants.cardPadding),
              decoration: BoxDecoration(
                color: colors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh,
                    color: colors.primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Incorrect Cards',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryText,
                          ),
                        ),
                        Text(
                          'Practice cards you got wrong to improve your learning',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // List of review decks
            ...snapshot.data!.map((deck) => _buildReviewDeckTile(deck, colors)),
          ],
        );
      },
    );
  }

  Widget _buildReviewDeckTile(ReviewDeck deck, ThemeColors colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.categorySpacing, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: deck.isFullyReviewed ? colors.completionGold : colors.primaryBlue,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            deck.isFullyReviewed ? Icons.check : Icons.refresh,
            color: colors.buttonTextOnColored,
            size: 24,
          ),
        ),
        title: Text(
          deck.categoryName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colors.primaryText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${deck.incorrectCards} incorrect cards',
              style: TextStyle(
                fontSize: 14,
                color: colors.secondaryText,
              ),
            ),
            if (deck.incorrectCards > 0) ...[
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: deck.reviewProgress,
                backgroundColor: colors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  deck.isFullyReviewed ? colors.completionGold : colors.primaryBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                deck.isFullyReviewed 
                    ? 'All reviewed!' 
                    : '${deck.reviewedCards}/${deck.incorrectCards} reviewed',
                style: TextStyle(
                  fontSize: 12,
                  color: deck.isFullyReviewed ? colors.completionGold : colors.secondaryText,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colors.secondaryIcon,
        ),
        onTap: () {
          // Navigate to review screen
          widget.onCloseFab?.call(); // Close FAB
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ReviewScreen(
                categoryId: deck.categoryId,
                categoryName: deck.categoryName,
                databaseService: widget.databaseService,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpacedRepetitionView(ThemeColors colors) {
    return FutureBuilder<Map<String, int>>(
      future: widget.databaseService.getOverallReviewStats(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading spaced repetition data'));
        }
        
        final stats = snapshot.data ?? {};
        final totalCards = stats['total'] ?? 0;
        final newCards = stats['new'] ?? 0;
        final reviewCards = stats['review'] ?? 0;
        final overdueCards = stats['overdue'] ?? 0;
        final totalDue = reviewCards + overdueCards;
        
        if (totalDue == 0 && newCards == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: AppConstants.drawerIconSize,
                  color: colors.secondaryIcon,
                ),
                SizedBox(height: AppConstants.drawerSpacingMedium),
                Text(
                  'No cards due for review!',
                  style: TextStyle(
                    fontSize: AppConstants.drawerTitleSize,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryText,
                  ),
                ),
                SizedBox(height: AppConstants.drawerSpacingSmall),
                Text(
                  'Great job! All your cards are up to date.',
                  style: TextStyle(
                    fontSize: AppConstants.drawerSubtitleSize,
                    color: colors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppConstants.categorySpacingLarge,
          ),
          children: [
            // Header with overall stats
            Container(
              margin: EdgeInsets.all(AppConstants.categorySpacing),
              padding: EdgeInsets.all(AppConstants.cardPadding),
              decoration: BoxDecoration(
                color: colors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: colors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: colors.primaryBlue,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.primaryText,
                              ),
                            ),
                            Text(
                              'Cards scheduled for spaced repetition review',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Due Today',
                          totalDue.toString(),
                          colors.primaryBlue,
                          colors,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'New Cards',
                          newCards.toString(),
                          colors.secondaryIcon,
                          colors,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          totalCards.toString(),
                          colors.secondaryText,
                          colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Quick action buttons
            if (totalDue > 0)
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppConstants.categorySpacing),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to review all due cards
                          Navigator.of(context).pop();
                          // This would need to be implemented to load all due cards
                        },
                        icon: Icon(Icons.play_arrow, color: colors.buttonTextOnColored),
                        label: Text(
                          'Review All Due Cards ($totalDue)',
                          style: TextStyle(color: colors.buttonTextOnColored),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryBlue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                          ),
                        ),
                      ),
                    ),
                    if (overdueCards > 0) ...[
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to review overdue cards first
                            Navigator.of(context).pop();
                            // This would need to be implemented to load overdue cards
                          },
                          icon: Icon(Icons.warning, color: colors.buttonTextOnColored),
                          label: Text(
                            'Review Overdue Cards ($overdueCards)',
                            style: TextStyle(color: colors.buttonTextOnColored),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            SizedBox(height: AppConstants.categorySpacing),
            
            // Info section
            Container(
              margin: EdgeInsets.symmetric(horizontal: AppConstants.categorySpacing),
              padding: EdgeInsets.all(AppConstants.cardPadding),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Spaced Repetition Works',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• New cards start with 1-day intervals\n'
                    '• Correct answers increase the interval\n'
                    '• Incorrect answers reset to 1-day\n'
                    '• Overdue cards need immediate attention',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(ThemeColors colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppConstants.categorySpacingLarge,
      ),
      child: Column(
        children: [
          // Theme Section
          SectionHeader(title: 'Appearance', icon: Icons.palette),
          
          // Theme Options
          _buildThemeTile(
            context,
            AppTheme.light,
            'Light Mode',
            'Clean white background',
            Icons.light_mode,
            colors,
          ),
          _buildThemeTile(
            context,
            AppTheme.dark,
            'Dark Mode',
            'Dark background for low light',
            Icons.dark_mode,
            colors,
          ),
          
          Divider(height: AppConstants.dividerHeight, color: colors.divider),
          
          // Background Photo Settings
          const BackgroundPhotoSettingsTraditional(),
          
          Divider(height: AppConstants.dividerHeight, color: colors.divider),
          
          // Learning Section
          SectionHeader(title: 'Learning Settings', icon: Icons.school),
          
          _buildActionTile(
            context,
            'Spaced Repetition Settings',
            'Customize review intervals and learning pace',
            Icons.schedule,
            colors,
            () async {
              // Load current settings from database
              final currentSettings = await widget.databaseService.loadSpacedRepetitionSettings();
              
              // Navigate to settings screen without closing drawer first
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
            },
          ),
          
          Divider(height: AppConstants.dividerHeight, color: colors.divider),
          
          // Data Section
          SectionHeader(title: 'Data & Storage', icon: Icons.storage),
          
          _buildResetDatabaseTile(context, colors),
          
          Divider(height: AppConstants.dividerHeight, color: colors.divider),
        ],
      ),
    );
  }


  Widget _buildThemeTile(
    BuildContext context,
    AppTheme theme,
    String title,
    String subtitle,
    IconData icon,
    ThemeColors colors,
  ) {
    final themeService = ThemeService();
    final isSelected = themeService.currentTheme == theme;
    
    return ListTile(
      leading: Container(
        width: AppConstants.themeTileSize,
        height: AppConstants.themeTileSize,
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryBlue : colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.themeTileBorderRadius),
          border: Border.all(
            color: isSelected ? colors.primaryBlue : colors.divider,
            width: AppConstants.themeTileBorderWidth,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colors.primaryBlue.withValues(alpha: AppConstants.themeShadowAlpha),
              blurRadius: AppConstants.themeShadowBlur,
              offset: const Offset(0, AppConstants.themeShadowOffset),
            ),
          ] : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.buttonTextOnColored : colors.primaryIcon,
          size: AppConstants.themeIconSize,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.primaryText,
          fontWeight: isSelected ? AppConstants.themeSelectedWeight : AppConstants.themeNormalWeight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colors.secondaryText,
          fontSize: AppConstants.categoryCountSize,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: colors.primaryBlue,
              size: AppConstants.themeIconSize,
            )
          : null,
      onTap: () {
        widget.onCloseFab?.call(); // Close FAB when changing theme
        widget.onThemeChanged?.call(theme);
        setState(() {}); // Refresh to show new selection
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ThemeColors colors,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: AppConstants.themeTileSize,
        height: AppConstants.themeTileSize,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.themeTileBorderRadius),
          border: Border.all(color: colors.divider),
        ),
        child: Icon(
          icon,
          color: colors.primaryIcon,
          size: AppConstants.themeIconSize,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.primaryText,
          fontWeight: AppConstants.categoryWeight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colors.secondaryText,
          fontSize: AppConstants.categoryCountSize,
        ),
      ),
      onTap: () {
        widget.onCloseFab?.call(); // Close FAB when performing action
        onTap(); // Call the provided callback directly
      },
    );
  }

  Widget _buildResetDatabaseTile(BuildContext context, ThemeColors colors) {
    return ListTile(
      leading: Container(
        width: AppConstants.themeTileSize,
        height: AppConstants.themeTileSize,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.themeTileBorderRadius),
          border: Border.all(color: colors.divider),
        ),
        child: Icon(
          Icons.refresh,
          color: colors.primaryIcon,
          size: AppConstants.themeIconSize,
        ),
      ),
      title: Text(
        'Reset Database Connection',
        style: TextStyle(
          color: colors.primaryText,
          fontWeight: AppConstants.categoryWeight,
        ),
      ),
      subtitle: Text(
        'Clear cached data and reconnect',
        style: TextStyle(
          color: colors.secondaryText,
          fontSize: AppConstants.categoryCountSize,
        ),
      ),
      onTap: () {
        widget.onCloseFab?.call(); // Close FAB when performing action
        _showResetConfirmation(context, widget.onResetDatabase ?? () {}, colors);
      },
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    ThemeColors colors,
  ) {
    return ListTile(
      leading: Container(
        width: AppConstants.themeTileSize,
        height: AppConstants.themeTileSize,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.themeTileBorderRadius),
          border: Border.all(color: colors.divider),
        ),
        child: Icon(
          icon,
          color: colors.primaryIcon,
          size: AppConstants.themeIconSize,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.primaryText,
          fontWeight: AppConstants.categoryWeight,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: colors.secondaryText,
          fontSize: AppConstants.categoryCountSize,
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, VoidCallback onConfirm, ThemeColors colors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Reset Database',
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will clear all cached data and reconnect to the database. Are you sure?',
            style: TextStyle(
              color: colors.primaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.secondaryText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                'Reset',
                style: TextStyle(
                  color: colors.primaryBlue,
                  fontWeight: AppConstants.themeSelectedWeight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCategoryList(List<Category> categories) {
    return categories.map((category) {
      return _buildCategoryTile(category);
    }).toList();
  }

  Widget _buildCategoryTile(Category category) {
    final colors = ThemeColors.instance;
    
    return Builder(
      builder: (context) {
    // If it's a bottom-level category (has cards), show as ListTile
    if (category.isCardCategory) {
      return ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontWeight: AppConstants.themeSelectedWeight, 
                  fontSize: AppConstants.categoryTitleSize,
                  color: colors.primaryText,
                ),
              ),
            ),
            if (category.cardCount > 0)
              Container(
                margin: const EdgeInsets.only(left: AppConstants.categoryBadgeMargin),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.categoryBadgePadding, 
                  vertical: 2
                ),
                decoration: BoxDecoration(
                  color: colors.primaryBlue,
                  borderRadius: BorderRadius.circular(AppConstants.categoryBadgeRadius),
                ),
                child: Text(
                  '${category.cardCount}',
                  style: TextStyle(
                    color: colors.buttonTextOnColored, 
                    fontSize: AppConstants.cardCountSize
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Close the drawer and load cards for this category
          Navigator.of(context).pop();
          widget.onCloseFab?.call(); // Close FAB when selecting category
          if (widget.onCategorySelected != null) {
            widget.onCategorySelected!(category.id);
          }
        },
      );
    }
    
    // If it has children, show as ExpansionTile
    if (category.children != null && category.children!.isNotEmpty) {
      return ExpansionTile(
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: AppConstants.themeSelectedWeight, 
            fontSize: AppConstants.categoryTitleSize,
            color: colors.primaryText,
          ),
        ),
        maintainState: true,
        initiallyExpanded: category.parentId == null, // Auto-expand top-level categories
        children: category.children!.map((subcategory) {
          return Padding(
            padding: const EdgeInsets.only(left: AppConstants.themeTilePadding),
            child: _buildCategoryTile(subcategory),
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
          color: colors.primaryText,
        ),
      ),
    );
      }
    );
  }
}

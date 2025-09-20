// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Screens
import 'home_screen.dart';
import 'library_screen.dart';

// Project imports - Constants
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

// Project imports - Utils
import '../utils/app_theme.dart';

/// Main navigation screen with bottom navigation bar
/// 
/// This screen provides the main navigation structure for the app with:
/// - Bottom navigation bar for switching between Home and Library
/// - Consistent theming across all screens
/// - Proper state management for navigation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appTheme.appBarBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: AppSizes.shadowBlurMedium,
              offset: const Offset(0, -AppSizes.shadowOffsetSmall),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: appTheme.secondaryText,
          selectedLabelStyle: TextStyle(
            fontSize: AppSizes.fontSmall,
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: AppSizes.fontSmall,
            fontWeight: FontWeight.w400,
            color: appTheme.secondaryText,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, color: appTheme.secondaryText),
              activeIcon: Icon(Icons.home, color: theme.primaryColor),
              label: AppStrings.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined, color: appTheme.secondaryText),
              activeIcon: Icon(Icons.library_books, color: theme.primaryColor),
              label: AppStrings.library,
            ),
          ],
        ),
      ),
    );
  }
}

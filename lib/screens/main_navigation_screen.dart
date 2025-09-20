// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Screens
import 'home_screen.dart';
import 'library_screen.dart';

// Project imports - Utils
import '../utils/theme_colors.dart';

// Project imports - Constants
import '../constants/app_sizes.dart';
import '../constants/app_colors.dart';

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
    final colors = ThemeColors.instance;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.appBarBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: AppSizes.shadowBlurMedium,
              offset: Offset(0, -AppSizes.shadowOffsetSmall),
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
          selectedItemColor: colors.primaryBlue,
          unselectedItemColor: colors.secondaryText,
          selectedLabelStyle: TextStyle(
            fontSize: AppSizes.spacingSmall,
            fontWeight: FontWeight.w600,
            color: colors.primaryBlue,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: AppSizes.spacingSmall,
            fontWeight: FontWeight.w400,
            color: colors.secondaryText,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, color: colors.secondaryText),
              activeIcon: Icon(Icons.home, color: colors.primaryBlue),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined, color: colors.secondaryText),
              activeIcon: Icon(Icons.library_books, color: colors.primaryBlue),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}

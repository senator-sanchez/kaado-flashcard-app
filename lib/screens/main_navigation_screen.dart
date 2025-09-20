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
        height: 80,
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
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                      color: _currentIndex == 0 
                          ? appTheme.appBarIcon 
                          : appTheme.appBarIcon.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.home,
                      style: TextStyle(
                        fontSize: AppSizes.fontSmall,
                        fontWeight: _currentIndex == 0 ? FontWeight.w600 : FontWeight.w400,
                        color: _currentIndex == 0 
                            ? appTheme.appBarIcon 
                            : appTheme.appBarIcon.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentIndex == 1 ? Icons.library_books : Icons.library_books_outlined,
                      color: _currentIndex == 1 
                          ? appTheme.appBarIcon 
                          : appTheme.appBarIcon.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.library,
                      style: TextStyle(
                        fontSize: AppSizes.fontSmall,
                        fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.w400,
                        color: _currentIndex == 1 
                            ? appTheme.appBarIcon 
                            : appTheme.appBarIcon.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

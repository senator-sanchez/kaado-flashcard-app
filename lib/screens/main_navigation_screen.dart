// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports - Screens
import 'home_screen.dart';
import 'library_screen.dart';

// Project imports - Constants
// Removed unused imports after removing text labels

// Project imports - Utils
import '../utils/app_theme.dart';
import '../utils/system_ui_utils.dart';

/// Main navigation screen with bottom navigation bar
/// 
/// This screen provides the main navigation structure for the app with:
/// - Bottom navigation bar for switching between Home and Library
/// - Consistent theming across all screens
/// - Proper state management for navigation
/// - Android system navigation bar detection and padding
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    
    // Get system navigation bar height (Android's 3-line navigation)
    final systemNavigationBarHeight = SystemUIUtils.getSystemNavigationBarHeight(context);
    final hasSystemNavBar = SystemUIUtils.hasSystemNavigationBar(context);
    
    // Calculate total height: reduced height + system navigation bar
    final baseHeight = 60.0; // Reduced from default
    final totalBottomBarHeight = baseHeight + systemNavigationBarHeight;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: IndexedStack(
        key: ValueKey(_currentIndex), // Force rebuild when switching screens
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: totalBottomBarHeight,
        decoration: BoxDecoration(
          color: appTheme.appBarBackground,
        ),
        child: Column(
          children: [
            // Main navigation content
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                      child: Center(
                        child: Icon(
                          _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                          color: _currentIndex == 0 
                              ? appTheme.appBarIcon 
                              : appTheme.appBarIcon.withValues(alpha: 0.7),
                          size: 28,
                        ),
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
                      child: Center(
                        child: Icon(
                          _currentIndex == 1 ? Icons.library_books : Icons.library_books_outlined,
                          color: _currentIndex == 1 
                              ? appTheme.appBarIcon 
                              : appTheme.appBarIcon.withValues(alpha: 0.7),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // System navigation bar padding
            if (hasSystemNavBar)
              Container(
                height: systemNavigationBarHeight,
                color: appTheme.appBarBackground,
              ),
          ],
        ),
      ),
    );
  }
}

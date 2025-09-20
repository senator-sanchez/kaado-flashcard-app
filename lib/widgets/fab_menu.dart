// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Utils
import '../utils/app_theme.dart';

/// A Floating Action Button (FAB) menu that provides access to Shuffle and Reset actions.
/// 
/// This widget displays a circular FAB that expands to show menu items when tapped.
/// The menu items appear above the FAB and include Shuffle and Reset buttons.
/// All colors are theme-aware and adapt to the current app theme.
class FabMenu extends StatefulWidget {
  /// Callback function executed when the Shuffle button is pressed
  final VoidCallback? onShuffle;
  
  /// Callback function executed when the Reset button is pressed
  final VoidCallback onReset;
  
  /// Whether the FAB menu is enabled (affects button interactivity)
  final bool isEnabled;

  const FabMenu({
    super.key,
    this.onShuffle,
    required this.onReset,
    this.isEnabled = true,
  });

  @override
  State<FabMenu> createState() => FabMenuState();
}

/// State class for the FabMenu widget
class FabMenuState extends State<FabMenu> with TickerProviderStateMixin {
  /// Tracks whether the menu is currently open or closed
  bool _isOpen = false;
  
  /// Animation controller for menu transitions
  late AnimationController _animationController;
  
  /// Animation for menu items sliding up
  late Animation<double> _slideAnimation;
  
  /// Animation for menu items fading in/out
  late Animation<double> _fadeAnimation;
  
  /// Animation for FAB icon rotation
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize all animations for the FAB menu
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Slide animation: menu items slide up from below
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Fade animation: menu items fade in/out
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation: FAB icon rotates when opening/closing
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees (0.125 * 360)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  /// Toggles the menu state between open and closed
  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    
    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  /// Closes the menu if it's currently open
  /// This method can be called from parent widgets to close the menu
  void closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
      });
      _animationController.reverse();
    }
  }

  /// Builds a menu item button with consistent styling
  /// 
  /// [icon] - The icon to display in the button
  /// [label] - The text label for the button
  /// [color] - The background color of the button
  /// [textColor] - The text and icon color
  /// [onPressed] - Callback function when the button is pressed
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Animated menu items (appear above the FAB when open)
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _slideAnimation.value) * 50),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _isOpen ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onShuffle != null)
                      _buildMenuItem(
                        icon: Icons.shuffle,
                        label: 'Shuffle',
                        color: theme.primaryColor,
                        textColor: appTheme.buttonTextOnColored,
                        onPressed: () {
                          widget.onShuffle!();
                          closeMenu();
                        },
                      ),
                    _buildMenuItem(
                      icon: Icons.refresh,
                      label: 'Reset',
                      color: theme.primaryColor,
                      textColor: appTheme.buttonTextOnColored,
                      onPressed: () {
                        widget.onReset();
                        closeMenu();
                      },
                    ),
                  ],
                ) : const SizedBox.shrink(),
              ),
            );
          },
        ),
        // Main FAB with rotation animation
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
              child: FloatingActionButton(
                onPressed: _toggleMenu,
                backgroundColor: theme.primaryColor,
                foregroundColor: appTheme.buttonTextOnColored,
                shape: const CircleBorder(),
                child: Icon(_isOpen ? Icons.close : Icons.add),
              ),
            );
          },
        ),
      ],
    );
  }
}
// Flutter imports
import 'package:flutter/material.dart';

/// Custom animated drawer that slides in from left to right
/// 
/// This widget provides a custom drawer implementation with:
/// - Slide-in animation from left to right
/// - Smooth animation transitions
/// - Proper gesture handling for closing
/// - Customizable animation duration and curve
class CustomAnimatedDrawer extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Curve animationCurve;
  final double drawerWidth;

  const CustomAnimatedDrawer({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.drawerWidth = 280.0,
  });

  @override
  State<CustomAnimatedDrawer> createState() => _CustomAnimatedDrawerState();
}

class _CustomAnimatedDrawerState extends State<CustomAnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Slide animation from left to right
    _slideAnimation = Tween<double>(
      begin: -1.0, // Start completely off-screen to the left
      end: 0.0,    // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    // Fade animation for smooth appearance
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    // Start the animation immediately
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            if (_animationController.value > 0)
              GestureDetector(
                onTap: _closeDrawer,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5 * _fadeAnimation.value),
                ),
              ),
            
            // Drawer content
            Positioned(
              left: _slideAnimation.value * widget.drawerWidth,
              top: 0,
              bottom: 0,
              width: widget.drawerWidth,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }

  void _closeDrawer() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

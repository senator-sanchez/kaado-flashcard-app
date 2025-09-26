import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_photo_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// Widget that provides background for the app
/// Can display either a solid color or a background photo
class BackgroundWidget extends ConsumerStatefulWidget {
  final Widget child;
  final bool showBackgroundPhoto;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.showBackgroundPhoto = true,
  });

  @override
  ConsumerState<BackgroundWidget> createState() => _BackgroundWidgetState();
}

class _BackgroundWidgetState extends ConsumerState<BackgroundWidget> {
  final BackgroundPhotoService _backgroundPhotoService = BackgroundPhotoService.instance;

  @override
  void initState() {
    super.initState();
    _backgroundPhotoService.addListener(_onBackgroundPhotoChanged);
  }

  @override
  void dispose() {
    _backgroundPhotoService.removeListener(_onBackgroundPhotoChanged);
    super.dispose();
  }

  void _onBackgroundPhotoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final hasBackgroundPhoto = _backgroundPhotoService.hasBackgroundPhoto;
    final backgroundPhotoPath = _backgroundPhotoService.backgroundPhotoPath;

    return Container(
      decoration: _buildBackgroundDecoration(appTheme, hasBackgroundPhoto, backgroundPhotoPath),
      child: widget.child,
    );
  }

  BoxDecoration _buildBackgroundDecoration(
    AppThemeExtension appTheme,
    bool hasBackgroundPhoto,
    String? backgroundPhotoPath,
  ) {
    if (widget.showBackgroundPhoto && hasBackgroundPhoto && backgroundPhotoPath != null) {
      // Use background photo
      return BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundPhotoPath),
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Use solid color background
      return BoxDecoration(
        color: appTheme.backgroundColor,
      );
    }
  }
}

/// Alternative implementation using File image for local photos (Traditional State Management)
class BackgroundWidgetWithFile extends ConsumerStatefulWidget {
  final Widget child;
  final bool showBackgroundPhoto;

  const BackgroundWidgetWithFile({
    super.key,
    required this.child,
    this.showBackgroundPhoto = true,
  });

  @override
  ConsumerState<BackgroundWidgetWithFile> createState() => _BackgroundWidgetWithFileState();
}

class _BackgroundWidgetWithFileState extends ConsumerState<BackgroundWidgetWithFile> {
  final BackgroundPhotoService _backgroundPhotoService = BackgroundPhotoService.instance;

  @override
  void initState() {
    super.initState();
    _backgroundPhotoService.addListener(_onBackgroundPhotoChanged);
  }

  @override
  void dispose() {
    _backgroundPhotoService.removeListener(_onBackgroundPhotoChanged);
    super.dispose();
  }

  void _onBackgroundPhotoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final hasBackgroundPhoto = _backgroundPhotoService.hasBackgroundPhoto;

    return Container(
      decoration: _buildBackgroundDecoration(appTheme, hasBackgroundPhoto, _backgroundPhotoService),
      child: widget.child,
    );
  }

  BoxDecoration _buildBackgroundDecoration(
    AppThemeExtension appTheme,
    bool hasBackgroundPhoto,
    backgroundPhotoService,
  ) {
    if (widget.showBackgroundPhoto && hasBackgroundPhoto) {
      final backgroundPath = backgroundPhotoService.backgroundPhotoPath;
      if (backgroundPath != null) {
        // Check if it's a default asset or a file
        if (backgroundPath.startsWith(AppConstants.assetsPath)) {
          // Use asset image
          return BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundPath),
              fit: BoxFit.cover,
            ),
          );
        } else {
          // Use file image
          final backgroundFile = backgroundPhotoService.backgroundPhotoFile;
          if (backgroundFile != null) {
            return BoxDecoration(
              image: DecorationImage(
                image: FileImage(backgroundFile),
                fit: BoxFit.cover,
              ),
            );
          }
        }
      }
    }
    
    // Use solid color background
    return BoxDecoration(
        color: appTheme.backgroundColor,
    );
  }
}

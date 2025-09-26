import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_photo_service.dart';
import '../services/theme_service.dart';
import '../services/app_logger.dart';
import '../utils/app_theme.dart';
import 'background_selector_dialog.dart';

/// Widget for managing background photo settings (Traditional State Management)
class BackgroundPhotoSettingsTraditional extends ConsumerStatefulWidget {
  const BackgroundPhotoSettingsTraditional({super.key});

  @override
  ConsumerState<BackgroundPhotoSettingsTraditional> createState() =>
      _BackgroundPhotoSettingsTraditionalState();
}

class _BackgroundPhotoSettingsTraditionalState
    extends ConsumerState<BackgroundPhotoSettingsTraditional> {
  final BackgroundPhotoService _backgroundPhotoService =
      BackgroundPhotoService.instance;
  final ThemeService _themeService = ThemeService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _backgroundPhotoService.addListener(_onBackgroundPhotoChanged);
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _backgroundPhotoService.removeListener(_onBackgroundPhotoChanged);
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onBackgroundPhotoChanged() {
    if (mounted) {
      setState(() {
        _isLoading = _backgroundPhotoService.isLoading;
      });
    }
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
    final appTheme = context.appTheme;
    final hasBackgroundPhoto = _backgroundPhotoService.hasBackgroundPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Background Photo Header as ListTile
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: appTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appTheme.divider, width: 2),
            ),
            child: Icon(
              Icons.photo_library,
              color: appTheme.primaryIcon,
              size: 20,
            ),
          ),
          title: Text(
            'Background Photo',
            style: TextStyle(
              color: appTheme.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Customize your app background with a personal photo',
            style: TextStyle(color: appTheme.secondaryText, fontSize: 12),
          ),
        ),

        // Background Photo Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current status
              if (hasBackgroundPhoto) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: appTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: appTheme.primaryBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Custom background photo is set',
                          style: TextStyle(
                            color: appTheme.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Default backgrounds section
              if (_backgroundPhotoService.defaultBackgrounds.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Default Backgrounds',
                        style: TextStyle(
                          color: appTheme.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _showBackgroundSelector,
                      icon: Icon(
                        Icons.grid_view,
                        size: 16,
                        color: appTheme.primaryBlue,
                      ),
                      label: Text(
                        'Browse All',
                        style: TextStyle(
                          color: appTheme.primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Text(
                'Custom Backgrounds',
                style: TextStyle(
                  color: appTheme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionButton(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onPressed: _isLoading ? null : () => _pickFromGallery(),
                  ),
                  if (hasBackgroundPhoto)
                    _buildActionButton(
                      context: context,
                      icon: Icons.delete,
                      label: 'Remove',
                      onPressed: _isLoading ? null : () => _removePhoto(),
                      isDestructive: true,
                    ),
                ],
              ),

              // Loading indicator
              if (_isLoading) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          appTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Processing...',
                        style: TextStyle(
                          color: appTheme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final buttonColor = isDestructive ? theme.colorScheme.error : theme.primaryColor;
    // Use white text for colored buttons, regular button text for others
    final textColor = isDestructive
        ? appTheme.buttonTextOnColored
        : appTheme.buttonTextOnColored;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        shadowColor: buttonColor.withValues(alpha: 0.3),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting image picker...'),
          backgroundColor: context.appTheme.primaryBlue,
        ),
      );
      
      final success = await _backgroundPhotoService.pickBackgroundPhoto();

      if (success && mounted) {
        // Background photo updated from gallery
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Background photo updated successfully!'),
            backgroundColor: context.appTheme.correctButton,
          ),
        );
      } else {
        _showErrorMessage('Failed to pick photo from gallery');
      }
    } catch (e) {
      AppLogger.error('Error in _pickFromGallery', e);
      _showErrorMessage('Error picking photo: $e');
    }
  }

  Future<void> _removePhoto() async {
    await _backgroundPhotoService.removeBackgroundPhoto();
    // Background photo removed
  }

  void _showBackgroundSelector() {
    showDialog(
      context: context,
      builder: (context) => const BackgroundSelectorDialog(),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

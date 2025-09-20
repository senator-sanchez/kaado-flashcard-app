import 'package:flutter/material.dart';
import '../services/background_photo_service.dart';
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../utils/constants.dart';

/// Dialog for selecting background images from assets/backgrounds/
class BackgroundSelectorDialog extends StatefulWidget {
  const BackgroundSelectorDialog({super.key});

  @override
  State<BackgroundSelectorDialog> createState() => _BackgroundSelectorDialogState();
}

class _BackgroundSelectorDialogState extends State<BackgroundSelectorDialog> {
  final BackgroundPhotoService _backgroundPhotoService = BackgroundPhotoService.instance;
  String? _selectedBackground;

  @override
  void initState() {
    super.initState();
    _selectedBackground = _backgroundPhotoService.backgroundPhotoPath;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final defaultBackgrounds = _backgroundPhotoService.defaultBackgrounds;

    return Dialog(
      backgroundColor: appTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: appTheme.primaryIcon,
                  ),
                ),
                Icon(
                  Icons.image,
                  color: appTheme.primaryIcon,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Background',
                    style: TextStyle(
                      color: appTheme.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Background count
            Text(
              '${defaultBackgrounds.length} backgrounds available',
              style: TextStyle(
                color: appTheme.secondaryText,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Thumbnails grid
            Expanded(
              child: defaultBackgrounds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: appTheme.secondaryIcon,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No backgrounds found',
                            style: TextStyle(
                              color: appTheme.secondaryText,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add images to ${AppConstants.backgroundsPath} folder',
                            style: TextStyle(
                              color: appTheme.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: defaultBackgrounds.length,
                      itemBuilder: (context, index) {
                        final assetPath = defaultBackgrounds[index];
                        final isSelected = _selectedBackground == assetPath;
                        
                        return _buildThumbnailTile(
                          assetPath: assetPath,
                          isSelected: isSelected,
                          context: context,
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appTheme.primaryText,
                      side: BorderSide(color: appTheme.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedBackground != null
                        ? () => _applyBackground()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.primaryBlue,
                      foregroundColor: appTheme.buttonTextOnColored,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailTile({
    required String assetPath,
    required bool isSelected,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final fileName = assetPath.split('/').last.split('.').first;
    final displayName = fileName.replaceAll('_', ' ').toUpperCase();
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBackground = assetPath;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? appTheme.primaryBlue : appTheme.divider,
            width: isSelected ? 3 : 1,
          ),
          color: isSelected 
              ? appTheme.primaryBlue.withValues(alpha: 0.1)
              : appTheme.surface,
        ),
        child: Column(
          children: [
            // Thumbnail image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  image: DecorationImage(
                    image: AssetImage(assetPath),
                    fit: BoxFit.cover,
                  ),
                ),
                child: isSelected
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                          color: appTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_circle,
                            color: appTheme.buttonTextOnColored,
                            size: 32,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            
            // File name
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(11),
                  ),
                  color: isSelected 
                      ? appTheme.primaryBlue.withValues(alpha: 0.1)
                      : appTheme.surface,
                ),
                child: Center(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: isSelected ? appTheme.primaryBlue : appTheme.primaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyBackground() async {
    if (_selectedBackground != null) {
      await _backgroundPhotoService.setDefaultBackground(_selectedBackground!);
      if (mounted) {
        Navigator.of(context).pop();
        // Background applied successfully
      }
    }
  }
}

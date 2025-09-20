// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Constants
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

// Project imports - Models
import '../models/card_display_settings.dart';
import '../models/flashcard.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final bool showAnswer;
  final bool isCompleted;
  final VoidCallback onTap;
  final CardDisplaySettings? displaySettings;
  final VoidCallback? onEdit;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.showAnswer,
    required this.isCompleted,
    required this.onTap,
    this.displaySettings,
    this.onEdit,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    
    return GestureDetector(
      onTap: () {
        if (_showNotes) {
          setState(() {
            _showNotes = false;
          });
        } else {
          widget.onTap();
        }
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: AppConstants.isWeb(context) ? AppConstants.cardMinHeightWeb : AppConstants.cardMinHeight,
          maxHeight: AppConstants.isWeb(context) ? AppConstants.cardMinHeightWeb : AppConstants.cardMinHeight,
        ),
        decoration: BoxDecoration(
          color: appTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: AppSizes.shadowBlurMedium,
              offset: const Offset(0, AppSizes.shadowOffsetSmall),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.cardPadding),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isCompleted) ...[
                // Completion message
                Icon(
                  Icons.celebration,
                  size: AppConstants.cardCompletionIconSize,
                  color: theme.colorScheme.secondary,
                ),
                SizedBox(height: AppConstants.cardCompletionSpacing),
                Text(
                  'Deck Completed!',
                  style: TextStyle(
                    fontSize: AppConstants.cardCompletionTitleSize,
                    color: appTheme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.cardCompletionSubtitleSpacing),
                Text(
                  'Tap to reset',
                  style: TextStyle(
                    fontSize: AppConstants.cardCompletionSubtitleSize,
                    color: appTheme.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_showNotes && widget.flashcard.notes != null && widget.flashcard.notes!.isNotEmpty) ...[
                // Show only notes content
                _buildNotesContent(theme, appTheme),
              ] else ...[
                // Front of card - show selected front display type
                _buildCardContent(
                  theme,
                  appTheme,
                  _getFrontContent(),
                  isFront: true,
                ),
                
                if (widget.showAnswer) ...[
                  SizedBox(height: AppConstants.cardContentSpacing),
                  
                  // Back of card - show selected back display types
                  ..._getBackContent().map((content) => Padding(
                    padding: EdgeInsets.only(bottom: AppConstants.cardBackContentBottomPadding),
                    child: _buildCardContent(
                      theme,
                      appTheme,
                      content,
                      isFront: false,
                    ),
                  )),
                ],
              ],
            ],
          ),
        ),
      ),
        
        // Edit icon (only show when card is flipped)
        if (widget.showAnswer)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () {
                widget.onEdit?.call();
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.edit,
                  color: theme.primaryColor.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
          ),
        
        // Notes icon (only show if card has notes and not currently showing notes)
        if (widget.showAnswer && 
            widget.flashcard.notes != null && 
            widget.flashcard.notes!.isNotEmpty && 
            !_showNotes)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showNotes = true;
                });
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.note,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    ),
      ),
    );
  }

  /// Get the content to display on the front of the card
  String _getFrontContent() {
    final settings = widget.displaySettings ?? CardDisplaySettings.defaultSettings;
    
    switch (settings.frontDisplay) {
      case CardDisplayType.kana:
        return widget.flashcard.kana;
      case CardDisplayType.hiragana:
        return widget.flashcard.hiragana ?? widget.flashcard.kana;
      case CardDisplayType.english:
        return widget.flashcard.english;
      case CardDisplayType.romaji:
        return widget.flashcard.romaji ?? widget.flashcard.kana;
    }
  }

  /// Get the content to display on the back of the card
  List<CardContent> _getBackContent() {
    final settings = widget.displaySettings ?? CardDisplaySettings.defaultSettings;
    final List<CardContent> content = [];
    final String frontContent = _getFrontContent(); // Get the front text for comparison

    for (final displayType in settings.backDisplays) {
      // Skip if this display type is the same as the front display
      if (displayType == settings.frontDisplay) {
        continue;
      }
      
      String? text;
      switch (displayType) {
        case CardDisplayType.kana:
          text = widget.flashcard.kana;
          break;
        case CardDisplayType.hiragana:
          text = widget.flashcard.hiragana;
          break;
        case CardDisplayType.english:
          text = widget.flashcard.english;
          break;
        case CardDisplayType.romaji:
          text = widget.flashcard.romaji;
          break;
      }
      
      // Skip if the back content matches the front content (duplicate filtering)
      if (text != null && text == frontContent) {
        continue; // Don't show duplicate content
      }
      
      if (text != null) {
        content.add(CardContent(
          text: text,
          type: displayType,
        ));
      }
    }

    return content;
  }

  /// Check if text contains multiple words
  bool _isMultipleWords(String text) {
    return text.split(' ').length > 1;
  }

  /// Build card content with appropriate styling
  Widget _buildCardContent(ThemeData theme, AppThemeExtension appTheme, dynamic content, {required bool isFront}) {
    if (content is String) {
      // Front content - use FittedBox to scale text to fit
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            content,
            style: TextStyle(
              fontSize: AppConstants.cardFrontTextSize,
              color: appTheme.primaryText,
              fontWeight: AppConstants.cardTitleWeight,
            ),
            textAlign: TextAlign.center,
            maxLines: _isMultipleWords(content) ? AppConstants.multipleLinesMaxLines : AppConstants.singleLineMaxLines,
            overflow: _isMultipleWords(content) ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      );
    } else if (content is CardContent) {
      // Back content - use FittedBox for scaling
      final fontSize = _getFontSizeForType(content.type);
      final color = _getColorForType(content.type, appTheme);
      final fontWeight = _getFontWeightForType(content.type);
      final fontStyle = _getFontStyleForType(content.type);
      final isMultipleWords = _isMultipleWords(content.text);

      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            content.text,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
            ),
            textAlign: TextAlign.center,
            maxLines: isMultipleWords ? AppConstants.multipleLinesMaxLines : AppConstants.singleLineMaxLines,
            overflow: isMultipleWords ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      );
    }
    
    return SizedBox.shrink();
  }

  /// Get appropriate font size for display type
  double _getFontSizeForType(CardDisplayType type) {
    // Use uniform size for all back side elements
    return AppConstants.cardBackTextSize;
  }

  /// Get appropriate color for display type
  Color _getColorForType(CardDisplayType type, AppThemeExtension appTheme) {
    // Use uniform color for all back side elements
    return appTheme.primaryText;
  }

  /// Get appropriate font weight for display type
  FontWeight _getFontWeightForType(CardDisplayType type) {
    // Use uniform weight for all back side elements
    return AppConstants.cardBackWeight;
  }

  /// Get appropriate font style for display type
  FontStyle _getFontStyleForType(CardDisplayType type) {
    // Use uniform style for all back side elements
    return FontStyle.normal;
  }

  /// Build notes content display
  Widget _buildNotesContent(ThemeData theme, AppThemeExtension appTheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.cardPadding),
        child: Text(
          widget.flashcard.notes!,
          style: TextStyle(
            fontSize: AppConstants.cardBackTextSize,
            color: appTheme.primaryText,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: null, // Allow unlimited lines
          overflow: TextOverflow.visible, // Prevent clipping
        ),
      ),
    );
  }
}

/// Helper class for card content
class CardContent {
  final String text;
  final CardDisplayType type;

  CardContent({
    required this.text,
    required this.type,
  });
}

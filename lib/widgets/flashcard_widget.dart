import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_constants.dart';

/// Flashcard widget for displaying individual flashcards
class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final bool showAnswer;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.showAnswer,
    required this.isCompleted,
    required this.onTap,
    this.onEdit,
    this.onToggleFavorite,
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
      behavior: HitTestBehavior.deferToChild,
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
          minHeight: MediaQuery.of(context).size.height * 0.3,
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        decoration: BoxDecoration(
          color: appTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: appTheme.shadowColor,
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
                        color: Colors.amber,
                      ),
                      SizedBox(height: AppConstants.cardCompletionSpacing),
                      Text(
                        'Deck Completed!',
                        style: TextStyle(
                          fontSize: AppConstants.cardCompletionTitleSize,
                          color: appTheme.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppConstants.cardCompletionSpacing),
                      Text(
                        'Great job! You\'ve finished all the cards.',
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
                      // Main card content
                      _buildCardContent(theme, appTheme),
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
                      color: appTheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: appTheme.primaryIcon.withValues(alpha: 0.8),
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
                      color: appTheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.note,
                      color: appTheme.primaryIcon.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
              ),
            
            // Star icon (favorites) - only show when card is flipped (back side)
            if (widget.showAnswer && widget.onToggleFavorite != null)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.onToggleFavorite?.call();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appTheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        widget.flashcard.isFavorite ? Icons.star : Icons.star_border,
                        color: widget.flashcard.isFavorite 
                            ? Colors.amber 
                            : appTheme.primaryIcon.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build the main card content
  Widget _buildCardContent(ThemeData theme, AppThemeExtension appTheme) {
    if (widget.showAnswer) {
      return _buildBackContent(theme, appTheme);
    } else {
      return _buildFrontContent(theme, appTheme);
    }
  }

  /// Build front card content
  Widget _buildFrontContent(ThemeData theme, AppThemeExtension appTheme) {
    return _buildResponsiveText(
      text: widget.flashcard.kana,
      baseFontSize: 28.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build back card content
  Widget _buildBackContent(ThemeData theme, AppThemeExtension appTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // English translation
        _buildResponsiveText(
          text: widget.flashcard.english,
          baseFontSize: 24.0,
          color: appTheme.primaryText,
          fontWeight: FontWeight.w500,
        ),
        
        // Hiragana if available
        if (widget.flashcard.hiragana != null && widget.flashcard.hiragana!.isNotEmpty) ...[
          SizedBox(height: 8),
          _buildResponsiveText(
            text: widget.flashcard.hiragana!,
            baseFontSize: 18.0,
            color: appTheme.secondaryText,
            fontWeight: FontWeight.w400,
          ),
        ],
        
        // Romaji if available
        if (widget.flashcard.romaji != null && widget.flashcard.romaji!.isNotEmpty) ...[
          SizedBox(height: 4),
          _buildResponsiveText(
            text: widget.flashcard.romaji!,
            baseFontSize: 16.0,
            color: appTheme.secondaryText,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
          ),
        ],
      ],
    );
  }

  /// Build notes content display
  Widget _buildNotesContent(ThemeData theme, AppThemeExtension appTheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.cardPadding),
        child: _buildResponsiveText(
          text: widget.flashcard.notes!,
          baseFontSize: 20.0,
          color: appTheme.primaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build responsive text that automatically adjusts size based on content length
  Widget _buildResponsiveText({
    required String text,
    required double baseFontSize,
    required Color color,
    required FontWeight fontWeight,
    FontStyle? fontStyle,
  }) {
    // Calculate available width (card width minus padding)
    // final screenWidth = MediaQuery.of(context).size.width;
    // final cardPadding = AppConstants.cardPadding * 2; // Left and right padding
    // final availableWidth = screenWidth - cardPadding - 32; // Extra margin for safety
    
    // Estimate text length and adjust font size accordingly
    double fontSize = baseFontSize;
    
    // If text is very long, start with smaller font size
    if (text.length > 50) {
      fontSize = baseFontSize * 0.8;
    } else if (text.length > 30) {
      fontSize = baseFontSize * 0.9;
    }
    
    // If text is very short, make it larger
    if (text.length < 10) {
      fontSize = baseFontSize * 1.2;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight * 0.8, // Leave some space for other elements
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3, // Allow up to 3 lines
              overflow: TextOverflow.ellipsis, // Show ellipsis if still too long
              softWrap: true, // Enable word wrapping
            ),
          ),
        );
      },
    );
  }
}
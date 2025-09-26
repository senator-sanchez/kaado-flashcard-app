import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard.dart';
import '../models/card_display_settings.dart';
import '../models/language_agnostic_display_settings.dart' as lang_agnostic;
import '../models/language_field_option.dart';
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_constants.dart';

/// Flashcard widget for displaying individual flashcards
class FlashcardWidget extends ConsumerStatefulWidget {
  final Flashcard flashcard;
  final bool showAnswer;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;
  final CardDisplaySettings? displaySettings;
  final lang_agnostic.LanguageAgnosticDisplaySettings? languageAgnosticSettings;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.showAnswer,
    required this.isCompleted,
    required this.onTap,
    this.onEdit,
    this.onToggleFavorite,
    this.displaySettings,
    this.languageAgnosticSettings,
  });

  @override
  ConsumerState<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends ConsumerState<FlashcardWidget> {
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    
    return RepaintBoundary(
      key: ValueKey('flashcard_${widget.flashcard.id}'),
      child: GestureDetector(
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
      ),
    );
  }

  /// Build the main card content
  Widget _buildCardContent(ThemeData theme, AppThemeExtension appTheme) {
    // Use language-agnostic settings if available, otherwise fall back to legacy settings
    if (widget.languageAgnosticSettings != null) {
      return _buildLanguageAgnosticContent(theme, appTheme);
    } else {
      return _buildLegacyContent(theme, appTheme);
    }
  }

  /// Build content using language-agnostic settings
  Widget _buildLanguageAgnosticContent(ThemeData theme, AppThemeExtension appTheme) {
    final settings = widget.languageAgnosticSettings!;
    
    if (settings.displayMode == CardDisplayMode.mixed) {
      // In mixed mode, determine front/back based on card ID for consistency
      final isTranslationFront = _isTranslationFrontForMixedMode(settings);
      if (widget.showAnswer) {
        return isTranslationFront ? _buildTargetLanguageBackContent(theme, appTheme, settings) : _buildTranslationBackContent(theme, appTheme, settings);
      } else {
        return isTranslationFront ? _buildTranslationFrontContent(theme, appTheme, settings) : _buildTargetLanguageFrontContent(theme, appTheme, settings);
      }
    } else {
      // Normal mode - use display settings
      if (widget.showAnswer) {
        return _buildLanguageAgnosticBackContent(theme, appTheme, settings);
      } else {
        return _buildLanguageAgnosticFrontContent(theme, appTheme, settings);
      }
    }
  }

  /// Build content using legacy settings (backward compatibility)
  Widget _buildLegacyContent(ThemeData theme, AppThemeExtension appTheme) {
    final settings = widget.displaySettings ?? CardDisplaySettings.defaultSettings;
    
    if (settings.displayMode == CardDisplayMode.mixed) {
      // In mixed mode, determine front/back based on card ID for consistency
      final isEnglishFront = _isEnglishFrontForMixedMode();
      if (widget.showAnswer) {
        return isEnglishFront ? _buildJapaneseBackContent(theme, appTheme) : _buildEnglishBackContent(theme, appTheme);
      } else {
        return isEnglishFront ? _buildEnglishFrontContent(theme, appTheme) : _buildJapaneseFrontContent(theme, appTheme);
      }
    } else {
      // Normal mode - use display settings
      if (widget.showAnswer) {
        return _buildBackContent(theme, appTheme);
      } else {
        return _buildFrontContent(theme, appTheme);
      }
    }
  }

  /// Build front card content
  Widget _buildFrontContent(ThemeData theme, AppThemeExtension appTheme) {
    final settings = widget.displaySettings ?? CardDisplaySettings.defaultSettings;
    final frontText = _getFieldText(settings.frontCardOption);
    
    return _buildResponsiveText(
      text: frontText,
      baseFontSize: 28.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build back card content
  Widget _buildBackContent(ThemeData theme, AppThemeExtension appTheme) {
    final settings = widget.displaySettings ?? CardDisplaySettings.defaultSettings;
    final backOptions = settings.backCardOptions;
    
    if (backOptions.isEmpty) {
      return _buildResponsiveText(
        text: 'No back content configured',
        baseFontSize: 18.0,
        color: appTheme.secondaryText,
        fontWeight: FontWeight.w400,
      );
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: backOptions.map((option) {
        final text = _getFieldText(option);
        if (text.isEmpty) return SizedBox.shrink();
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: _buildResponsiveText(
            text: text,
            baseFontSize: _getFontSizeForOption(option),
            color: _getColorForOption(option, appTheme),
            fontWeight: _getFontWeightForOption(option),
            fontStyle: _getFontStyleForOption(option),
          ),
        );
      }).toList(),
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

  /// Determine if English should be on front for mixed mode (based on card ID for consistency)
  bool _isEnglishFrontForMixedMode() {
    // Use card ID to determine direction for consistency
    return widget.flashcard.id % 2 == 0;
  }

  /// Determine if translation should be on front for mixed mode (language-agnostic)
  bool _isTranslationFrontForMixedMode(lang_agnostic.LanguageAgnosticDisplaySettings settings) {
    // Use card ID to determine direction for consistency
    return widget.flashcard.id % 2 == 0;
  }

  /// Build language-agnostic front content
  Widget _buildLanguageAgnosticFrontContent(ThemeData theme, AppThemeExtension appTheme, lang_agnostic.LanguageAgnosticDisplaySettings settings) {
    final frontText = _getLanguageAgnosticFieldText(settings.frontField);
    
    return _buildResponsiveText(
      text: frontText,
      baseFontSize: 28.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build language-agnostic back content
  Widget _buildLanguageAgnosticBackContent(ThemeData theme, AppThemeExtension appTheme, lang_agnostic.LanguageAgnosticDisplaySettings settings) {
    final backFields = settings.backFields;
    
    if (backFields.isEmpty) {
      return _buildResponsiveText(
        text: 'No back content configured',
        baseFontSize: 18.0,
        color: appTheme.secondaryText,
        fontWeight: FontWeight.w400,
      );
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: backFields.map((field) {
        final text = _getLanguageAgnosticFieldText(field);
        if (text.isEmpty) return SizedBox.shrink();
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: _buildResponsiveText(
            text: text,
            baseFontSize: _getFontSizeForLanguageField(field),
            color: _getColorForLanguageField(field, appTheme),
            fontWeight: _getFontWeightForLanguageField(field),
            fontStyle: _getFontStyleForLanguageField(field),
          ),
        );
      }).toList(),
    );
  }

  /// Build target language front content for mixed mode
  Widget _buildTargetLanguageFrontContent(ThemeData theme, AppThemeExtension appTheme, lang_agnostic.LanguageAgnosticDisplaySettings settings) {
    final frontText = _getLanguageAgnosticFieldText(settings.frontField);
    
    return _buildResponsiveText(
      text: frontText,
      baseFontSize: 28.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build translation front content for mixed mode
  Widget _buildTranslationFrontContent(ThemeData theme, AppThemeExtension appTheme, lang_agnostic.LanguageAgnosticDisplaySettings settings) {
    // Find the translation field (usually English)
    final translationField = settings.backFields.firstWhere(
      (field) => field.isTranslation,
      orElse: () => LanguageFieldOptions.english,
    );
    final frontText = _getLanguageAgnosticFieldText(translationField);
    
    return _buildResponsiveText(
      text: frontText,
      baseFontSize: 28.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build target language back content for mixed mode
  Widget _buildTargetLanguageBackContent(ThemeData theme, AppThemeExtension appTheme, lang_agnostic.LanguageAgnosticDisplaySettings settings) {
    final backFields = settings.backFields.where((field) => !field.isTranslation).toList();
    
    if (backFields.isEmpty) {
      return _buildResponsiveText(
        text: 'No back content configured',
        baseFontSize: 18.0,
        color: appTheme.secondaryText,
        fontWeight: FontWeight.w400,
      );
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: backFields.map((field) {
        final text = _getLanguageAgnosticFieldText(field);
        if (text.isEmpty) return SizedBox.shrink();
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: _buildResponsiveText(
            text: text,
            baseFontSize: _getFontSizeForLanguageField(field),
            color: _getColorForLanguageField(field, appTheme),
            fontWeight: _getFontWeightForLanguageField(field),
            fontStyle: _getFontStyleForLanguageField(field),
          ),
        );
      }).toList(),
    );
  }

  /// Build translation back content for mixed mode
  Widget _buildTranslationBackContent(ThemeData theme, AppThemeExtension appTheme, lang_agnostic.LanguageAgnosticDisplaySettings settings) {
    // Find the translation field (usually English)
    final translationField = settings.backFields.firstWhere(
      (field) => field.isTranslation,
      orElse: () => LanguageFieldOptions.english,
    );
    final backText = _getLanguageAgnosticFieldText(translationField);
    
    return _buildResponsiveText(
      text: backText,
      baseFontSize: 24.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build English front content for mixed mode
  Widget _buildEnglishFrontContent(ThemeData theme, AppThemeExtension appTheme) {
    return _buildResponsiveText(
      text: widget.flashcard.english,
      baseFontSize: 28.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build Japanese front content for mixed mode
  Widget _buildJapaneseFrontContent(ThemeData theme, AppThemeExtension appTheme) {
    final settings = widget.displaySettings ?? CardDisplaySettings.defaultSettings;
    final frontText = _getFieldText(settings.frontCardOption);
    
    return _buildResponsiveText(
      text: frontText,
      baseFontSize: 28.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build English back content for mixed mode (when Japanese was on front)
  Widget _buildEnglishBackContent(ThemeData theme, AppThemeExtension appTheme) {
    return _buildResponsiveText(
      text: widget.flashcard.english,
      baseFontSize: 24.0,
      color: appTheme.primaryText,
      fontWeight: FontWeight.w500,
    );
  }

  /// Build Japanese back content for mixed mode (when English was on front)
  Widget _buildJapaneseBackContent(ThemeData theme, AppThemeExtension appTheme) {
    final settings = widget.displaySettings ?? CardDisplaySettings.defaultSettings;
    final backOptions = settings.backCardOptions;
    
    if (backOptions.isEmpty) {
      return _buildResponsiveText(
        text: 'No back content configured',
        baseFontSize: 18.0,
        color: appTheme.secondaryText,
        fontWeight: FontWeight.w400,
      );
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: backOptions.map((option) {
        final text = _getFieldText(option);
        if (text.isEmpty) return SizedBox.shrink();
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: _buildResponsiveText(
            text: text,
            baseFontSize: _getFontSizeForOption(option),
            color: _getColorForOption(option, appTheme),
            fontWeight: _getFontWeightForOption(option),
            fontStyle: _getFontStyleForOption(option),
          ),
        );
      }).toList(),
    );
  }

  /// Get field text for language-agnostic field
  String _getLanguageAgnosticFieldText(LanguageFieldOption field) {
    switch (field.fieldType) {
      case 'kana':
        return widget.flashcard.kana;
      case 'hiragana':
        return widget.flashcard.hiragana ?? '';
      case 'kanji':
        return widget.flashcard.kana; // Use kana field as kanji equivalent
      case 'romaji':
        return widget.flashcard.romaji ?? '';
      case 'english':
        return widget.flashcard.english;
      case 'spanish':
        return widget.flashcard.english; // For now, use English as placeholder
      case 'french':
        return widget.flashcard.english; // For now, use English as placeholder
      case 'german':
        return widget.flashcard.english; // For now, use English as placeholder
      default:
        return widget.flashcard.english; // Fallback to English
    }
  }

  /// Get font size for language field
  double _getFontSizeForLanguageField(LanguageFieldOption field) {
    if (field.isTranslation) {
      return 24.0;
    } else if (field.fieldType == 'romaji') {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// Get color for language field
  Color _getColorForLanguageField(LanguageFieldOption field, AppThemeExtension appTheme) {
    if (field.fieldType == 'romaji') {
      return appTheme.secondaryText;
    } else {
      return appTheme.primaryText;
    }
  }

  /// Get font weight for language field
  FontWeight _getFontWeightForLanguageField(LanguageFieldOption field) {
    if (field.isTranslation) {
      return FontWeight.w500;
    } else {
      return FontWeight.w400;
    }
  }

  /// Get font style for language field
  FontStyle _getFontStyleForLanguageField(LanguageFieldOption field) {
    if (field.fieldType == 'romaji') {
      return FontStyle.italic;
    } else {
      return FontStyle.normal;
    }
  }

  /// Get field text based on option
  String _getFieldText(dynamic option) {
    if (option is FrontCardOption) {
      switch (option) {
        case FrontCardOption.kana:
          return widget.flashcard.kana;
        case FrontCardOption.hiragana:
          return widget.flashcard.hiragana ?? '';
        case FrontCardOption.kanji:
          return widget.flashcard.kana; // Use kana field as kanji equivalent
        case FrontCardOption.romaji:
          return widget.flashcard.romaji ?? '';
        case FrontCardOption.english:
          return widget.flashcard.english;
      }
    } else if (option is BackCardOption) {
      switch (option) {
        case BackCardOption.kana:
          return widget.flashcard.kana;
        case BackCardOption.hiragana:
          return widget.flashcard.hiragana ?? '';
        case BackCardOption.kanji:
          return widget.flashcard.kana; // Use kana field as kanji equivalent
        case BackCardOption.romaji:
          return widget.flashcard.romaji ?? '';
        case BackCardOption.english:
          return widget.flashcard.english;
      }
    }
    return '';
  }

  /// Get font size for option
  double _getFontSizeForOption(dynamic option) {
    if (option is BackCardOption) {
      switch (option) {
        case BackCardOption.english:
          return 24.0;
        case BackCardOption.kana:
        case BackCardOption.hiragana:
        case BackCardOption.kanji:
          return 20.0;
        case BackCardOption.romaji:
          return 16.0;
      }
    }
    return 18.0;
  }

  /// Get color for option
  Color _getColorForOption(dynamic option, AppThemeExtension appTheme) {
    if (option is BackCardOption) {
      switch (option) {
        case BackCardOption.english:
          return appTheme.primaryText;
        case BackCardOption.kana:
        case BackCardOption.hiragana:
        case BackCardOption.kanji:
          return appTheme.primaryText;
        case BackCardOption.romaji:
          return appTheme.secondaryText;
      }
    }
    return appTheme.primaryText;
  }

  /// Get font weight for option
  FontWeight _getFontWeightForOption(dynamic option) {
    if (option is BackCardOption) {
      switch (option) {
        case BackCardOption.english:
          return FontWeight.w500;
        case BackCardOption.kana:
        case BackCardOption.hiragana:
        case BackCardOption.kanji:
          return FontWeight.w400;
        case BackCardOption.romaji:
          return FontWeight.w400;
      }
    }
    return FontWeight.w400;
  }

  /// Get font style for option
  FontStyle _getFontStyleForOption(dynamic option) {
    if (option is BackCardOption) {
      switch (option) {
        case BackCardOption.romaji:
          return FontStyle.italic;
        default:
          return FontStyle.normal;
      }
    }
    return FontStyle.normal;
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

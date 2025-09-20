import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_colors.dart';

/// Quick edit dialog for editing cards directly from the home screen
class QuickEditCardDialog extends StatefulWidget {
  final Flashcard card;
  final VoidCallback onCardUpdated;

  const QuickEditCardDialog({
    super.key,
    required this.card,
    required this.onCardUpdated,
  });

  @override
  State<QuickEditCardDialog> createState() => _QuickEditCardDialogState();
}

class _QuickEditCardDialogState extends State<QuickEditCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kanaController = TextEditingController();
  final _hiraganaController = TextEditingController();
  final _englishController = TextEditingController();
  final _romajiController = TextEditingController();
  final _notesController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _kanaController.text = widget.card.kana;
    _hiraganaController.text = widget.card.hiragana ?? '';
    _englishController.text = widget.card.english;
    _romajiController.text = widget.card.romaji ?? '';
    _notesController.text = widget.card.notes ?? '';
  }

  @override
  void dispose() {
    _kanaController.dispose();
    _hiraganaController.dispose();
    _englishController.dispose();
    _romajiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Save the card
  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedCard = Flashcard(
        id: widget.card.id,
        kana: _kanaController.text.trim(),
        hiragana: _hiraganaController.text.trim().isEmpty ? null : _hiraganaController.text.trim(),
        english: _englishController.text.trim(),
        romaji: _romajiController.text.trim().isEmpty ? null : _romajiController.text.trim(),
        scriptType: widget.card.scriptType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        categoryId: widget.card.categoryId,
        categoryName: widget.card.categoryName,
      );

      await _databaseService.updateCard(updatedCard);
      widget.onCardUpdated();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating card: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.instance;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      elevation: AppSizes.shadowBlurLarge,
      title: Text(
        'Edit Card',
        style: TextStyle(
          color: colors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: AppSizes.spacingLarge,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kana field (required)
              TextFormField(
                controller: _kanaController,
                decoration: InputDecoration(
                  labelText: 'Kana *',
                  hintText: 'Japanese text (kanji, hiragana, katakana)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: BorderSide(
                      color: colors.divider,
                      width: AppSizes.borderWidthThin,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: BorderSide(
                      color: colors.divider,
                      width: AppSizes.borderWidthThin,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: BorderSide(
                      color: colors.primaryBlue,
                      width: AppSizes.borderWidthMedium,
                    ),
                  ),
                  filled: true,
                  fillColor: colors.backgroundColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                    vertical: AppSizes.paddingSmall,
                  ),
                ),
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kana is required';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // Hiragana field (optional)
              TextFormField(
                controller: _hiraganaController,
                decoration: InputDecoration(
                  labelText: 'Hiragana',
                  hintText: 'Hiragana reading (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  filled: true,
                  fillColor: colors.backgroundColor,
                ),
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // English field (required)
              TextFormField(
                controller: _englishController,
                decoration: InputDecoration(
                  labelText: 'English *',
                  hintText: 'English translation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  filled: true,
                  fillColor: colors.backgroundColor,
                ),
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'English translation is required';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // Romaji field (optional)
              TextFormField(
                controller: _romajiController,
                decoration: InputDecoration(
                  labelText: 'Romaji',
                  hintText: 'Romaji reading (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  filled: true,
                  fillColor: colors.backgroundColor,
                ),
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // Notes field (optional)
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional notes (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  filled: true,
                  fillColor: colors.backgroundColor,
                ),
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCard,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryBlue,
            foregroundColor: colors.buttonTextOnColored,
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            elevation: AppSizes.shadowBlurSmall,
          ),
          child: _isLoading
              ? SizedBox(
                  width: AppSizes.iconSmall,
                  height: AppSizes.iconSmall,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.borderWidthThin,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.buttonTextOnColored),
                  ),
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

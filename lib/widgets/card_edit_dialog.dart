// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports - Models
import '../models/flashcard.dart';

// Project imports - Services
import '../services/database_service.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';

// Project imports - Constants

/// Dialog for adding and editing flashcards
/// 
/// This dialog provides:
/// - Form fields for all card properties (Kana, Hiragana, English, Romaji)
/// - Validation and error handling
/// - Save and cancel actions
/// - Clean, user-friendly interface
class CardEditDialog extends ConsumerStatefulWidget {
  final int categoryId;
  final Flashcard? card;

  final VoidCallback onCardSaved;

  const CardEditDialog({
    super.key,
    required this.categoryId,
    this.card,
    required this.onCardSaved,
  });

  @override
  ConsumerState<CardEditDialog> createState() => _CardEditDialogState();
}

class _CardEditDialogState extends ConsumerState<CardEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kanaController = TextEditingController();
  final _hiraganaController = TextEditingController();
  final _englishController = TextEditingController();
  final _romajiController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _kanaController.text = widget.card!.kana;
      _hiraganaController.text = widget.card!.hiragana ?? '';
      _englishController.text = widget.card!.english;
      _romajiController.text = widget.card!.romaji ?? '';
      _notesController.text = widget.card!.notes ?? '';
    }
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
      final databaseService = DatabaseService();
      
      if (widget.card != null) {
        // Update existing card
        final updatedCard = Flashcard(
          id: widget.card!.id,
          kana: _kanaController.text.trim(),
          hiragana: _hiraganaController.text.trim().isEmpty ? null : _hiraganaController.text.trim(),
          english: _englishController.text.trim(),
          romaji: _romajiController.text.trim().isEmpty ? null : _romajiController.text.trim(),
          scriptType: widget.card!.scriptType,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          categoryId: widget.card!.categoryId,
          categoryName: widget.card!.categoryName,
        );
        
        await databaseService.updateCard(updatedCard);
      } else {
        // Create new card
        await databaseService.addCard(
          widget.categoryId,
          _kanaController.text.trim(),
          _englishController.text.trim(),
          hiragana: _hiraganaController.text.trim().isEmpty ? null : _hiraganaController.text.trim(),
          romaji: _romajiController.text.trim().isEmpty ? null : _romajiController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
        final theme = Theme.of(context);
        Navigator.of(context).pop();
        widget.onCardSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.card != null ? 'Card updated successfully' : 'Card added successfully'),
            backgroundColor: theme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving card: $e'),
            backgroundColor: theme.colorScheme.error,
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
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final isEditing = widget.card != null;

    return AlertDialog(
      backgroundColor: appTheme.surface,
      title: Text(
        isEditing ? 'Edit Card' : 'Add Card',
        style: TextStyle(
          color: appTheme.primaryText,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kana field (required)
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF000000), // Pure black for maximum contrast
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: appTheme.divider),
                ),
                child: TextFormField(
                  controller: _kanaController,
                  decoration: InputDecoration(
                    labelText: 'Kana *',
                    hintText: 'Japanese text (kanji, hiragana, katakana)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: appTheme.primaryText),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kana is required';
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // Hiragana field (optional)
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF000000), // Pure black for maximum contrast
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: appTheme.divider),
                ),
                child: TextFormField(
                  controller: _hiraganaController,
                  decoration: InputDecoration(
                    labelText: 'Hiragana',
                    hintText: 'Hiragana reading (optional)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: appTheme.primaryText),
                ),
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // English field (required)
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF000000), // Pure black for maximum contrast
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: appTheme.divider),
                ),
                child: TextFormField(
                  controller: _englishController,
                  decoration: InputDecoration(
                    labelText: 'English *',
                    hintText: 'English translation',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: appTheme.primaryText),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'English translation is required';
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // Romaji field (optional)
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF000000), // Pure black for maximum contrast
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: appTheme.divider),
                ),
                child: TextFormField(
                  controller: _romajiController,
                  decoration: InputDecoration(
                    labelText: 'Romaji',
                    hintText: 'Romaji reading (optional)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: appTheme.primaryText),
                ),
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // Notes field (optional)
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF000000), // Pure black for maximum contrast
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: appTheme.divider),
                ),
                child: TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional notes (optional)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: appTheme.primaryText),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: appTheme.secondaryText),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCard,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: appTheme.buttonTextOnColored,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(appTheme.buttonTextOnColored),
                  ),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

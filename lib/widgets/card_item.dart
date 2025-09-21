// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/flashcard.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';

// Project imports - Constants

/// A card item widget for displaying flashcard information
/// 
/// This widget provides:
/// - All card fields (Kana, Hiragana, English, Romaji)
/// - Edit and delete actions
/// - Clean, organized display
class CardItem extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CardItem({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.spacingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Card #${card.id}',
                      style: TextStyle(
                        color: appTheme.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onTap();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: appTheme.primaryIcon),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: appTheme.primaryIcon,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSizes.spacingMedium),

              // Card content
              _buildFieldRow('Kana', card.kana, appTheme.primaryText, appTheme.secondaryText),
              if (card.hiragana?.isNotEmpty == true)
                _buildFieldRow('Hiragana', card.hiragana!, appTheme.secondaryText, appTheme.secondaryText),
              _buildFieldRow('English', card.english, appTheme.primaryText, appTheme.secondaryText),
              if (card.romaji?.isNotEmpty == true)
                _buildFieldRow('Romaji', card.romaji!, appTheme.secondaryText, appTheme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a field row with label and value
  Widget _buildFieldRow(String label, String value, Color textColor, Color labelColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

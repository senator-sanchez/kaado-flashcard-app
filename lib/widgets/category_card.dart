// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/category.dart';

// Project imports - Utils
import '../utils/app_theme.dart';

// Project imports - Constants
import '../constants/app_sizes.dart';

// Project imports - Constants

/// A card widget for displaying category information
/// 
/// This widget provides:
/// - Category name and description
/// - Card count display
/// - Edit and delete actions
/// - Clean, modern design
class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.onEdit,
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
              // Header row with name and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            color: appTheme.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (category.description?.isNotEmpty == true) ...[
                          SizedBox(height: 4),
                          Text(
                            category.description!,
                            style: TextStyle(
                              color: appTheme.secondaryText,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
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

              // Footer with card count and arrow
              Row(
                children: [
                  Icon(
                    Icons.style,
                    size: 16,
                    color: appTheme.primaryIcon,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${category.cardCount} cards',
                    style: TextStyle(
                      color: appTheme.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: appTheme.primaryIcon,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

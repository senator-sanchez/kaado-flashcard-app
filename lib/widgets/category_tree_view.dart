import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/theme_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_colors.dart';

/// A hierarchical tree view widget for displaying categories
/// 
/// This widget displays categories in a tree structure with:
/// - Expand/collapse functionality for parent categories
/// - Visual hierarchy indicators (icons, indentation)
/// - Different styling for parent vs leaf categories
class CategoryTreeView extends StatefulWidget {
  final List<Category> categories;
  final Function(Category) onCategoryTap;
  final Function(Category) onCategoryEdit;
  final Function(Category) onCategoryDelete;

  const CategoryTreeView({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    required this.onCategoryEdit,
    required this.onCategoryDelete,
  });

  @override
  State<CategoryTreeView> createState() => _CategoryTreeViewState();
}

class _CategoryTreeViewState extends State<CategoryTreeView> {
  final Set<int> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingMedium),
      itemCount: widget.categories.length,
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        return _buildCategoryNode(category, 0);
      },
    );
  }

  /// Build a category node with proper indentation and hierarchy
  Widget _buildCategoryNode(Category category, int depth) {
    final colors = ThemeColors.instance;
    final isExpanded = _expandedCategories.contains(category.id);
    final hasChildren = category.children != null && category.children!.isNotEmpty;
    final isLeafCategory = category.isCardCategory && category.cardCount > 0;

    return Column(
      children: [
        // Category card with indentation
        Padding(
          padding: EdgeInsets.only(
            left: depth * AppSizes.spacingLarge,
            bottom: AppSizes.spacingSmall,
          ),
          child: Card(
            color: colors.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            ),
            child: InkWell(
              onTap: () {
                if (hasChildren) {
                  _toggleExpansion(category.id);
                } else if (isLeafCategory) {
                  widget.onCategoryTap(category);
                }
              },
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              child: Padding(
                padding: EdgeInsets.all(AppSizes.spacingMedium),
                child: Row(
                  children: [
                    // Hierarchy icon
                    Icon(
                      hasChildren 
                        ? (isExpanded ? Icons.folder_open : Icons.folder)
                        : (isLeafCategory ? Icons.description : Icons.folder_outlined),
                      color: hasChildren 
                        ? colors.primaryBlue
                        : (isLeafCategory ? colors.primaryText : colors.secondaryText),
                      size: 20,
                    ),
                    SizedBox(width: AppSizes.spacingSmall),
                    
                    // Category name and info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 16,
                              fontWeight: hasChildren ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (category.description != null && category.description!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: AppSizes.spacingXSmall),
                              child: Text(
                                category.description!,
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Card count or expand icon
                    if (isLeafCategory)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingSmall,
                          vertical: AppSizes.spacingXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                        ),
                        child: Text(
                          '${category.cardCount}',
                          style: TextStyle(
                            color: colors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (hasChildren)
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: colors.secondaryText,
                        size: 20,
                      ),
                    
                    // Menu button for actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: colors.secondaryIcon, size: 16),
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onCategoryEdit(category);
                        } else if (value == 'delete') {
                          widget.onCategoryDelete(category);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit', style: TextStyle(color: colors.primaryText)),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Children (if expanded)
        if (hasChildren && isExpanded)
          ...category.children!.map((child) => _buildCategoryNode(child, depth + 1)),
      ],
    );
  }

  /// Toggle expansion state of a category
  void _toggleExpansion(int categoryId) {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
  }
}

// Flutter imports
import 'package:flutter/material.dart';

// Project imports - Models
import '../models/category.dart';

// Project imports - Services
import '../services/database_service.dart';

// Project imports - Utils
import '../utils/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

// Project imports - Constants

/// Dialog for adding a new category
class AddCategoryDialog extends StatefulWidget {
  final VoidCallback onCategoryAdded;

  const AddCategoryDialog({
    super.key,
    required this.onCategoryAdded,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Add the category
  Future<void> _addCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final databaseService = DatabaseService();
      await databaseService.addCategory(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      if (mounted) {
        final theme = Theme.of(context);
        Navigator.of(context).pop();
        widget.onCategoryAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category added successfully'),
            backgroundColor: theme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding category: $e'),
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

    return AlertDialog(
      backgroundColor: appTheme.surface,
      title: Text(
        'Add Category',
        style: TextStyle(
          color: appTheme.primaryText,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name field (required)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name *',
                hintText: 'Enter category name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                filled: true,
                fillColor: appTheme.backgroundColor,
              ),
              style: TextStyle(color: appTheme.primaryText),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category name is required';
                }
                return null;
              },
            ),

            SizedBox(height: AppSizes.spacingMedium),

            // Description field (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter category description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                filled: true,
                fillColor: appTheme.backgroundColor,
              ),
              style: TextStyle(color: appTheme.primaryText),
              maxLines: 3,
            ),
          ],
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
          onPressed: _isLoading ? null : _addCategory,
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
              : Text('Add'),
        ),
      ],
    );
  }
}

/// Dialog for editing an existing category
class EditCategoryDialog extends StatefulWidget {
  final Category category;
  final VoidCallback onCategoryUpdated;

  const EditCategoryDialog({
    super.key,
    required this.category,
    required this.onCategoryUpdated,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category.name;
    _descriptionController.text = widget.category.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Update the category
  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final databaseService = DatabaseService();
      final updatedCategory = Category(
        id: widget.category.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        cardCount: widget.category.cardCount,
      );
      
      await databaseService.updateCategory(updatedCategory);

      if (mounted) {
        final theme = Theme.of(context);
        Navigator.of(context).pop();
        widget.onCategoryUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category updated successfully'),
            backgroundColor: theme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating category: $e'),
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

    return AlertDialog(
      backgroundColor: appTheme.surface,
      title: Text(
        'Edit Category',
        style: TextStyle(
          color: appTheme.primaryText,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name field (required)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name *',
                hintText: 'Enter category name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                filled: true,
                fillColor: appTheme.backgroundColor,
              ),
              style: TextStyle(color: appTheme.primaryText),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Category name is required';
                }
                return null;
              },
            ),

            SizedBox(height: AppSizes.spacingMedium),

            // Description field (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter category description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                filled: true,
                fillColor: appTheme.backgroundColor,
              ),
              style: TextStyle(color: appTheme.primaryText),
              maxLines: 3,
            ),
          ],
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
          onPressed: _isLoading ? null : _updateCategory,
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
              : Text('Update'),
        ),
      ],
    );
  }
}

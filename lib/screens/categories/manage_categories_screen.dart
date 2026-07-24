import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/category_icon_mapper.dart';
import '../../models/food_category.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'category_form_dialog.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _showCategoryForm(
    BuildContext context, {
    FoodCategory? category,
  }) async {
    final wasSaved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return CategoryFormDialog(category: category);
      },
    );

    if (!context.mounted || wasSaved != true) {
      return;
    }

    final message = category == null
        ? 'Category added successfully.'
        : 'Category updated successfully.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteCategory(
    BuildContext context,
    FoodCategory category,
  ) async {
    final foodItemProvider = context.read<FoodItemProvider?>();

    if (foodItemProvider == null) {
      _showMessage(
        context,
        'Unable to verify whether this category is currently in use.',
      );
      return;
    }

    final linkedItems = foodItemProvider.getItemsByCategory(category.id);

    if (linkedItems.isNotEmpty) {
      final itemCount = linkedItems.length;

      final itemText = itemCount == 1
          ? '1 food item uses'
          : '$itemCount food items use';

      _showMessage(
        context,
        '$itemText "${category.name}". '
        'Move or delete the food '
        '${itemCount == 1 ? 'item' : 'items'} '
        'before deleting this category.',
      );

      return;
    }

    final shouldDelete = await showConfirmationDialog(
      context: context,
      title: 'Delete category?',
      message:
          'The category "${category.name}" '
          'will be permanently removed.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!context.mounted || !shouldDelete) {
      return;
    }

    final provider = context.read<CategoryProvider>();

    final success = await provider.deleteCategory(category.id);

    if (!context.mounted) {
      return;
    }

    final message = success
        ? 'Category deleted successfully.'
        : provider.errorMessage ?? 'Unable to delete the category.';

    _showMessage(context, message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCategoryForm(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingView(message: 'Loading categories...');
          }

          if (provider.errorMessage != null && provider.categories.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.initialize,
            );
          }

          if (provider.categories.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message: 'Add a category to organize the food in your pantry.',
              buttonText: 'Add Category',
              onButtonPressed: () {
                _showCategoryForm(context);
              },
            );
          }

          return Column(
            children: [
              _CategorySummaryHeader(categoryCount: provider.categoryCount),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: provider.categories.length,
                  separatorBuilder: (_, _) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];

                    return _CategoryListTile(
                      category: category,
                      onEdit: () {
                        _showCategoryForm(context, category: category);
                      },
                      onDelete: () {
                        _deleteCategory(context, category);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySummaryHeader extends StatelessWidget {
  const _CategorySummaryHeader({required this.categoryCount});

  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$categoryCount categories available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            CategoryIconMapper.fromKey(category.iconKey),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          category.isDefault ? 'Default category' : 'Custom category',
        ),
        trailing: category.isDefault
            ? Tooltip(
                message: 'Default categories cannot be changed',
                child: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : PopupMenuButton<_CategoryAction>(
                tooltip: 'Category actions',
                onSelected: (action) {
                  switch (action) {
                    case _CategoryAction.edit:
                      onEdit();

                    case _CategoryAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: _CategoryAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _CategoryAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ];
                },
              ),
      ),
    );
  }
}

enum _CategoryAction { edit, delete }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shopping_item.dart';
import '../../providers/shopping_item_provider.dart';
import 'shopping_item_form_dialog.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingItemProvider?>();

    if (provider == null) {
      return const Scaffold(
        body: Center(
          child: Text('The shopping list is currently unavailable.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (provider.completedCount > 0)
            IconButton(
              tooltip: 'Clear completed items',
              onPressed: provider.isSubmitting
                  ? null
                  : () {
                      _clearCompletedItems(context, provider);
                    },
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
          IconButton(
            tooltip: 'Refresh shopping list',
            onPressed: provider.reloadItems,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isSubmitting
            ? null
            : () {
                _openItemDialog(context);
              },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, ShoppingItemProvider provider) {
    if (provider.isLoading && !provider.hasItems) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && !provider.hasItems) {
      return _ShoppingErrorState(
        message: provider.errorMessage!,
        onRetry: provider.reloadItems,
      );
    }

    if (!provider.hasItems) {
      return _EmptyShoppingState(
        onAddItem: () {
          _openItemDialog(context);
        },
        onRefresh: provider.reloadItems,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _ShoppingSummary(
            pendingCount: provider.pendingCount,
            completedCount: provider.completedCount,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Your Shopping Items',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              provider.reloadItems();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: provider.items.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 8);
              },
              itemBuilder: (context, index) {
                final item = provider.items[index];

                return _ShoppingItemCard(
                  item: item,
                  isDisabled: provider.isSubmitting,
                  onToggle: () {
                    _toggleCompleted(context, provider, item);
                  },
                  onEdit: () {
                    _openItemDialog(context, item: item);
                  },
                  onDelete: () {
                    _deleteItem(context, provider, item);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openItemDialog(
    BuildContext context, {
    ShoppingItem? item,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return ShoppingItemFormDialog(item: item);
      },
    );

    if (saved != true || !context.mounted) {
      return;
    }

    final message = item == null
        ? 'Shopping item added.'
        : 'Shopping item updated.';

    _showMessage(context, message);
  }

  Future<void> _toggleCompleted(
    BuildContext context,
    ShoppingItemProvider provider,
    ShoppingItem item,
  ) async {
    final success = await provider.toggleCompleted(item.id);

    if (!success && context.mounted) {
      _showMessage(
        context,
        provider.errorMessage ?? 'Unable to update the shopping item.',
      );
    }
  }

  Future<void> _deleteItem(
    BuildContext context,
    ShoppingItemProvider provider,
    ShoppingItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete shopping item?'),
          content: Text(
            'Remove "${item.name}" from your '
            'shopping list?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await provider.deleteItem(item.id);

    if (!context.mounted) {
      return;
    }

    _showMessage(
      context,
      success
          ? '${item.name} was removed.'
          : provider.errorMessage ?? 'Unable to delete the shopping item.',
    );
  }

  Future<void> _clearCompletedItems(
    BuildContext context,
    ShoppingItemProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear completed items?'),
          content: Text(
            'This will remove '
            '${provider.completedCount} completed '
            'shopping item(s).',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await provider.clearCompletedItems();

    if (!context.mounted) {
      return;
    }

    _showMessage(
      context,
      success
          ? 'Completed shopping items were cleared.'
          : provider.errorMessage ?? 'Unable to clear completed items.',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ShoppingSummary extends StatelessWidget {
  const _ShoppingSummary({
    required this.pendingCount,
    required this.completedCount,
  });

  final int pendingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _SummaryValue(
                icon: Icons.shopping_cart_outlined,
                value: pendingCount,
                label: 'To buy',
                color: colorScheme.primary,
              ),
            ),
            Container(width: 1, height: 58, color: colorScheme.outlineVariant),
            Expanded(
              child: _SummaryValue(
                icon: Icons.check_circle_outline,
                value: completedCount,
                label: 'Completed',
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  const _ShoppingItemCard({
    required this.item,
    required this.isDisabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingItem item;
  final bool isDisabled;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textDecoration = item.isCompleted
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    final textColor = item.isCompleted
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        value: item.isCompleted,
        enabled: !isDisabled,
        onChanged: (_) {
          onToggle();
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: textDecoration,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_formatQuantity(item.quantity)} '
          '${item.unit}',
          style: TextStyle(decoration: textDecoration, color: textColor),
        ),
        secondary: PopupMenuButton<String>(
          tooltip: 'Shopping item actions',
          enabled: !isDisabled,
          onSelected: (action) {
            switch (action) {
              case 'edit':
                onEdit();
                break;

              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (_) {
            return const [
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
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

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

class _EmptyShoppingState extends StatelessWidget {
  const _EmptyShoppingState({required this.onAddItem, required this.onRefresh});

  final VoidCallback onAddItem;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Your shopping list is empty',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Add items you need to buy and mark '
            'them as completed while shopping.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Shopping Item'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingErrorState extends StatelessWidget {
  const _ShoppingErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../providers/shopping_item_provider.dart';
import '../../providers/storage_location_provider.dart';
import 'food_item_form_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  static const double _lowStockThreshold = 2;

  @override
  Widget build(BuildContext context) {
    // Nullable providers keep older widget tests working when
    // the test environment does not provide the inventory data layer.
    final foodItemProvider = context.watch<FoodItemProvider?>();

    final categoryProvider = context.watch<CategoryProvider?>();

    final storageLocationProvider = context.watch<StorageLocationProvider?>();

    final shoppingItemProvider = context.watch<ShoppingItemProvider?>();

    if (foodItemProvider == null ||
        categoryProvider == null ||
        storageLocationProvider == null) {
      return const Scaffold(
        body: Center(child: Text('Inventory is currently unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Inventory'),
        actions: [
          IconButton(
            tooltip: 'Refresh inventory',
            onPressed: foodItemProvider.reloadItems,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFoodItemForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Food'),
      ),
      body: _buildBody(
        context,
        foodItemProvider: foodItemProvider,
        categoryProvider: categoryProvider,
        storageLocationProvider: storageLocationProvider,
        shoppingItemProvider: shoppingItemProvider,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required FoodItemProvider foodItemProvider,
    required CategoryProvider categoryProvider,
    required StorageLocationProvider storageLocationProvider,
    required ShoppingItemProvider? shoppingItemProvider,
  }) {
    if (foodItemProvider.isLoading && !foodItemProvider.hasItems) {
      return const Center(child: CircularProgressIndicator());
    }

    if (foodItemProvider.errorMessage != null && !foodItemProvider.hasItems) {
      return _InventoryErrorState(
        message: foodItemProvider.errorMessage!,
        onRetry: foodItemProvider.reloadItems,
      );
    }

    if (!foodItemProvider.hasItems) {
      return _EmptyInventoryState(
        onAddFood: () {
          _openFoodItemForm(context);
        },
        onRefresh: foodItemProvider.reloadItems,
      );
    }

    final items = foodItemProvider.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _InventorySummary(
            totalItems: foodItemProvider.itemCount,
            expiringSoon: foodItemProvider.expiringSoonItems.length,
            expired: foodItemProvider.expiredItems.length,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Your Items',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              foodItemProvider.reloadItems();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final item = items[index];

                final categoryName =
                    categoryProvider.getCategoryById(item.categoryId)?.name ??
                    'Unknown category';

                final locationName =
                    storageLocationProvider
                        .getLocationById(item.storageLocationId)
                        ?.name ??
                    'Unknown location';

                final isLowStock = item.quantity <= _lowStockThreshold;

                final isInShoppingList =
                    shoppingItemProvider?.containsItemNamed(item.name) ?? false;

                return _FoodItemCard(
                  item: item,
                  categoryName: categoryName,
                  locationName: locationName,
                  isLowStock: isLowStock,
                  isInShoppingList: isInShoppingList,
                  onEdit: () {
                    _openFoodItemForm(context, item: item);
                  },
                  onAddToShoppingList: () {
                    _addToShoppingList(context, item);
                  },
                  onDelete: () {
                    _deleteFoodItem(context, item);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFoodItemForm(BuildContext context, {FoodItem? item}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return FoodItemFormScreen(item: item);
        },
      ),
    );
  }

  Future<void> _addToShoppingList(BuildContext context, FoodItem item) async {
    final provider = context.read<ShoppingItemProvider?>();

    if (provider == null) {
      _showMessage(context, 'The shopping list is currently unavailable.');
      return;
    }

    if (provider.containsItemNamed(item.name)) {
      _showMessage(context, '${item.name} is already in your shopping list.');
      return;
    }

    final success = await provider.addItem(
      name: item.name,
      quantity: 1,
      unit: item.unit,
    );

    if (!context.mounted) {
      return;
    }

    final message = success
        ? '${item.name} was added to your shopping list.'
        : provider.errorMessage ??
              'Unable to add the item to your shopping list.';

    _showMessage(context, message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteFoodItem(BuildContext context, FoodItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete food item?'),
          content: Text(
            'Are you sure you want to delete '
            '"${item.name}" from your inventory?',
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

    final provider = context.read<FoodItemProvider>();

    final success = await provider.deleteItem(item.id);

    if (!context.mounted) {
      return;
    }

    final message = success
        ? '${item.name} was removed.'
        : provider.errorMessage ?? 'Unable to delete the food item.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({
    required this.totalItems,
    required this.expiringSoon,
    required this.expired,
  });

  final int totalItems;
  final int expiringSoon;
  final int expired;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryItem(
                icon: Icons.inventory_2_outlined,
                value: totalItems,
                label: 'Total items',
                iconColor: colorScheme.primary,
              ),
            ),
            Expanded(
              child: _SummaryItem(
                icon: Icons.schedule_outlined,
                value: expiringSoon,
                label: 'Expiring soon',
                iconColor: colorScheme.tertiary,
              ),
            ),
            Expanded(
              child: _SummaryItem(
                icon: Icons.warning_amber_rounded,
                value: expired,
                label: 'Expired',
                iconColor: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  const _FoodItemCard({
    required this.item,
    required this.categoryName,
    required this.locationName,
    required this.isLowStock,
    required this.isInShoppingList,
    required this.onEdit,
    required this.onAddToShoppingList,
    required this.onDelete,
  });

  final FoodItem item;
  final String categoryName;
  final String locationName;
  final bool isLowStock;
  final bool isInShoppingList;
  final VoidCallback onEdit;
  final VoidCallback onAddToShoppingList;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expiryPresentation = _getExpiryPresentation(context, item.expiryDate);

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(child: Icon(Icons.fastfood_outlined)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatQuantity(item.quantity)} '
                      '${item.unit}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    if (isLowStock) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInShoppingList
                                  ? Icons.shopping_cart_checkout_rounded
                                  : Icons.remove_shopping_cart_outlined,
                              size: 15,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isInShoppingList
                                  ? 'Low stock • In shopping list'
                                  : 'Low stock',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    _InformationLine(
                      icon: Icons.category_outlined,
                      text: categoryName,
                    ),
                    const SizedBox(height: 4),
                    _InformationLine(
                      icon: Icons.kitchen_outlined,
                      text: locationName,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      expiryPresentation.text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: expiryPresentation.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Food item actions',
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit();
                      break;

                    case 'add_to_shopping':
                      onAddToShoppingList();
                      break;

                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),

                    if (isLowStock)
                      PopupMenuItem<String>(
                        value: 'add_to_shopping',
                        enabled: !isInShoppingList,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isInShoppingList
                                ? Icons.check_circle_outline
                                : Icons.add_shopping_cart_outlined,
                          ),
                          title: Text(
                            isInShoppingList
                                ? 'Already in Shopping List'
                                : 'Add to Shopping List',
                          ),
                        ),
                      ),

                    const PopupMenuItem<String>(
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
            ],
          ),
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

  static _ExpiryPresentation _getExpiryPresentation(
    BuildContext context,
    DateTime? expiryDate,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (expiryDate == null) {
      return _ExpiryPresentation(
        text: 'No expiry date',
        color: colorScheme.onSurfaceVariant,
      );
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final days = expiry.difference(today).inDays;

    if (days < 0) {
      final expiredDays = days.abs();

      return _ExpiryPresentation(
        text: expiredDays == 1
            ? 'Expired 1 day ago'
            : 'Expired $expiredDays days ago',
        color: colorScheme.error,
      );
    }

    if (days == 0) {
      return _ExpiryPresentation(
        text: 'Expires today',
        color: colorScheme.error,
      );
    }

    if (days == 1) {
      return _ExpiryPresentation(
        text: 'Expires tomorrow',
        color: colorScheme.tertiary,
      );
    }

    if (days <= 7) {
      return _ExpiryPresentation(
        text: 'Expires in $days days',
        color: colorScheme.tertiary,
      );
    }

    return _ExpiryPresentation(
      text: 'Expires ${DateFormat('dd MMM yyyy').format(expiry)}',
      color: colorScheme.onSurfaceVariant,
    );
  }
}

class _InformationLine extends StatelessWidget {
  const _InformationLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ExpiryPresentation {
  const _ExpiryPresentation({required this.text, required this.color});

  final String text;
  final Color color;
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({
    required this.onAddFood,
    required this.onRefresh,
  });

  final VoidCallback onAddFood;
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
            Icons.inventory_2_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Your inventory is empty',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your first food item to start '
            'tracking quantities and expiry dates.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: onAddFood,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Food Item'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryErrorState extends StatelessWidget {
  const _InventoryErrorState({required this.message, required this.onRetry});

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

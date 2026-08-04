import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/shopping_item_provider.dart';
import '../../providers/storage_location_provider.dart';
import '../inventory/food_item_form_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const double _lowStockThreshold = 2;

  @override
  Widget build(BuildContext context) {
    final foodItemProvider = context.watch<FoodItemProvider?>();

    final categoryProvider = context.watch<CategoryProvider?>();

    final storageLocationProvider = context.watch<StorageLocationProvider?>();

    final shoppingItemProvider = context.watch<ShoppingItemProvider?>();

    final notificationProvider = context.watch<NotificationProvider>();

    if (foodItemProvider == null ||
        categoryProvider == null ||
        storageLocationProvider == null) {
      return const Scaffold(
        body: Center(child: Text('Notifications are currently unavailable.')),
      );
    }

    final alertItems = foodItemProvider.items.where((item) {
      final hasAlert =
          _isExpired(item) || _isExpiringSoon(item) || _isLowStock(item);

      return hasAlert && !notificationProvider.isCleared(item.id.toString());
    }).toList()..sort(_compareAlertItems);

    final expiredCount = alertItems.where(_isExpired).length;

    final expiringSoonCount = alertItems.where(_isExpiringSoon).length;

    final lowStockCount = alertItems.where(_isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (alertItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.clear_all_rounded, size: 20),
                label: const Text(
                  'Clear All',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await notificationProvider.clearNotifications(
                    alertItems.map((item) => item.id.toString()).toList(),
                  );

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Notifications cleared')),
                    );
                },
              ),
            ),
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: foodItemProvider.reloadItems,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _NotificationSummary(
              expiredCount: expiredCount,
              expiringSoonCount: expiringSoonCount,
              lowStockCount: lowStockCount,
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Items Needing Attention',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _buildContent(
              context,
              foodItemProvider: foodItemProvider,
              categoryProvider: categoryProvider,
              storageLocationProvider: storageLocationProvider,
              shoppingItemProvider: shoppingItemProvider,
              alertItems: alertItems,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required FoodItemProvider foodItemProvider,
    required CategoryProvider categoryProvider,
    required StorageLocationProvider storageLocationProvider,
    required ShoppingItemProvider? shoppingItemProvider,
    required List<FoodItem> alertItems,
  }) {
    if (foodItemProvider.isLoading && alertItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (foodItemProvider.errorMessage != null && alertItems.isEmpty) {
      return _NotificationErrorState(
        message: foodItemProvider.errorMessage!,
        onRetry: foodItemProvider.reloadItems,
      );
    }

    if (alertItems.isEmpty) {
      return _EmptyNotificationState(onRefresh: foodItemProvider.reloadItems);
    }

    return RefreshIndicator(
      onRefresh: () async {
        foodItemProvider.reloadItems();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: alertItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = alertItems[index];

          final categoryName =
              categoryProvider.getCategoryById(item.categoryId)?.name ??
              'Unknown category';

          final locationName =
              storageLocationProvider
                  .getLocationById(item.storageLocationId)
                  ?.name ??
              'Unknown location';

          final isInShoppingList =
              shoppingItemProvider?.containsItemNamed(item.name) ?? false;

          return _NotificationItemCard(
            item: item,
            categoryName: categoryName,
            locationName: locationName,
            isExpired: _isExpired(item),
            isExpiringSoon: _isExpiringSoon(item),
            isLowStock: _isLowStock(item),
            isInShoppingList: isInShoppingList,
            onEdit: () {
              _openFoodItemForm(context, item);
            },
            onAddToShoppingList: () {
              _addToShoppingList(context, item);
            },
          );
        },
      ),
    );
  }

  Future<void> _openFoodItemForm(BuildContext context, FoodItem item) async {
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

    _showMessage(
      context,
      success
          ? '${item.name} was added to your shopping list.'
          : provider.errorMessage ?? 'Unable to add the item.',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static bool _isExpired(FoodItem item) {
    final expiryDate = item.expiryDate;

    if (expiryDate == null) {
      return false;
    }

    return _dateOnly(expiryDate).isBefore(_dateOnly(DateTime.now()));
  }

  static bool _isExpiringSoon(FoodItem item) {
    final expiryDate = item.expiryDate;

    if (expiryDate == null) {
      return false;
    }

    final today = _dateOnly(DateTime.now());

    final expiry = _dateOnly(expiryDate);

    final limit = today.add(const Duration(days: 7));

    return !expiry.isBefore(today) && !expiry.isAfter(limit);
  }

  static bool _isLowStock(FoodItem item) {
    return item.quantity <= _lowStockThreshold;
  }

  static int _compareAlertItems(FoodItem first, FoodItem second) {
    final firstPriority = _getAlertPriority(first);

    final secondPriority = _getAlertPriority(second);

    if (firstPriority != secondPriority) {
      return firstPriority.compareTo(secondPriority);
    }

    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }

  static int _getAlertPriority(FoodItem item) {
    if (_isExpired(item)) {
      return 0;
    }

    if (_isExpiringSoon(item)) {
      return 1;
    }

    return 2;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.lowStockCount,
  });

  final int expiredCount;
  final int expiringSoonCount;
  final int lowStockCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryValue(
                icon: Icons.warning_amber_rounded,
                value: expiredCount,
                label: 'Expired',
                color: colorScheme.error,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _SummaryValue(
                icon: Icons.schedule_outlined,
                value: expiringSoonCount,
                label: 'Expiring',
                color: colorScheme.tertiary,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _SummaryValue(
                icon: Icons.remove_shopping_cart_outlined,
                value: lowStockCount,
                label: 'Low stock',
                color: colorScheme.primary,
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
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

class _NotificationItemCard extends StatelessWidget {
  const _NotificationItemCard({
    required this.item,
    required this.categoryName,
    required this.locationName,
    required this.isExpired,
    required this.isExpiringSoon,
    required this.isLowStock,
    required this.isInShoppingList,
    required this.onEdit,
    required this.onAddToShoppingList,
  });

  final FoodItem item;
  final String categoryName;
  final String locationName;

  final bool isExpired;
  final bool isExpiringSoon;
  final bool isLowStock;
  final bool isInShoppingList;

  final VoidCallback onEdit;
  final VoidCallback onAddToShoppingList;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: onEdit,
        leading: Icon(
          isExpired
              ? Icons.warning
              : isExpiringSoon
              ? Icons.schedule
              : Icons.shopping_cart,
          color: isExpired ? colorScheme.error : colorScheme.primary,
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$categoryName • $locationName\n'
          '${item.quantity} ${item.unit}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            }

            if (value == 'shopping') {
              onAddToShoppingList();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Food Item')),
            if (isLowStock)
              PopupMenuItem(
                value: 'shopping',
                enabled: !isInShoppingList,
                child: Text(
                  isInShoppingList ? 'Already Added' : 'Add to Shopping List',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'You are all caught up',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Expired, expiring soon and low-stock '
            'items will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _NotificationErrorState extends StatelessWidget {
  const _NotificationErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

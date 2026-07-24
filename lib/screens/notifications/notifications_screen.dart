import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
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

    if (foodItemProvider == null ||
        categoryProvider == null ||
        storageLocationProvider == null) {
      return const Scaffold(
        body: Center(child: Text('Notifications are currently unavailable.')),
      );
    }

    final alertItems = foodItemProvider.items.where((item) {
      return _isExpired(item) || _isExpiringSoon(item) || _isLowStock(item);
    }).toList()..sort(_compareAlertItems);

    final expiredCount = foodItemProvider.items.where(_isExpired).length;

    final expiringSoonCount = foodItemProvider.items
        .where(_isExpiringSoon)
        .length;

    final lowStockCount = foodItemProvider.items.where(_isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: foodItemProvider.reloadItems,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
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
        separatorBuilder: (_, _) {
          return const SizedBox(height: 10);
        },
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
          : provider.errorMessage ??
                'Unable to add the item to your shopping list.',
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

    final today = _dateOnly(DateTime.now());

    return _dateOnly(expiryDate).isBefore(today);
  }

  static bool _isExpiringSoon(FoodItem item) {
    final expiryDate = item.expiryDate;

    if (expiryDate == null) {
      return false;
    }

    final today = _dateOnly(DateTime.now());

    final expiry = _dateOnly(expiryDate);

    final finalDate = today.add(const Duration(days: 7));

    return !expiry.isBefore(today) && !expiry.isAfter(finalDate);
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

    final firstExpiry = first.expiryDate;
    final secondExpiry = second.expiryDate;

    if (firstExpiry != null && secondExpiry != null) {
      final dateComparison = firstExpiry.compareTo(secondExpiry);

      if (dateComparison != 0) {
        return dateComparison;
      }
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
            _SummaryDivider(color: colorScheme.outlineVariant),
            Expanded(
              child: _SummaryValue(
                icon: Icons.schedule_outlined,
                value: expiringSoonCount,
                label: 'Expiring',
                color: colorScheme.tertiary,
              ),
            ),
            _SummaryDivider(color: colorScheme.outlineVariant),
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

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 58, color: color);
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
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _getPrimaryColor(colorScheme).withAlpha(30),
                child: Icon(
                  _getPrimaryIcon(),
                  color: _getPrimaryColor(colorScheme),
                ),
              ),
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
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$categoryName • $locationName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isExpired)
                          _AlertLabel(
                            icon: Icons.warning_amber_rounded,
                            text: _expiryMessage(),
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                          ),
                        if (isExpiringSoon)
                          _AlertLabel(
                            icon: Icons.schedule_outlined,
                            text: _expiryMessage(),
                            backgroundColor: colorScheme.tertiaryContainer,
                            foregroundColor: colorScheme.onTertiaryContainer,
                          ),
                        if (isLowStock)
                          _AlertLabel(
                            icon: isInShoppingList
                                ? Icons.shopping_cart_checkout_rounded
                                : Icons.remove_shopping_cart_outlined,
                            text: isInShoppingList
                                ? 'Low stock • Added'
                                : 'Low stock',
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Notification actions',
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit();
                      break;

                    case 'shopping':
                      onAddToShoppingList();
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
                        title: Text('Edit Food Item'),
                      ),
                    ),
                    if (isLowStock)
                      PopupMenuItem<String>(
                        value: 'shopping',
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
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPrimaryIcon() {
    if (isExpired) {
      return Icons.warning_amber_rounded;
    }

    if (isExpiringSoon) {
      return Icons.schedule_rounded;
    }

    return Icons.remove_shopping_cart_outlined;
  }

  Color _getPrimaryColor(ColorScheme colorScheme) {
    if (isExpired) {
      return colorScheme.error;
    }

    if (isExpiringSoon) {
      return colorScheme.tertiary;
    }

    return colorScheme.primary;
  }

  String _expiryMessage() {
    final expiryDate = item.expiryDate;

    if (expiryDate == null) {
      return 'No expiry date';
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final days = expiry.difference(today).inDays;

    if (days < 0) {
      final value = days.abs();

      return value == 1 ? 'Expired 1 day ago' : 'Expired $value days ago';
    }

    if (days == 0) {
      return 'Expires today';
    }

    if (days == 1) {
      return 'Expires tomorrow';
    }

    if (days <= 7) {
      return 'Expires in $days days';
    }

    return DateFormat('dd MMM yyyy').format(expiry);
  }

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

class _AlertLabel extends StatelessWidget {
  const _AlertLabel({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 70),
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'You are all caught up',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Expired, expiring-soon and low-stock '
            'food items will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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

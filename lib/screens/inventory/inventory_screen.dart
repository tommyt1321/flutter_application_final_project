import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../providers/shopping_item_provider.dart';
import '../../providers/storage_location_provider.dart';
import 'food_item_form_screen.dart';

enum FilterOption { all, available, expiring, expired, lowStock, consumed, donated, discarded }

enum _SortField { expiryDate, name, dateAdded, quantity, category }

bool shouldIncludeItemForFilter({
  required FoodItem item,
  required FilterOption filter,
  required bool isExpired,
  required bool isExpiringSoon,
  required bool isLowStock,
  required bool hasConsumed,
  required bool hasDonated,
  required bool hasDiscarded,
}) {
  switch (filter) {
    case FilterOption.all:
      return true;

    case FilterOption.available:
      return item.quantity > 0 && !isExpired && !hasConsumed && !hasDonated && !hasDiscarded;

    case FilterOption.expiring:
      return isExpiringSoon;

    case FilterOption.expired:
      return isExpired;

    case FilterOption.lowStock:
      return isLowStock;

    case FilterOption.consumed:
      return hasConsumed;

    case FilterOption.donated:
      return hasDonated;

    case FilterOption.discarded:
      return hasDiscarded;
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  static const double _lowStockThreshold = 2;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  FilterOption _filter = FilterOption.all;
  _SortField _sortField = _SortField.expiryDate;
  bool _ascending = true;

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

    // Apply search
    final searchClauses = _parseSearchClauses(_searchQuery);

    List<FoodItem> displayed = items.where((item) {
      if (searchClauses.isNotEmpty) {
        final searchableValues = [
          item.name.toLowerCase(),
          categoryProvider.getCategoryById(item.categoryId)?.name?.toLowerCase() ?? '',
          storageLocationProvider.getLocationById(item.storageLocationId)?.name?.toLowerCase() ?? '',
        ];

        final matchesAllClauses = searchClauses.every((clause) {
          final normalizedClause = clause.toLowerCase();
          return searchableValues.any((value) => value.contains(normalizedClause));
        });

        if (!matchesAllClauses) return false;
      }

      // Filter
      final isLowStock = item.quantity <= InventoryScreen._lowStockThreshold;
      final status = item.statusEnum;
      final hasConsumed = status == FoodItemStatus.consumed;
      final hasDonated = status == FoodItemStatus.donated;
      final hasDiscarded = status == FoodItemStatus.discarded;

      final isExpired = foodItemProvider.expiredItems.any((i) => i.id == item.id);
      final isExpiringSoon = foodItemProvider.expiringSoonItems.any((i) => i.id == item.id);

      return shouldIncludeItemForFilter(
        item: item,
        filter: _filter,
        isExpired: isExpired,
        isExpiringSoon: isExpiringSoon,
        isLowStock: isLowStock,
        hasConsumed: hasConsumed,
        hasDonated: hasDonated,
        hasDiscarded: hasDiscarded,
      );
    }).toList();

    // Sort
    displayed.sort((a, b) {
      int cmp = 0;

      switch (_sortField) {
        case _SortField.expiryDate:
          final ae = a.expiryDate;
          final be = b.expiryDate;
          if (ae == null && be == null) cmp = 0;
          else if (ae == null) cmp = 1;
          else if (be == null) cmp = -1;
          else cmp = ae.compareTo(be);
          break;

        case _SortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;

        case _SortField.dateAdded:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;

        case _SortField.quantity:
          cmp = a.quantity.compareTo(b.quantity);
          break;

        case _SortField.category:
          final an = categoryProvider.getCategoryById(a.categoryId)?.name?.toLowerCase() ?? '';
          final bn = categoryProvider.getCategoryById(b.categoryId)?.name?.toLowerCase() ?? '';
          cmp = an.compareTo(bn);
          break;
      }

      return _ascending ? cmp : -cmp;
    });

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final shouldUseSingleRow = maxWidth >= 900;

                  if (shouldUseSingleRow) {
                    return Row(
                      children: [
                        Text(
                          'Your Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Search by name, category, or location',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: Tooltip(
                                  message: 'Use commas or quotes to combine search terms',
                                  preferBelow: false,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<FilterOption>(
                            value: _filter,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(),
                            ),
                            items: FilterOption.values
                                .map((f) => DropdownMenuItem(value: f, child: Text(_filterLabel(f))))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _filter = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<_SortField>(
                            value: _sortField,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(),
                            ),
                            items: _SortField.values
                                .map((s) => DropdownMenuItem(value: s, child: Text(_sortLabel(s))))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _sortField = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          type: MaterialType.button,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: InkWell(
                            onTap: () => setState(() => _ascending = !_ascending),
                            child: const SizedBox(
                              width: 56,
                              height: 56,
                              child: Center(
                                child: Icon(Icons.swap_vert_rounded, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Your Items',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Search by name, category, or location',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: Tooltip(
                                    message: 'Use commas or quotes to combine search terms',
                                    preferBelow: false,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (v) => setState(() => _searchQuery = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<FilterOption>(
                              value: _filter,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(),
                              ),
                              items: FilterOption.values
                                  .map((f) => DropdownMenuItem(value: f, child: Text(_filterLabel(f))))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _filter = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<_SortField>(
                              value: _sortField,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(),
                              ),
                              items: _SortField.values
                                  .map((s) => DropdownMenuItem(value: s, child: Text(_sortLabel(s))))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _sortField = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            type: MaterialType.button,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: InkWell(
                              onTap: () => setState(() => _ascending = !_ascending),
                              child: const SizedBox(
                                width: 56,
                                height: 56,
                                child: Center(
                                  child: Icon(Icons.swap_vert_rounded, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
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
              itemCount: displayed.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final item = displayed[index];

                final categoryName =
                    categoryProvider.getCategoryById(item.categoryId)?.name ??
                    'Unknown category';

                final locationName =
                    storageLocationProvider
                        .getLocationById(item.storageLocationId)
                        ?.name ??
                    'Unknown location';

                final isLowStock = item.quantity <= InventoryScreen._lowStockThreshold;

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
                  onConsume: () => _handleConsume(context, item),
                  onDonate: () => _handleDonateOrDiscard(context, item, 'donated'),
                  onDiscard: () => _handleDonateOrDiscard(context, item, 'discarded'),
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

  Future<void> _handleConsume(BuildContext context, FoodItem item) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Consume ${item.name}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: 'Amount (${item.unit})'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Consume')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final entered = double.tryParse(controller.text) ?? 0.0;
    if (entered <= 0) {
      _showMessage(context, 'Enter a valid amount to consume.');
      return;
    }

    final newQuantity = (item.quantity - entered).clamp(0.0, double.infinity);

    final status = newQuantity <= 0 ? FoodItemStatus.consumed.name : item.status;

    final provider = context.read<FoodItemProvider>();

    final success = await provider.updateItem(
      item: item.copyWith(status: status),
      name: item.name,
      quantity: newQuantity,
      unit: item.unit,
      categoryId: item.categoryId,
      storageLocationId: item.storageLocationId,
      expiryDate: item.expiryDate,
      removeExpiryDate: false,
      notes: item.notes,
    );

    if (!context.mounted) return;

    if (success) {
      _showMessage(context, 'Consumed ${entered.toString()} ${item.unit} of ${item.name}.');
    } else {
      _showMessage(context, provider.errorMessage ?? 'Unable to update item.');
    }
  }

  Future<void> _handleDonateOrDiscard(BuildContext context, FoodItem item, String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${tag[0].toUpperCase()}${tag.substring(1)} ${item.name}?'),
          content: Text('This will set the quantity to zero and mark the item as $tag.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(tag[0].toUpperCase() + tag.substring(1))),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final provider = context.read<FoodItemProvider>();

    final success = await provider.updateItem(
      item: item.copyWith(quantity: 0, status: tag.toLowerCase()),
      name: item.name,
      quantity: 0,
      unit: item.unit,
      categoryId: item.categoryId,
      storageLocationId: item.storageLocationId,
      expiryDate: item.expiryDate,
      removeExpiryDate: false,
      notes: item.notes,
    );

    if (!context.mounted) return;

    if (success) {
      _showMessage(context, '${item.name} marked as $tag.');
    } else {
      _showMessage(context, provider.errorMessage ?? 'Unable to update item.');
    }
  }

  String _filterLabel(FilterOption f) {
    switch (f) {
      case FilterOption.all:
        return 'All';
      case FilterOption.available:
        return 'Available';
      case FilterOption.expiring:
        return 'Expiring';
      case FilterOption.expired:
        return 'Expired';
      case FilterOption.lowStock:
        return 'Low stock';
      case FilterOption.consumed:
        return 'Consumed';
      case FilterOption.donated:
        return 'Donated';
      case FilterOption.discarded:
        return 'Discarded';
    }
  }

  List<String> _parseSearchClauses(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final clauses = <String>[];
    final buffer = StringBuffer();
    bool inSingleQuotes = false;
    bool inDoubleQuotes = false;

    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];

      if (char == "'" && !inDoubleQuotes) {
        inSingleQuotes = !inSingleQuotes;
        continue;
      }

      if (char == '"' && !inSingleQuotes) {
        inDoubleQuotes = !inDoubleQuotes;
        continue;
      }

      if (char == ',' && !inSingleQuotes && !inDoubleQuotes) {
        final clause = buffer.toString().trim();
        if (clause.isNotEmpty) {
          clauses.add(clause);
        }
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    final lastClause = buffer.toString().trim();
    if (lastClause.isNotEmpty) {
      clauses.add(lastClause);
    }

    return clauses
        .map((clause) => clause.replaceAll("'", '').replaceAll('"', '').trim())
        .where((clause) => clause.isNotEmpty)
        .toList();
  }

  String _sortLabel(_SortField s) {
    switch (s) {
      case _SortField.expiryDate:
        return 'Expiry date';
      case _SortField.name:
        return 'Food name';
      case _SortField.dateAdded:
        return 'Date added';
      case _SortField.quantity:
        return 'Quantity';
      case _SortField.category:
        return 'Category';
    }
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
    required this.onConsume,
    required this.onDonate,
    required this.onDiscard,
  });

  final FoodItem item;
  final String categoryName;
  final String locationName;
  final bool isLowStock;
  final bool isInShoppingList;
  final VoidCallback onEdit;
  final VoidCallback onAddToShoppingList;
  final VoidCallback onDelete;
  final VoidCallback onConsume;
  final VoidCallback onDonate;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final expiryPresentation = _getExpiryPresentation(context, item.expiryDate);

    final colorScheme = Theme.of(context).colorScheme;
    final status = item.statusEnum;
    final hasConsumed = status == FoodItemStatus.consumed;
    final hasDonated = status == FoodItemStatus.donated;
    final hasDiscarded = status == FoodItemStatus.discarded;
    final statusPresentation = _getStatusPresentation(
      context,
      isLowStock: isLowStock,
      hasConsumed: hasConsumed,
      hasDonated: hasDonated,
      hasDiscarded: hasDiscarded,
      isInShoppingList: isInShoppingList,
    );

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

                    if (isLowStock || hasConsumed || hasDonated || hasDiscarded) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusPresentation.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusPresentation.icon,
                              size: 15,
                              color: statusPresentation.textColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusPresentation.label,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: statusPresentation.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    if (hasConsumed || hasDonated || hasDiscarded) ...[
                      _InformationLine(
                        icon: Icons.access_time_outlined,
                        text: _statusTimestampLabel(item),
                      ),
                      const SizedBox(height: 4),
                    ],
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
              if (!hasConsumed && !hasDonated && !hasDiscarded)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Consume',
                      icon: const Icon(Icons.local_drink_outlined),
                      onPressed: onConsume,
                    ),
                    IconButton(
                      tooltip: 'Donate',
                      icon: const Icon(Icons.card_giftcard_outlined),
                      onPressed: onDonate,
                    ),
                    IconButton(
                      tooltip: 'Discard',
                      icon: const Icon(Icons.delete_forever_outlined),
                      onPressed: onDiscard,
                    ),
                  ],
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

  static String _statusTimestampLabel(FoodItem item) {
    final timestamp = item.statusTimestamp;

    if (timestamp == null) {
      return 'Status updated recently';
    }

    final formattedDate = DateFormat('dd MMM yyyy').format(timestamp);
    final statusLabel = item.statusEnum.label;

    return '$statusLabel at $formattedDate';
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

_StatusPresentation _getStatusPresentation(
  BuildContext context, {
  required bool isLowStock,
  required bool hasConsumed,
  required bool hasDonated,
  required bool hasDiscarded,
  required bool isInShoppingList,
}) {
  if (hasConsumed) {
    return _StatusPresentation(
      label: 'Consumed',
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade100,
      textColor: Colors.green.shade900,
    );
  }

  if (hasDonated) {
    return _StatusPresentation(
      label: 'Donated',
      icon: Icons.card_giftcard_outlined,
      backgroundColor: Colors.amber.shade100,
      textColor: Colors.amber.shade900,
    );
  }

  if (hasDiscarded) {
    return _StatusPresentation(
      label: 'Discarded',
      icon: Icons.delete_forever_outlined,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      textColor: Theme.of(context).colorScheme.onErrorContainer,
    );
  }

  return _StatusPresentation(
    label: isInShoppingList ? 'Low stock • In shopping list' : 'Low stock',
    icon: isInShoppingList
        ? Icons.shopping_cart_checkout_rounded
        : Icons.remove_shopping_cart_outlined,
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
    textColor: Theme.of(context).colorScheme.onErrorContainer,
  );
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../providers/storage_location_provider.dart';
import '../inventory/food_item_form_screen.dart';

class UseFirstScreen extends StatelessWidget {
  const UseFirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foodItemProvider = context.watch<FoodItemProvider?>();

    final categoryProvider = context.watch<CategoryProvider?>();

    final storageLocationProvider = context.watch<StorageLocationProvider?>();

    if (foodItemProvider == null ||
        categoryProvider == null ||
        storageLocationProvider == null) {
      return const Scaffold(
        body: Center(child: Text('Expiry recommendations are unavailable.')),
      );
    }

    final Map<String, FoodItem> itemMap = {};

    for (final item in foodItemProvider.expiredItems) {
      itemMap[item.id] = item;
    }

    for (final item in foodItemProvider.expiringSoonItems) {
      itemMap[item.id] = item;
    }

    for (final item in foodItemProvider.manuallySelectedItems) {
      itemMap[item.id] = item;
    }

    final attentionItems = itemMap.values.toList()
      ..sort((a, b) {
        final aDate = a.expiryDate ?? DateTime(9999);
        final bDate = b.expiryDate ?? DateTime(9999);

        return aDate.compareTo(bDate);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Use First'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
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
            child: _ExpirySummary(
              expiredCount: foodItemProvider.expiredItems.length,
              expiringSoonCount: foodItemProvider.expiringSoonItems.length,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Priority Items',
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
              attentionItems: attentionItems,
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
    required List<FoodItem> attentionItems,
  }) {
    if (foodItemProvider.isLoading && attentionItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (foodItemProvider.errorMessage != null && attentionItems.isEmpty) {
      return _UseFirstErrorState(
        message: foodItemProvider.errorMessage!,
        onRetry: foodItemProvider.reloadItems,
      );
    }

    if (attentionItems.isEmpty) {
      return _UseFirstEmptyState(onRefresh: foodItemProvider.reloadItems);
    }

    return RefreshIndicator(
      onRefresh: () async {
        foodItemProvider.reloadItems();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: attentionItems.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          final item = attentionItems[index];

          final categoryName =
              categoryProvider.getCategoryById(item.categoryId)?.name ??
              'Unknown category';

          final locationName =
              storageLocationProvider
                  .getLocationById(item.storageLocationId)
                  ?.name ??
              'Unknown location';

          return _UseFirstItemCard(
            item: item,
            categoryName: categoryName,
            locationName: locationName,
            onTap: () {
              _openFoodItemForm(context, item);
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
}

class _ExpirySummary extends StatelessWidget {
  const _ExpirySummary({
    required this.expiredCount,
    required this.expiringSoonCount,
  });

  final int expiredCount;
  final int expiringSoonCount;

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
                icon: Icons.warning_amber_rounded,
                value: expiredCount,
                label: 'Expired',
                color: colorScheme.error,
              ),
            ),
            Container(width: 1, height: 60, color: colorScheme.outlineVariant),
            Expanded(
              child: _SummaryValue(
                icon: Icons.schedule_rounded,
                value: expiringSoonCount,
                label: 'Next 7 days',
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

class _UseFirstItemCard extends StatelessWidget {
  const _UseFirstItemCard({
    required this.item,
    required this.categoryName,
    required this.locationName,
    required this.onTap,
  });

  final FoodItem item;
  final String categoryName;
  final String locationName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expiryInformation = _getExpiryInformation(context, item.expiryDate!);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: expiryInformation.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  expiryInformation.icon,
                  color: expiryInformation.color,
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
                    const SizedBox(height: 8),
                    Text(
                      '$categoryName • $locationName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expiryInformation.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: expiryInformation.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
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

  static _ExpiryInformation _getExpiryInformation(
    BuildContext context,
    DateTime expiryDate,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final difference = expiry.difference(today).inDays;

    if (difference < 0) {
      final expiredDays = difference.abs();

      return _ExpiryInformation(
        text: expiredDays == 1
            ? 'Expired 1 day ago'
            : 'Expired $expiredDays days ago',
        icon: Icons.warning_amber_rounded,
        color: colorScheme.error,
      );
    }

    if (difference == 0) {
      return _ExpiryInformation(
        text: 'Expires today',
        icon: Icons.warning_amber_rounded,
        color: Colors.red,
      );
    }

    if (difference == 1) {
      return _ExpiryInformation(
        text: 'Expires tomorrow',
        icon: Icons.schedule_rounded,
        color: Colors.red,
      );
    }

    return _ExpiryInformation(
      text:
          'Expires in $difference days · '
          '${DateFormat('dd MMM yyyy').format(expiry)}',
      icon: Icons.schedule_rounded,
      color: colorScheme.tertiary,
    );
  }
}

class _ExpiryInformation {
  const _ExpiryInformation({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;
}

class _UseFirstEmptyState extends StatelessWidget {
  const _UseFirstEmptyState({required this.onRefresh});

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
          const SizedBox(height: 60),
          Icon(
            Icons.eco_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nothing needs attention',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Food that has expired or will expire '
            'within seven days will appear here.',
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

class _UseFirstErrorState extends StatelessWidget {
  const _UseFirstErrorState({required this.message, required this.onRetry});

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

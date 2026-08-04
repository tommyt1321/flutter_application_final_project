import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/food_item.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../providers/storage_location_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/dashboard_summary_card.dart';
import '../inventory/food_item_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.onOpenInventory,
    this.onOpenNotifications,
    this.onOpenUseFirst,
  });

  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenUseFirst;

  // Temporary low-stock rule.
  // This can later be replaced with a user-defined threshold.
  static const double _lowStockThreshold = 2;

  @override
  Widget build(BuildContext context) {
    final foodItemProvider = context.watch<FoodItemProvider>();

    final categoryProvider = context.watch<CategoryProvider?>();

    final storageLocationProvider = context.watch<StorageLocationProvider?>();

    final items = foodItemProvider.items;

    final expiringSoonCount = foodItemProvider.expiringSoonItems.length;

    final expiredCount = foodItemProvider.expiredItems.length;

    final totalItems = items.length;

    final lowStockCount = items.where((item) {
      return item.statusEnum == FoodItemStatus.available &&
          item.quantity <= _lowStockThreshold;
    }).length;

    final useFirstItems = items
        .where((item) {
          return _needsAttention(item);
        })
        .take(3)
        .toList();

    final notificationProvider = context.watch<NotificationProvider>();

    final notificationCount = notificationProvider.getNotificationCount(items);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PantryPal'),
            Text(
              'Your food at a glance',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Inventory alerts',
            onPressed: () {
              _handleNotificationPressed(context, notificationCount);
            },
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return RefreshIndicator(
              onRefresh: () async {
                foodItemProvider.reloadItems();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (foodItemProvider.isLoading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                    ],
                    _WelcomeCard(
                      onAddFood: () {
                        _openFoodItemForm(context);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pantry Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.45 : 1.15,
                      children: [
                        DashboardSummaryCard(
                          title: 'Total Items',
                          value: totalItems.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                        DashboardSummaryCard(
                          title: 'Expiring Soon',
                          value: expiringSoonCount.toString(),
                          icon: Icons.schedule_outlined,
                          color: AppColors.expiringSoon,
                        ),
                        DashboardSummaryCard(
                          title: 'Expired',
                          value: expiredCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.expired,
                        ),
                        DashboardSummaryCard(
                          title: 'Low Stock',
                          value: lowStockCount.toString(),
                          icon: Icons.remove_shopping_cart_outlined,
                          color: AppColors.lowStock,
                          onTap: lowStockCount > 0 ? onOpenInventory : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Use These First',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: onOpenUseFirst,
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (foodItemProvider.errorMessage != null && items.isEmpty)
                      _DashboardErrorCard(
                        message: foodItemProvider.errorMessage!,
                        onRetry: foodItemProvider.reloadItems,
                      )
                    else if (useFirstItems.isEmpty)
                      const _UseFirstEmptyCard()
                    else
                      ...useFirstItems.map((item) {
                        final categoryName =
                            categoryProvider
                                ?.getCategoryById(item.categoryId)
                                ?.name ??
                            'Unknown category';

                        final locationName =
                            storageLocationProvider
                                ?.getLocationById(item.storageLocationId)
                                ?.name ??
                            'Unknown location';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _UseFirstFoodCard(
                            item: item,
                            categoryName: categoryName,
                            locationName: locationName,
                            onTap: () {
                              _openFoodItemForm(context, item: item);
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleNotificationPressed(BuildContext context, int notificationCount) {
    if (notificationCount == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No food items need attention.')),
        );

      return;
    }

    final openNotifications = onOpenNotifications ?? onOpenInventory;

    openNotifications?.call();
  }

  Future<void> _openFoodItemForm(BuildContext context, {FoodItem? item}) async {
    final categoryProvider = context.read<CategoryProvider>();

    final storageLocationProvider = context.read<StorageLocationProvider>();

    if (categoryProvider.categories.isEmpty ||
        storageLocationProvider.locations.isEmpty) {
      _showMessage(
        context,
        'Please wait for categories and storage '
        'locations to finish loading.',
      );

      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return FoodItemFormScreen(item: item);
        },
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static bool _needsAttention(FoodItem item) {
    if (item.statusEnum != FoodItemStatus.available) {
      return false;
    }

    final expiryDate = item.expiryDate;

    if (expiryDate == null) {
      return false;
    }

    final today = _dateOnly(DateTime.now());

    final finalDate = today.add(const Duration(days: 7));

    return !_dateOnly(expiryDate).isAfter(finalDate);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onAddFood});

  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 430;

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WelcomeText(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _DashboardAddFoodButton(onPressed: onAddFood),
                ),
              ],
            );
          }

          return Row(
            children: [
              const Expanded(child: _WelcomeText()),
              const SizedBox(width: 20),
              SizedBox(
                width: 190,
                child: _DashboardAddFoodButton(onPressed: onAddFood),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardAddFoodButton extends StatelessWidget {
  const _DashboardAddFoodButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('dashboard_add_food_button'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withAlpha(20),
        side: const BorderSide(color: Colors.white70, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Add Food',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to PantryPal',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'Track your food and reduce '
          'unnecessary waste.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(220)),
        ),
      ],
    );
  }
}

class _UseFirstFoodCard extends StatelessWidget {
  const _UseFirstFoodCard({
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatQuantity(item.quantity)} '
                      '${item.unit} • $categoryName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      expiryInformation.text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: expiryInformation.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
          '${DateFormat('dd MMM').format(expiry)}',
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

class _UseFirstEmptyCard extends StatelessWidget {
  const _UseFirstEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.eco_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nothing needs attention yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Food that is nearing expiry '
                    'will appear here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
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

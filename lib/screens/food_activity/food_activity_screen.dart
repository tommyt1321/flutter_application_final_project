import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_activity.dart';
import '../../providers/food_activity_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'log_food_activity_dialog.dart';

class FoodActivityScreen extends StatelessWidget {
  const FoodActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodActivityProvider?>();

    if (provider == null) {
      return const Scaffold(
        body: Center(child: Text('Food activity is currently unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Activity'),
        actions: [
          IconButton(
            tooltip: 'Refresh activity',
            onPressed: provider.reloadActivities,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          heroTag: 'food_activity_fab',
        onPressed: provider.isSubmitting
            ? null
            : () {
                _openLogDialog(context);
              },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Activity'),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, FoodActivityProvider provider) {
    if (provider.isLoading && !provider.hasActivities) {
      return const LoadingView(message: 'Loading food activity...');
    }

    if (provider.errorMessage != null && !provider.hasActivities) {
      return ErrorView(
        message: provider.errorMessage!,
        onRetry: provider.reloadActivities,
      );
    }

    if (!provider.hasActivities) {
      return EmptyState(
        icon: Icons.history_outlined,
        title: 'No activity logged yet',
        message:
            'Log when food is consumed, wasted, or expired to '
            'start building your analytics.',
        buttonText: 'Log Activity',
        onButtonPressed: () {
          _openLogDialog(context);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        provider.reloadActivities();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.activities.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final activity = provider.activities[index];

          return _FoodActivityCard(
            activity: activity,
            isDisabled: provider.isSubmitting,
            onDelete: () {
              _deleteActivity(context, provider, activity);
            },
          );
        },
      ),
    );
  }

  Future<void> _openLogDialog(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LogFoodActivityDialog(),
    );

    if (saved != true || !context.mounted) {
      return;
    }

    _showMessage(context, 'Food activity logged.');
  }

  Future<void> _deleteActivity(
    BuildContext context,
    FoodActivityProvider provider,
    FoodActivity activity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete activity?'),
          content: Text(
            'Remove this ${_labelFor(activity.activityType).toLowerCase()} '
            'entry for "${activity.foodItemName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await provider.deleteActivity(activity.id);

    if (!context.mounted) {
      return;
    }

    _showMessage(
      context,
      success
          ? 'Activity entry removed.'
          : provider.errorMessage ?? 'Unable to delete this entry.',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _labelFor(ActivityType type) => switch (type) {
    ActivityType.added => 'Added',
    ActivityType.consumed => 'Consumed',
    ActivityType.wasted => 'Wasted',
    ActivityType.expired => 'Expired',
  };
}

class _FoodActivityCard extends StatelessWidget {
  const _FoodActivityCard({
    required this.activity,
    required this.isDisabled,
    required this.onDelete,
  });

  final FoodActivity activity;
  final bool isDisabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color) = _iconAndColorFor(activity.activityType, colorScheme);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          activity.foodItemName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${FoodActivityScreen._labelFor(activity.activityType)} · '
          '${_formatQuantity(activity.quantity)} ${activity.unit}'
          '${activity.notes != null ? ' · ${activity.notes}' : ''}',
        ),
        trailing: IconButton(
          tooltip: 'Delete entry',
          onPressed: isDisabled ? null : onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  (IconData, Color) _iconAndColorFor(
    ActivityType type,
    ColorScheme colorScheme,
  ) {
    return switch (type) {
      ActivityType.added => (Icons.add_circle_outline, colorScheme.primary),
      ActivityType.consumed => (Icons.restaurant_outlined, colorScheme.tertiary),
      ActivityType.wasted => (Icons.delete_outline, colorScheme.error),
      ActivityType.expired => (Icons.warning_amber_outlined, colorScheme.error),
    };
  }

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

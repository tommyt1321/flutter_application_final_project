import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/analytics_summary.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider?>();

    if (provider == null) {
      return const Scaffold(
        body: Center(child: Text('Analytics is currently unavailable.')),
      );
    }

    final summary = provider.currentSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<AnalyticsPeriod>(
            tooltip: 'Change period',
            onSelected: (period) {
              context.read<AnalyticsProvider>().changePeriod(period);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: AnalyticsPeriod.last7Days,
                child: Text('Last 7 days'),
              ),
              PopupMenuItem(
                value: AnalyticsPeriod.last30Days,
                child: Text('Last 30 days'),
              ),
              PopupMenuItem(
                value: AnalyticsPeriod.allTime,
                child: Text('All time'),
              ),
            ],
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: () => context.read<AnalyticsProvider>().refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(context, provider, summary),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsProvider provider,
    AnalyticsSummary? summary,
  ) {
    if (provider.isLoading && summary == null) {
      return const LoadingView(message: 'Calculating analytics...');
    }

    if (provider.errorMessage != null && summary == null) {
      return ErrorView(
        message: provider.errorMessage!,
        onRetry: provider.refresh,
      );
    }

    if (summary == null) {
      return const Center(child: Text('No analytics available yet.'));
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            '${_formatDate(summary.periodStart)} — '
            '${_formatDate(summary.periodEnd)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.add_circle_outline,
                  label: 'Added',
                  value: summary.totalAdded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.restaurant_outlined,
                  label: 'Consumed',
                  value: summary.totalConsumed,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.delete_outline,
                  label: 'Wasted',
                  value: summary.totalWasted,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber_outlined,
                  label: 'Expired',
                  value: summary.totalExpired,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waste Rate',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: summary.wastePercentage,
                      minHeight: 12,
                      color: Theme.of(context).colorScheme.error,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((summary.wastePercentage) * 100).toStringAsFixed(1)}% '
                    'of added food was wasted in this period.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (summary.mostWastedItemName != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down,
                          size: 20,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Most wasted: ${summary.mostWastedItemName}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              _formatQuantity(value),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: color),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
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

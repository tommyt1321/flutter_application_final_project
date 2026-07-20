import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/dashboard_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Badge(child: Icon(Icons.notifications_outlined)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeCard(onAddFood: () {}),
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
                    children: const [
                      DashboardSummaryCard(
                        title: 'Total Items',
                        value: '0',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primary,
                      ),
                      DashboardSummaryCard(
                        title: 'Expiring Soon',
                        value: '0',
                        icon: Icons.schedule_outlined,
                        color: AppColors.expiringSoon,
                      ),
                      DashboardSummaryCard(
                        title: 'Expired',
                        value: '0',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.expired,
                      ),
                      DashboardSummaryCard(
                        title: 'Low Stock',
                        value: '0',
                        icon: Icons.remove_shopping_cart_outlined,
                        color: AppColors.lowStock,
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
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _UseFirstEmptyCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WelcomeText(),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Add Food',
                  icon: Icons.add,
                  isOutlined: true,
                  onPressed: onAddFood,
                ),
              ],
            );
          }

          return Row(
            children: [
              const Expanded(child: _WelcomeText()),
              const SizedBox(width: 20),
              SizedBox(
                width: 200,
                child: AppButton(
                  text: 'Add Food',
                  icon: Icons.add,
                  isOutlined: true,
                  onPressed: onAddFood,
                ),
              ),
            ],
          );
        },
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
          'Track your food and reduce unnecessary waste.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(220)),
        ),
      ],
    );
  }
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
                    'Food that is nearing expiry will appear here.',
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

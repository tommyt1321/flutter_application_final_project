import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 24),
          Text(
            'Pantry Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Manage Categories'),
                  subtitle: const Text('Create and organize food categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.manageCategories);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.kitchen_outlined),
                  title: const Text('Storage Locations'),
                  subtitle: const Text('Manage where your food is stored'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.manageStorageLocations);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Application', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.dark_mode_outlined),
                  title: Text('Appearance'),
                  subtitle: Text('Light and dark theme settings'),
                  trailing: Icon(Icons.chevron_right),
                  enabled: false,
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About PantryPal'),
                  subtitle: Text('Version 1.6.7'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PantryPal User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your pantry preferences',
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

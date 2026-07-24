import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  Future<void> _changeTheme(BuildContext context, ThemeMode mode) async {
    final provider = context.read<SettingsProvider>();

    final success = await provider.setThemeMode(mode);

    if (!context.mounted || success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? 'Unable to change the appearance.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your theme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your selection will be remembered when you reopen PantryPal.',
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
          const SizedBox(height: 20),
          _ThemeOptionTile(
            title: 'System default',
            description: 'Follow the appearance setting of your device.',
            icon: Icons.settings_suggest_outlined,
            mode: ThemeMode.system,
            currentMode: provider.themeMode,
            isSaving: provider.isSaving,
            onTap: () {
              _changeTheme(context, ThemeMode.system);
            },
          ),
          const SizedBox(height: 8),
          _ThemeOptionTile(
            title: 'Light mode',
            description: 'Always display PantryPal using the light theme.',
            icon: Icons.light_mode_outlined,
            mode: ThemeMode.light,
            currentMode: provider.themeMode,
            isSaving: provider.isSaving,
            onTap: () {
              _changeTheme(context, ThemeMode.light);
            },
          ),
          const SizedBox(height: 8),
          _ThemeOptionTile(
            title: 'Dark mode',
            description: 'Always display PantryPal using the dark theme.',
            icon: Icons.dark_mode_outlined,
            mode: ThemeMode.dark,
            currentMode: provider.themeMode,
            isSaving: provider.isSaving,
            onTap: () {
              _changeTheme(context, ThemeMode.dark);
            },
          ),
          if (provider.isSaving) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.mode,
    required this.currentMode,
    required this.isSaving,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode currentMode;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentMode == mode;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: !isSaving,
        onTap: isSaving ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

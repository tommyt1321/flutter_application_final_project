import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/settings_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editDisplayName(BuildContext context) async {
    final provider = context.read<SettingsProvider>();

    final newName = await showDialog<String>(
      context: context,
      builder: (_) {
        return _EditDisplayNameDialog(initialName: provider.displayName);
      },
    );

    if (!context.mounted || newName == null) {
      return;
    }

    final success = await provider.setDisplayName(newName);

    if (!context.mounted) {
      return;
    }

    final message = success
        ? 'Profile name updated successfully.'
        : provider.errorMessage ?? 'Unable to update the profile name.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final displayName = context.select<SettingsProvider, String>(
      (provider) => provider.displayName,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            displayName: displayName,
            onEdit: () {
              _editDisplayName(context);
            },
          ),
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
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Appearance'),
                  subtitle: const Text('Light, dark or system theme'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.appearance);
                  },
                ),
                const Divider(height: 1),
                const ListTile(
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
  const _ProfileHeader({required this.displayName, required this.onEdit});

  final String displayName;
  final VoidCallback onEdit;

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
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            IconButton(
              tooltip: 'Edit profile name',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDisplayNameDialog extends StatefulWidget {
  const _EditDisplayNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditDisplayNameDialog> createState() {
    return _EditDisplayNameDialogState();
  }
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nameController.text.length,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile Name'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Profile name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              final name = value?.trim() ?? '';

              if (name.length < 2) {
                return 'Please enter at least 2 characters.';
              }

              if (name.length > 30) {
                return 'The name cannot exceed 30 characters.';
              }

              return null;
            },
            onFieldSubmitted: (_) {
              _submit();
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

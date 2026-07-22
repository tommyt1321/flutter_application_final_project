import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/storage_location_icon_mapper.dart';
import '../../models/storage_location.dart';
import '../../providers/storage_location_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'storage_location_form_dialog.dart';

class ManageStorageLocationsScreen extends StatelessWidget {
  const ManageStorageLocationsScreen({super.key});

  Future<void> _showLocationForm(
    BuildContext context, {
    StorageLocation? location,
  }) async {
    final wasSaved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StorageLocationFormDialog(location: location);
      },
    );

    if (!context.mounted || wasSaved != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          location == null
              ? 'Storage location added successfully.'
              : 'Storage location updated successfully.',
        ),
      ),
    );
  }

  Future<void> _deleteLocation(
    BuildContext context,
    StorageLocation location,
  ) async {
    final shouldDelete = await showConfirmationDialog(
      context: context,
      title: 'Delete storage location?',
      message: 'The location "${location.name}" will be permanently removed.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!context.mounted || !shouldDelete) {
      return;
    }

    final provider = context.read<StorageLocationProvider>();

    final success = await provider.deleteLocation(location.id);

    if (!context.mounted) {
      return;
    }

    final message = success
        ? 'Storage location deleted successfully.'
        : provider.errorMessage ?? 'Unable to delete the storage location.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage Locations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showLocationForm(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Location'),
      ),
      body: Consumer<StorageLocationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingView(message: 'Loading storage locations...');
          }

          if (provider.errorMessage != null && provider.locations.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.initialize,
            );
          }

          if (provider.locations.isEmpty) {
            return EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No storage locations',
              message: 'Add a storage location to organize where food is kept.',
              buttonText: 'Add Location',
              onButtonPressed: () {
                _showLocationForm(context);
              },
            );
          }

          return Column(
            children: [
              _LocationSummaryHeader(locationCount: provider.locationCount),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: provider.locations.length,
                  separatorBuilder: (_, _) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final location = provider.locations[index];

                    return _StorageLocationListTile(
                      location: location,
                      onEdit: () {
                        _showLocationForm(context, location: location);
                      },
                      onDelete: () {
                        _deleteLocation(context, location);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationSummaryHeader extends StatelessWidget {
  const _LocationSummaryHeader({required this.locationCount});

  final int locationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$locationCount storage locations available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageLocationListTile extends StatelessWidget {
  const _StorageLocationListTile({
    required this.location,
    required this.onEdit,
    required this.onDelete,
  });

  final StorageLocation location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            StorageLocationIconMapper.fromKey(location.iconKey),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          location.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          location.isDefault ? 'Default location' : 'Custom location',
        ),
        trailing: location.isDefault
            ? Tooltip(
                message: 'Default locations cannot be changed',
                child: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : PopupMenuButton<_StorageLocationAction>(
                tooltip: 'Storage location actions',
                onSelected: (action) {
                  switch (action) {
                    case _StorageLocationAction.edit:
                      onEdit();
                      return;

                    case _StorageLocationAction.delete:
                      onDelete();
                      return;
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: _StorageLocationAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _StorageLocationAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ];
                },
              ),
      ),
    );
  }
}

enum _StorageLocationAction { edit, delete }

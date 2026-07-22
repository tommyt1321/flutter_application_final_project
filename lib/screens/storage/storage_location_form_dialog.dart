import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/storage_location_icon_mapper.dart';
import '../../models/storage_location.dart';
import '../../providers/storage_location_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class StorageLocationFormDialog extends StatefulWidget {
  const StorageLocationFormDialog({this.location, super.key});

  final StorageLocation? location;

  bool get isEditing => location != null;

  @override
  State<StorageLocationFormDialog> createState() {
    return _StorageLocationFormDialogState();
  }
}

class _StorageLocationFormDialogState extends State<StorageLocationFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late String _selectedIconKey;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.location?.name ?? '');

    _selectedIconKey = widget.location?.iconKey ?? 'other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final provider = context.read<StorageLocationProvider>();

    final bool success;

    if (widget.isEditing) {
      success = await provider.updateLocation(
        location: widget.location!,
        name: _nameController.text,
        iconKey: _selectedIconKey,
      );
    } else {
      success = await provider.addLocation(
        name: _nameController.text,
        iconKey: _selectedIconKey,
      );
    }

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ?? 'Unable to save the storage location.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<StorageLocationProvider, bool>(
      (provider) => provider.isSubmitting,
    );

    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Edit Storage Location' : 'Add Storage Location',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Location name',
                  hint: 'Example: Dining Room Cabinet',
                  prefixIcon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Please enter a storage location name.';
                    }

                    if (name.length < 2) {
                      return 'The name must contain at least 2 characters.';
                    }

                    if (name.length > 30) {
                      return 'The name cannot exceed 30 characters.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIconKey,
                  decoration: const InputDecoration(
                    labelText: 'Location icon',
                    prefixIcon: Icon(Icons.emoji_emotions_outlined),
                  ),
                  items: StorageLocationIconMapper.options.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.keyName,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 21),
                          const SizedBox(width: 12),
                          Text(option.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedIconKey = value;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 150,
          child: AppButton(
            text: widget.isEditing ? 'Save' : 'Add',
            icon: widget.isEditing ? Icons.save_outlined : Icons.add,
            isLoading: isSubmitting,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

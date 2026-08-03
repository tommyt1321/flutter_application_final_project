import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_activity.dart';
import '../../providers/food_activity_provider.dart';

/// Manual activity logging entry point. Most "consumed"/"wasted"/"expired"
/// entries will ideally be triggered from the pantry item screen once a
/// "mark status" action is added there — this dialog covers logging
/// something directly from the Food Activity screen in the meantime.
class LogFoodActivityDialog extends StatefulWidget {
  const LogFoodActivityDialog({super.key});

  @override
  State<LogFoodActivityDialog> createState() => _LogFoodActivityDialogState();
}

class _LogFoodActivityDialogState extends State<LogFoodActivityDialog> {
  static const List<String> _defaultUnits = [
    'pcs',
    'g',
    'kg',
    'mL',
    'L',
    'pack',
    'box',
    'bottle',
    'can',
    'carton',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _notesController = TextEditingController();

  ActivityType _selectedType = ActivityType.consumed;
  String _selectedUnit = _defaultUnits.first;
  String? _localErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _localErrorMessage = null);

    final provider = context.read<FoodActivityProvider>();

    final success = await provider.logActivity(
      // No linked FoodItem id for a manual entry logged this way.
      // Once a "mark status" action exists on the pantry item screen,
      // that flow should call logActivity with the real FoodItem's id
      // instead of this placeholder.
      foodItemId: 'manual_entry',
      foodItemName: _nameController.text.trim(),
      activityType: _selectedType,
      quantity: double.parse(_quantityController.text),
      unit: _selectedUnit,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _localErrorMessage =
            provider.errorMessage ?? 'Unable to log this activity.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<FoodActivityProvider, bool>(
      (provider) => provider.isSubmitting,
    );

    final units = <String>{..._defaultUnits, _selectedUnit}.toList();

    return AlertDialog(
      title: const Text('Log Food Activity'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<ActivityType>(
                  segments: const [
                    ButtonSegment(
                      value: ActivityType.consumed,
                      label: Text('Consumed'),
                      icon: Icon(Icons.restaurant_outlined),
                    ),
                    ButtonSegment(
                      value: ActivityType.wasted,
                      label: Text('Wasted'),
                      icon: Icon(Icons.delete_outline),
                    ),
                    ButtonSegment(
                      value: ActivityType.expired,
                      label: Text('Expired'),
                      icon: Icon(Icons.warning_amber_outlined),
                    ),
                    ButtonSegment(
                      value: ActivityType.donated,
                      label: Text('Donated'),
                      icon: Icon(Icons.volunteer_activism_outlined),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: isSubmitting
                      ? null
                      : (selection) {
                          setState(() => _selectedType = selection.first);
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Food item name',
                    hintText: 'Example: Milk',
                    prefixIcon: Icon(Icons.fastfood_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Please enter a food item name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        enabled: !isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) {
                            return 'Required';
                          }

                          final parsed = double.tryParse(text);

                          if (parsed == null || parsed <= 0) {
                            return 'Enter a number > 0';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: units
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _selectedUnit = value);
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  enabled: !isSubmitting,
                  maxLines: 2,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_localErrorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _localErrorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Log Activity'),
        ),
      ],
    );
  }
}
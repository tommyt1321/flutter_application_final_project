import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shopping_item.dart';
import '../../providers/shopping_item_provider.dart';

class ShoppingItemFormDialog extends StatefulWidget {
  const ShoppingItemFormDialog({super.key, this.item});

  final ShoppingItem? item;

  bool get isEditing => item != null;

  @override
  State<ShoppingItemFormDialog> createState() => _ShoppingItemFormDialogState();
}

class _ShoppingItemFormDialogState extends State<ShoppingItemFormDialog> {
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

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;

  late String _selectedUnit;
  String? _localErrorMessage;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');

    _quantityController = TextEditingController(
      text: item == null ? '1' : _formatQuantity(item.quantity),
    );

    _selectedUnit = item?.unit ?? _defaultUnits.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<ShoppingItemProvider, bool>(
      (provider) => provider.isSubmitting,
    );

    final units = <String>{..._defaultUnits, _selectedUnit}.toList();

    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Edit Shopping Item' : 'Add Shopping Item',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  autofocus: !widget.isEditing,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'Example: Eggs',
                    prefixIcon: Icon(Icons.shopping_basket_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Please enter an item name.';
                    }

                    if (name.length > 50) {
                      return 'Item name cannot exceed '
                          '50 characters.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
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
                          prefixIcon: Icon(Icons.numbers_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final quantity = double.tryParse(value?.trim() ?? '');

                          if (quantity == null) {
                            return 'Enter a number.';
                          }

                          if (quantity <= 0) {
                            return 'Must be above 0.';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          prefixIcon: Icon(Icons.straighten_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: units.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedUnit = value;
                                });
                              },
                      ),
                    ),
                  ],
                ),
                if (_localErrorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _localErrorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
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
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: isSubmitting ? null : _saveItem,
          icon: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  widget.isEditing ? Icons.save_outlined : Icons.add_rounded,
                ),
          label: Text(
            isSubmitting
                ? 'Saving...'
                : widget.isEditing
                ? 'Save'
                : 'Add',
          ),
        ),
      ],
    );
  }

  Future<void> _saveItem() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());

    if (quantity == null) {
      return;
    }

    setState(() {
      _localErrorMessage = null;
    });

    final provider = context.read<ShoppingItemProvider>();

    final existingItem = widget.item;

    final success = existingItem == null
        ? await provider.addItem(
            name: _nameController.text,
            quantity: quantity,
            unit: _selectedUnit,
          )
        : await provider.updateItem(
            item: existingItem,
            name: _nameController.text,
            quantity: quantity,
            unit: _selectedUnit,
          );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _localErrorMessage =
          provider.errorMessage ?? 'Unable to save the shopping item.';
    });
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

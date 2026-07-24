import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../providers/storage_location_provider.dart';

class FoodItemFormScreen extends StatefulWidget {
  const FoodItemFormScreen({super.key, this.item});

  final FoodItem? item;

  bool get isEditing => item != null;

  @override
  State<FoodItemFormScreen> createState() => _FoodItemFormScreenState();
}

class _FoodItemFormScreenState extends State<FoodItemFormScreen> {
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

  late final TextEditingController _notesController;

  late String _selectedUnit;

  String? _selectedCategoryId;
  String? _selectedStorageLocationId;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');

    _quantityController = TextEditingController(
      text: item == null ? '1' : _formatQuantity(item.quantity),
    );

    _notesController = TextEditingController(text: item?.notes ?? '');

    _selectedUnit = item?.unit ?? _defaultUnits.first;

    _selectedCategoryId = item?.categoryId;

    _selectedStorageLocationId = item?.storageLocationId;

    _expiryDate = item?.expiryDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final categoryProvider = Provider.of<CategoryProvider>(context);

    final storageLocationProvider = Provider.of<StorageLocationProvider>(
      context,
    );

    final categories = categoryProvider.categories;

    final locations = storageLocationProvider.locations;

    final categoryStillExists = categories.any(
      (category) => category.id == _selectedCategoryId,
    );

    if (!categoryStillExists) {
      _selectedCategoryId = categories.isEmpty ? null : categories.first.id;
    }

    final locationStillExists = locations.any(
      (location) => location.id == _selectedStorageLocationId,
    );

    if (!locationStillExists) {
      _selectedStorageLocationId = locations.isEmpty
          ? null
          : locations.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    final storageLocationProvider = context.watch<StorageLocationProvider>();

    final isSubmitting = context.select<FoodItemProvider, bool>(
      (provider) => provider.isSubmitting,
    );

    final categories = categoryProvider.categories;

    final locations = storageLocationProvider.locations;

    final units = <String>{..._defaultUnits, _selectedUnit}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Food Item' : 'Add Food Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Food name',
                    hintText: 'Example: Fresh Milk',
                    prefixIcon: Icon(Icons.fastfood_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Please enter the food name.';
                    }

                    if (name.length > 50) {
                      return 'Food name cannot exceed '
                          '50 characters.';
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
                        key: ValueKey('unit-$_selectedUnit'),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'category-'
                    '$_selectedCategoryId-'
                    '${categories.length}',
                  ),
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'location-'
                    '$_selectedStorageLocationId-'
                    '${locations.length}',
                  ),
                  initialValue: _selectedStorageLocationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Storage location',
                    prefixIcon: Icon(Icons.kitchen_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location.id,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedStorageLocationId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a storage '
                          'location.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Expiry date'),
                    subtitle: Text(
                      _expiryDate == null
                          ? 'No expiry date selected'
                          : DateFormat('dd MMMM yyyy').format(_expiryDate!),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_expiryDate != null)
                          IconButton(
                            tooltip: 'Remove expiry date',
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _expiryDate = null;
                                    });
                                  },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                        IconButton(
                          tooltip: 'Select expiry date',
                          onPressed: isSubmitting ? null : _selectExpiryDate,
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ],
                    ),
                    onTap: isSubmitting ? null : _selectExpiryDate,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  enabled: !isSubmitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText:
                        'Optional information about '
                        'this food item',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value?.trim().length ?? 0) > 200) {
                      return 'Notes cannot exceed '
                          '200 characters.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isSubmitting ? null : _saveItem,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.isEditing
                              ? Icons.save_outlined
                              : Icons.add_rounded,
                        ),
                  label: Text(
                    isSubmitting
                        ? 'Saving...'
                        : widget.isEditing
                        ? 'Save Changes'
                        : 'Add to Inventory',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final today = DateTime.now();

    final firstDate = DateTime(today.year - 5, 1, 1);

    final lastDate = DateTime(today.year + 20, 12, 31);

    var initialDate = _expiryDate ?? today;

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select expiry date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _expiryDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  Future<void> _saveItem() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final categoryId = _selectedCategoryId;

    final storageLocationId = _selectedStorageLocationId;

    if (categoryId == null || storageLocationId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a category and '
              'storage location.',
            ),
          ),
        );

      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());

    if (quantity == null) {
      return;
    }

    final provider = context.read<FoodItemProvider>();

    final existingItem = widget.item;

    final success = existingItem == null
        ? await provider.addItem(
            name: _nameController.text,
            quantity: quantity,
            unit: _selectedUnit,
            categoryId: categoryId,
            storageLocationId: storageLocationId,
            expiryDate: _expiryDate,
            notes: _notesController.text,
          )
        : await provider.updateItem(
            item: existingItem,
            name: _nameController.text,
            quantity: quantity,
            unit: _selectedUnit,
            categoryId: categoryId,
            storageLocationId: storageLocationId,
            expiryDate: _expiryDate,
            removeExpiryDate: _expiryDate == null,
            notes: _notesController.text,
          );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to save the food item.',
          ),
        ),
      );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toString();
  }
}

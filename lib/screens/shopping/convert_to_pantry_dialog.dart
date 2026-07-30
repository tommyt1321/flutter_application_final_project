import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_activity.dart';
import '../../models/shopping_item.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/food_activity_provider.dart';
import '../../providers/food_item_provider.dart';
import '../../providers/shopping_item_provider.dart';
import '../../providers/storage_location_provider.dart';

/// Converts a purchased ShoppingItem into a pantry FoodItem. Asks for the
/// two required FoodItem fields that ShoppingItem doesn't carry
/// (category, storage location) plus an optional expiry date, then:
///  1. creates the FoodItem via FoodItemProvider.addItem(...)
///  2. logs a FoodActivity(added) entry via FoodActivityProvider
///  3. marks the ShoppingItem converted via ShoppingItemProvider
///  4. refreshes AnalyticsProvider so the dashboard reflects the change
class ConvertToPantryDialog extends StatefulWidget {
  const ConvertToPantryDialog({required this.item, super.key});

  final ShoppingItem item;

  @override
  State<ConvertToPantryDialog> createState() => _ConvertToPantryDialogState();
}

class _ConvertToPantryDialogState extends State<ConvertToPantryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedCategoryId;
  String? _selectedStorageLocationId;
  DateTime? _expiryDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedStorageLocationId == null) {
      setState(() {
        _errorMessage = 'Please select a category and storage location.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final foodItemProvider = context.read<FoodItemProvider>();
    final foodActivityProvider = context.read<FoodActivityProvider>();
    final shoppingItemProvider = context.read<ShoppingItemProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    // Generated up front so the FoodActivity entry and the ShoppingItem's
    // convertedFoodItemId both reference the exact same FoodItem id.
    final foodItemId =
        'food_item_${DateTime.now().microsecondsSinceEpoch}_conv';

    final createdFoodItem = await foodItemProvider.addItem(
      id: foodItemId,
      name: widget.item.name,
      quantity: widget.item.quantity,
      unit: widget.item.unit,
      categoryId: _selectedCategoryId!,
      storageLocationId: _selectedStorageLocationId!,
      expiryDate: _expiryDate,
    );

    if (!createdFoodItem) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            foodItemProvider.errorMessage ?? 'Unable to create the pantry item.';
      });
      return;
    }

    await foodActivityProvider.logActivity(
      foodItemId: foodItemId,
      foodItemName: widget.item.name,
      activityType: ActivityType.added,
      quantity: widget.item.quantity,
      unit: widget.item.unit,
      notes: 'Added from shopping list',
    );

    final marked = await shoppingItemProvider.markConverted(
      widget.item.id,
      foodItemId: foodItemId,
    );

    // Recompute analytics so the dashboard reflects this addition right
    // away rather than waiting for the next natural refresh.
    unawaited(analyticsProvider.refresh());

    if (!mounted) return;

    if (marked) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = shoppingItemProvider.errorMessage ??
            'Pantry item created, but the shopping item could not be updated.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final storageLocations = context.watch<StorageLocationProvider>().locations;

    return AlertDialog(
      title: const Text('Add to Pantry'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.item.name} · ${_formatQuantity(widget.item.quantity)} '
                  '${widget.item.unit}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedCategoryId = value),
                  validator: (value) =>
                      value == null ? 'Please select a category.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStorageLocationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Storage location',
                    prefixIcon: Icon(Icons.kitchen_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: storageLocations
                      .map(
                        (location) => DropdownMenuItem(
                          value: location.id,
                          child: Text(location.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) =>
                            setState(() => _selectedStorageLocationId = value),
                  validator: (value) => value == null
                      ? 'Please select a storage location.'
                      : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isSubmitting ? null : _pickExpiryDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry date (optional)',
                      prefixIcon: Icon(Icons.event_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _expiryDate == null
                          ? 'No expiry date set'
                          : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
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
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add to Pantry'),
        ),
      ],
    );
  }

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

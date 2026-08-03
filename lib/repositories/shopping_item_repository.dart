import 'package:hive_ce/hive_ce.dart';

import '../models/shopping_item.dart';

class ShoppingItemRepository {
  ShoppingItemRepository(this._box);

  final Box<ShoppingItem> _box;

  List<ShoppingItem> getItemsForUser(String userId) {
    final items = _box.values.where((item) {
      return item.ownerUserId == userId;
    }).toList();

    items.sort((first, second) {
      // Unpurchased items appear first.
      if (first.isCompleted != second.isCompleted) {
        return first.isCompleted ? 1 : -1;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return List<ShoppingItem>.unmodifiable(items);
  }

  ShoppingItem? getItemById({required String id, required String userId}) {
    final item = _box.get(id);

    if (item == null) {
      return null;
    }

    if (item.ownerUserId != userId) {
      return null;
    }

    return item;
  }

  Future<void> addItem(ShoppingItem item, {required String userId}) async {
    final trimmedName = item.name.trim();
    final trimmedUnit = item.unit.trim();

    _validateItem(
      name: trimmedName,
      quantity: item.quantity,
      unit: trimmedUnit,
    );

    if (_itemNameExists(trimmedName, userId: userId)) {
      throw StateError('This item is already in your shopping list.');
    }

    final now = DateTime.now();

    final savedItem = item.copyWith(
      ownerUserId: userId,
      name: trimmedName,
      unit: trimmedUnit,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await _box.put(savedItem.id, savedItem);
  }

  Future<void> updateItem(ShoppingItem item, {required String userId}) async {
    final existingItem = _box.get(item.id);

    if (existingItem == null) {
      throw StateError('The selected shopping item does not exist.');
    }

    if (existingItem.ownerUserId != userId) {
      throw StateError(
        'You do not have permission to edit this shopping item.',
      );
    }

    final trimmedName = item.name.trim();
    final trimmedUnit = item.unit.trim();

    _validateItem(
      name: trimmedName,
      quantity: item.quantity,
      unit: trimmedUnit,
    );

    if (_itemNameExists(trimmedName, userId: userId, excludingId: item.id)) {
      throw StateError('This item is already in your shopping list.');
    }

    final updatedItem = item.copyWith(
      ownerUserId: userId,
      name: trimmedName,
      unit: trimmedUnit,
      createdAt: existingItem.createdAt,
      updatedAt: DateTime.now(),
    );

    await _box.put(updatedItem.id, updatedItem);
  }

  Future<void> toggleCompleted(String itemId, {required String userId}) async {
    final existingItem = _box.get(itemId);

    if (existingItem == null) {
      throw StateError('The selected shopping item does not exist.');
    }

    if (existingItem.ownerUserId != userId) {
      throw StateError(
        'You do not have permission to update this shopping item.',
      );
    }

    final updatedItem = existingItem.copyWith(
      isCompleted: !existingItem.isCompleted,
      updatedAt: DateTime.now(),
    );

    await _box.put(itemId, updatedItem);
  }

  /// Marks a purchased item as converted into a pantry FoodItem, storing
  /// the resulting FoodItem's id for reference. Called after a successful
  /// FoodItemProvider.addItem(...) call during the conversion flow.
  Future<void> markConverted(
    String itemId, {
    required String userId,
    required String foodItemId,
  }) async {
    final existingItem = _box.get(itemId);

    if (existingItem == null) {
      throw StateError('The selected shopping item does not exist.');
    }

    if (existingItem.ownerUserId != userId) {
      throw StateError(
        'You do not have permission to update this shopping item.',
      );
    }

    if (existingItem.isConverted) {
      throw StateError('This item has already been added to your pantry.');
    }

    final updatedItem = existingItem.copyWith(
      isCompleted: true,
      isConverted: true,
      convertedFoodItemId: foodItemId,
      updatedAt: DateTime.now(),
    );

    await _box.put(itemId, updatedItem);
  }

  Future<void> deleteItem(String itemId, {required String userId}) async {
    final item = _box.get(itemId);

    if (item == null) {
      throw StateError('The selected shopping item does not exist.');
    }

    if (item.ownerUserId != userId) {
      throw StateError(
        'You do not have permission to delete this shopping item.',
      );
    }

    await _box.delete(itemId);
  }

  Future<void> clearCompletedItems(String userId) async {
    final keysToDelete = <dynamic>[];

    for (final key in _box.keys) {
      final item = _box.get(key);

      if (item != null && item.ownerUserId == userId && item.isCompleted) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _box.deleteAll(keysToDelete);
    }
  }

  void _validateItem({
    required String name,
    required double quantity,
    required String unit,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Shopping item name cannot be empty.');
    }

    if (name.length > 50) {
      throw ArgumentError('Shopping item name cannot exceed 50 characters.');
    }

    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    if (unit.isEmpty) {
      throw ArgumentError('Please select or enter a unit.');
    }
  }

  bool _itemNameExists(
    String name, {
    required String userId,
    String? excludingId,
  }) {
    final normalizedName = name.trim().toLowerCase();

    return _box.values.any((item) {
      return item.ownerUserId == userId &&
          item.id != excludingId &&
          item.name.trim().toLowerCase() == normalizedName;
    });
  }
}
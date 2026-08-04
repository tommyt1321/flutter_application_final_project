import 'package:hive_ce/hive_ce.dart';

import '../models/food_item.dart';

class FoodItemRepository {
  FoodItemRepository(this._box);

  final Box<FoodItem> _box;

  List<FoodItem> getItemsForUser(String userId) {
    final items = _box.values
        .where((item) => item.ownerUserId == userId)
        .toList();

    items.sort(_compareItems);

    return List<FoodItem>.unmodifiable(items);
  }

  FoodItem? getItemById({required String id, required String userId}) {
    final item = _box.get(id);

    if (item == null || item.ownerUserId != userId) {
      return null;
    }

    return item;
  }

  Future<void> migrateLegacyItems(String userId) async {
    final items = _box.values.toList(growable: false);

    for (final item in items) {
      var updatedItem = item;

      if (updatedItem.ownerUserId.isEmpty) {
        updatedItem = updatedItem.copyWith(ownerUserId: userId);
      }

      final legacyStatus = _extractStatusFromNotes(updatedItem.notes);
      if (updatedItem.status == null && legacyStatus != null) {
        updatedItem = updatedItem.copyWith(
          status: legacyStatus,
          notes: _stripStatusMarkers(updatedItem.notes),
        );
      }

      if (updatedItem != item) {
        await _box.put(updatedItem.id, updatedItem);
      }
    }
  }

  Future<void> addItem(FoodItem item, {required String userId}) async {
    _validateItem(item);

    if (_box.containsKey(item.id)) {
      throw StateError('A food item with this ID already exists.');
    }

    final now = DateTime.now();
    final status = _normalizeStatus(item.status) ?? 'available';
    final normalizedNotes = _normalizeNotes(item.notes);

    final savedItem = item.copyWith(
      ownerUserId: userId,
      name: item.name.trim(),
      unit: item.unit.trim(),
      notes: normalizedNotes,
      clearNotes: normalizedNotes == null,
      status: status,
      clearStatus: false,
      createdAt: now,
      updatedAt: now,
    );

    await _box.put(savedItem.id, savedItem);
  }

  Future<void> updateItem(FoodItem item, {required String userId}) async {
    final existingItem = _box.get(item.id);

    if (existingItem == null) {
      throw StateError('The selected food item does not exist.');
    }

    if (existingItem.ownerUserId != userId) {
      throw StateError('You do not have permission to edit this food item.');
    }

    _validateItem(item);

    final normalizedNotes = _normalizeNotes(item.notes);
    final normalizedStatus = _normalizeStatus(item.status) ?? item.status ?? 'available';

    final updatedItem = item.copyWith(
      ownerUserId: userId,
      name: item.name.trim(),
      unit: item.unit.trim(),
      notes: normalizedNotes,
      clearNotes: normalizedNotes == null,
      status: normalizedStatus,
      clearStatus: false,
      createdAt: existingItem.createdAt,
      updatedAt: DateTime.now(),
    );

    await _box.put(updatedItem.id, updatedItem);
  }

  Future<void> deleteItem(String itemId, {required String userId}) async {
    final item = _box.get(itemId);

    if (item == null) {
      throw StateError('The selected food item does not exist.');
    }

    if (item.ownerUserId != userId) {
      throw StateError('You do not have permission to delete this food item.');
    }

    await _box.delete(itemId);
  }

  void _validateItem(FoodItem item) {
    final trimmedName = item.name.trim();
    final trimmedUnit = item.unit.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Food name cannot be empty.');
    }

    if (trimmedName.length > 50) {
      throw ArgumentError('Food name cannot exceed 50 characters.');
    }

    final status = item.statusEnum;
    if (item.quantity <= 0) {
      if (status == FoodItemStatus.available) {
        throw ArgumentError('Quantity must be greater than zero.');
      }
    }

    if (trimmedUnit.isEmpty) {
      throw ArgumentError('Please select or enter a unit.');
    }

    if (item.categoryId.trim().isEmpty) {
      throw ArgumentError('Please select a category.');
    }

    if (item.storageLocationId.trim().isEmpty) {
      throw ArgumentError('Please select a storage location.');
    }

    final notes = item.notes?.trim();

    if (notes != null && notes.length > 200) {
      throw ArgumentError('Notes cannot exceed 200 characters.');
    }
  }

  String? _normalizeNotes(String? notes) {
    final trimmedNotes = notes?.trim();

    if (trimmedNotes == null || trimmedNotes.isEmpty) {
      return null;
    }

    return trimmedNotes;
  }

  String? _normalizeStatus(String? status) {
    final normalized = status?.trim().toLowerCase();

    switch (normalized) {
      case 'available':
      case 'consumed':
      case 'donated':
      case 'discarded':
        return normalized;
      default:
        return null;
    }
  }

  String? _extractStatusFromNotes(String? notes) {
    if (notes == null) {
      return null;
    }

    final regex = RegExp(r'\[STATUS:(consumed|donated|discarded)\]', caseSensitive: false);
    final match = regex.firstMatch(notes);

    if (match == null) {
      return null;
    }

    return match.group(1)?.toLowerCase();
  }

  String? _stripStatusMarkers(String? notes) {
    if (notes == null) {
      return null;
    }

    final stripped = notes.replaceAll(RegExp(r'\[STATUS:(consumed|donated|discarded)\]', caseSensitive: false), '').trim();

    return stripped.isEmpty ? null : stripped;
  }

  int _compareItems(FoodItem first, FoodItem second) {
    final firstExpiry = first.expiryDate;
    final secondExpiry = second.expiryDate;

    if (firstExpiry == null && secondExpiry != null) {
      return 1;
    }

    if (firstExpiry != null && secondExpiry == null) {
      return -1;
    }

    if (firstExpiry != null && secondExpiry != null) {
      final expiryComparison = firstExpiry.compareTo(secondExpiry);

      if (expiryComparison != 0) {
        return expiryComparison;
      }
    }

    return first.name.toLowerCase().compareTo(second.name.toLowerCase());
  }
}

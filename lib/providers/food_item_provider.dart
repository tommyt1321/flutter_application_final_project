import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../repositories/food_item_repository.dart';

class FoodItemProvider extends ChangeNotifier {
  FoodItemProvider(this._repository);

  final FoodItemRepository _repository;

  String? _userId;
  List<FoodItem> _items = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<FoodItem> get items => List<FoodItem>.unmodifiable(_items);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasItems => _items.isNotEmpty;

  int get itemCount => _items.length;

  List<FoodItem> get expiredItems {
    final today = _dateOnly(DateTime.now());

    return List<FoodItem>.unmodifiable(
      _items.where((item) {
        final expiryDate = item.expiryDate;

        if (expiryDate == null) {
          return false;
        }

        return _dateOnly(expiryDate).isBefore(today);
      }),
    );
  }

  List<FoodItem> get expiringSoonItems {
    final today = _dateOnly(DateTime.now());

    final finalDate = today.add(const Duration(days: 7));

    return List<FoodItem>.unmodifiable(
      _items.where((item) {
        final expiryDate = item.expiryDate;

        if (expiryDate == null) {
          return false;
        }

        final date = _dateOnly(expiryDate);

        return !date.isBefore(today) && !date.isAfter(finalDate);
      }),
    );
  }

  void updateUserId(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;

    if (userId == null) {
      _items = [];
      _isLoading = false;
      _isSubmitting = false;
      _errorMessage = null;

      scheduleMicrotask(notifyListeners);
      return;
    }

    scheduleMicrotask(() {
      unawaited(initialize());
    });
  }

  Future<void> initialize() async {
    final userId = _userId;

    if (userId == null) {
      _items = [];
      _isLoading = false;
      _errorMessage = 'Please sign in to view your food inventory.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loadItems(userId);
    } catch (error) {
      if (_userId == userId) {
        _errorMessage = _getReadableError(error);
      }
    } finally {
      if (_userId == userId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void reloadItems() {
    final userId = _userId;

    if (userId == null) {
      return;
    }

    try {
      _errorMessage = null;
      _loadItems(userId);
      notifyListeners();
    } catch (error) {
      _errorMessage = _getReadableError(error);
      notifyListeners();
    }
  }

  FoodItem? getItemById(String id) {
    final userId = _userId;

    if (userId == null) {
      return null;
    }

    return _repository.getItemById(id: id, userId: userId);
  }

  Future<bool> addItem({
    required String name,
    required double quantity,
    required String unit,
    required String categoryId,
    required String storageLocationId,
    DateTime? expiryDate,
    String? notes,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before adding a food item.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final now = DateTime.now();

      final item = FoodItem(
        id:
            'food_item_'
            '${DateTime.now().microsecondsSinceEpoch}',
        ownerUserId: userId,
        name: name,
        quantity: quantity,
        unit: unit,
        categoryId: categoryId,
        storageLocationId: storageLocationId,
        expiryDate: expiryDate,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addItem(item, userId: userId);

      if (_userId == userId) {
        _loadItems(userId);
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint('Food item add error: ${error.runtimeType} - $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> updateItem({
    required FoodItem item,
    required String name,
    required double quantity,
    required String unit,
    required String categoryId,
    required String storageLocationId,
    DateTime? expiryDate,
    required bool removeExpiryDate,
    String? notes,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before editing a food item.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final updatedItem = item.copyWith(
        name: name,
        quantity: quantity,
        unit: unit,
        categoryId: categoryId,
        storageLocationId: storageLocationId,
        expiryDate: expiryDate,
        clearExpiryDate: removeExpiryDate,
        notes: notes,
        clearNotes: notes == null || notes.trim().isEmpty,
      );

      await _repository.updateItem(updatedItem, userId: userId);

      if (_userId == userId) {
        _loadItems(userId);
      }

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> deleteItem(String itemId) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before deleting a food item.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      await _repository.deleteItem(itemId, userId: userId);

      if (_userId == userId) {
        _loadItems(userId);
      }

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  List<FoodItem> getItemsByCategory(String categoryId) {
    return List<FoodItem>.unmodifiable(
      _items.where((item) => item.categoryId == categoryId),
    );
  }

  List<FoodItem> getItemsByLocation(String storageLocationId) {
    return List<FoodItem>.unmodifiable(
      _items.where((item) => item.storageLocationId == storageLocationId),
    );
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _loadItems(String userId) {
    _items = _repository.getItemsForUser(userId);
  }

  void _startSubmitting() {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishSubmitting() {
    _isSubmitting = false;
    notifyListeners();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _getReadableError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ??
          'The food item information is invalid.';
    }

    if (error is StateError) {
      return error.message;
    }

    debugPrint(
      'Unhandled food inventory error: '
      '${error.runtimeType} - $error',
    );

    return 'Unable to save the food item. '
        'Check the terminal for the exact error.';
  }
}

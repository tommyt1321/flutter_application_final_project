import 'dart:async';

import 'package:flutter/material.dart';

import '../models/shopping_item.dart';
import '../repositories/shopping_item_repository.dart';

class ShoppingItemProvider extends ChangeNotifier {
  ShoppingItemProvider(this._repository);

  final ShoppingItemRepository _repository;

  String? _userId;
  List<ShoppingItem> _items = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<ShoppingItem> get items => List<ShoppingItem>.unmodifiable(_items);

  List<ShoppingItem> get pendingItems => List<ShoppingItem>.unmodifiable(
    _items.where((item) => !item.isCompleted),
  );

  List<ShoppingItem> get completedItems =>
      List<ShoppingItem>.unmodifiable(_items.where((item) => item.isCompleted));

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasItems => _items.isNotEmpty;

  int get itemCount => _items.length;

  int get pendingCount => pendingItems.length;

  int get completedCount => completedItems.length;

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
      _errorMessage = 'Please sign in to view your shopping list.';
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

  Future<bool> addItem({
    required String name,
    required double quantity,
    required String unit,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before adding a shopping item.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final now = DateTime.now();

      final item = ShoppingItem(
        id:
            'shopping_item_'
            '${DateTime.now().microsecondsSinceEpoch}',
        ownerUserId: userId,
        name: name,
        quantity: quantity,
        unit: unit,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addItem(item, userId: userId);

      if (_userId == userId) {
        _loadItems(userId);
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Shopping item add error: '
        '${error.runtimeType} - $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> updateItem({
    required ShoppingItem item,
    required String name,
    required double quantity,
    required String unit,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before editing a shopping item.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final updatedItem = item.copyWith(
        name: name,
        quantity: quantity,
        unit: unit,
      );

      await _repository.updateItem(updatedItem, userId: userId);

      if (_userId == userId) {
        _loadItems(userId);
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Shopping item update error: '
        '${error.runtimeType} - $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> toggleCompleted(String itemId) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before updating a shopping item.';
      notifyListeners();
      return false;
    }

    try {
      _errorMessage = null;

      await _repository.toggleCompleted(itemId, userId: userId);

      if (_userId == userId) {
        _loadItems(userId);
      }

      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before deleting a shopping item.';
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

  Future<bool> clearCompletedItems() async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before clearing completed items.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      await _repository.clearCompletedItems(userId);

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

  String _getReadableError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ??
          'The shopping item information is invalid.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Unable to complete the shopping-list operation.';
  }
}

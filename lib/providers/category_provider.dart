import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food_category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._repository);

  final CategoryRepository _repository;

  String? _userId;
  List<FoodCategory> _categories = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<FoodCategory> get categories =>
      List<FoodCategory>.unmodifiable(_categories);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasCategories => _categories.isNotEmpty;

  int get categoryCount => _categories.length;

  void updateUserId(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;

    if (userId == null) {
      _categories = [];
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
      _categories = [];
      _isLoading = false;
      _errorMessage = 'Please sign in to view categories.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.seedDefaultCategories();

      await _repository.migrateLegacyCustomCategories(userId);

      if (_userId != userId) {
        return;
      }

      _loadCategories(userId);
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

  void reloadCategories() {
    final userId = _userId;

    if (userId == null) {
      return;
    }

    try {
      _errorMessage = null;
      _loadCategories(userId);
      notifyListeners();
    } catch (error) {
      _errorMessage = _getReadableError(error);
      notifyListeners();
    }
  }

  FoodCategory? getCategoryById(String id) {
    final userId = _userId;

    if (userId == null) {
      return null;
    }

    return _repository.getCategoryById(id: id, userId: userId);
  }

  Future<bool> addCategory({
    required String name,
    required String iconKey,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before adding a category.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final category = FoodCategory(
        id:
            'custom_category_'
            '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        iconKey: iconKey,
        isDefault: false,
        createdAt: DateTime.now(),
        ownerUserId: userId,
      );

      await _repository.addCategory(category, userId: userId);

      if (_userId == userId) {
        _loadCategories(userId);
      }

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> updateCategory({
    required FoodCategory category,
    required String name,
    required String iconKey,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before editing a category.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final updatedCategory = category.copyWith(name: name, iconKey: iconKey);

      await _repository.updateCategory(updatedCategory, userId: userId);

      if (_userId == userId) {
        _loadCategories(userId);
      }

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before deleting a category.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      await _repository.deleteCategory(categoryId, userId: userId);

      if (_userId == userId) {
        _loadCategories(userId);
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

  void _loadCategories(String userId) {
    _categories = _repository.getCategoriesForUser(userId);
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
          'The category information is invalid.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Unable to complete the category operation.';
  }
}

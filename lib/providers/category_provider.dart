import 'package:flutter/material.dart';

import '../models/food_category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._repository);

  final CategoryRepository _repository;

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

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.seedDefaultCategories();
      _loadCategories();
    } catch (error) {
      _errorMessage = _getReadableError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reloadCategories() {
    try {
      _errorMessage = null;
      _loadCategories();
      notifyListeners();
    } catch (error) {
      _errorMessage = _getReadableError(error);
      notifyListeners();
    }
  }

  FoodCategory? getCategoryById(String id) {
    return _repository.getCategoryById(id);
  }

  Future<bool> addCategory({
    required String name,
    required String iconKey,
  }) async {
    _startSubmitting();

    try {
      final category = FoodCategory(
        id: 'custom_category_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        iconKey: iconKey,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await _repository.addCategory(category);

      _loadCategories();

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
    _startSubmitting();

    try {
      final updatedCategory = category.copyWith(name: name, iconKey: iconKey);

      await _repository.updateCategory(updatedCategory);

      _loadCategories();

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);

      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    _startSubmitting();

    try {
      await _repository.deleteCategory(categoryId);

      _loadCategories();

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

  void _loadCategories() {
    _categories = _repository.getAllCategories();
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

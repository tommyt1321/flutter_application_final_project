import 'package:hive_ce/hive_ce.dart';

import '../models/food_category.dart';

class CategoryRepository {
  CategoryRepository(this._box);

  final Box<FoodCategory> _box;

  List<FoodCategory> getCategoriesForUser(String userId) {
    final categories = _box.values.where((category) {
      return category.isDefault || category.ownerUserId == userId;
    }).toList();

    categories.sort((first, second) {
      if (first.isDefault != second.isDefault) {
        return first.isDefault ? -1 : 1;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return List<FoodCategory>.unmodifiable(categories);
  }

  FoodCategory? getCategoryById({required String id, required String userId}) {
    final category = _box.get(id);

    if (category == null) {
      return null;
    }

    if (category.isDefault || category.ownerUserId == userId) {
      return category;
    }

    return null;
  }

  Future<void> seedDefaultCategories() async {
    final now = DateTime.now();

    final defaultCategories = [
      FoodCategory(
        id: 'category_fruits',
        name: 'Fruits',
        iconKey: 'fruit',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_vegetables',
        name: 'Vegetables',
        iconKey: 'vegetable',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_meat',
        name: 'Meat',
        iconKey: 'meat',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_seafood',
        name: 'Seafood',
        iconKey: 'seafood',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_dairy',
        name: 'Dairy',
        iconKey: 'dairy',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_beverages',
        name: 'Beverages',
        iconKey: 'drink',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_snacks',
        name: 'Snacks',
        iconKey: 'snack',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_frozen',
        name: 'Frozen Food',
        iconKey: 'frozen',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_canned',
        name: 'Canned Food',
        iconKey: 'canned',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_dry',
        name: 'Dry Food',
        iconKey: 'dry',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_condiments',
        name: 'Condiments',
        iconKey: 'condiment',
        isDefault: true,
        createdAt: now,
      ),
      FoodCategory(
        id: 'category_other',
        name: 'Other',
        iconKey: 'other',
        isDefault: true,
        createdAt: now,
      ),
    ];

    for (final category in defaultCategories) {
      if (!_box.containsKey(category.id)) {
        await _box.put(category.id, category);
      }
    }
  }

  /// Assigns custom categories created before Firebase Authentication
  /// was added to the first currently signed-in user.
  Future<void> migrateLegacyCustomCategories(String userId) async {
    final categories = _box.values.toList(growable: false);

    for (final category in categories) {
      if (!category.isDefault && category.ownerUserId == null) {
        await _box.put(category.id, category.copyWith(ownerUserId: userId));
      }
    }
  }

  Future<void> addCategory(
    FoodCategory category, {
    required String userId,
  }) async {
    final trimmedName = category.name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    if (_categoryNameExists(trimmedName, userId: userId)) {
      throw StateError('A category with this name already exists.');
    }

    await _box.put(
      category.id,
      category.copyWith(
        name: trimmedName,
        isDefault: false,
        ownerUserId: userId,
      ),
    );
  }

  Future<void> updateCategory(
    FoodCategory category, {
    required String userId,
  }) async {
    final existingCategory = _box.get(category.id);

    if (existingCategory == null) {
      throw StateError('The selected category does not exist.');
    }

    if (existingCategory.isDefault) {
      throw StateError('Default categories cannot be edited.');
    }

    if (existingCategory.ownerUserId != userId) {
      throw StateError('You do not have permission to edit this category.');
    }

    final trimmedName = category.name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    if (_categoryNameExists(
      trimmedName,
      userId: userId,
      excludingId: category.id,
    )) {
      throw StateError('A category with this name already exists.');
    }

    await _box.put(
      category.id,
      category.copyWith(
        name: trimmedName,
        isDefault: false,
        ownerUserId: userId,
      ),
    );
  }

  Future<void> deleteCategory(
    String categoryId, {
    required String userId,
  }) async {
    final category = _box.get(categoryId);

    if (category == null) {
      throw StateError('The selected category does not exist.');
    }

    if (category.isDefault) {
      throw StateError('Default categories cannot be deleted.');
    }

    if (category.ownerUserId != userId) {
      throw StateError('You do not have permission to delete this category.');
    }

    await _box.delete(categoryId);
  }

  bool _categoryNameExists(
    String name, {
    required String userId,
    String? excludingId,
  }) {
    final normalizedName = name.trim().toLowerCase();

    return _box.values.any((category) {
      final isVisibleToUser =
          category.isDefault || category.ownerUserId == userId;

      return isVisibleToUser &&
          category.id != excludingId &&
          category.name.trim().toLowerCase() == normalizedName;
    });
  }
}

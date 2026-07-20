import 'dart:io';

import 'package:flutter_application_final_project/models/food_category.dart';
import 'package:flutter_application_final_project/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory temporaryDirectory;
  late Box<FoodCategory> categoryBox;
  late CategoryRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_category_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FoodCategoryAdapter());
    }

    categoryBox = await Hive.openBox<FoodCategory>('category_test_box');

    repository = CategoryRepository(categoryBox);
  });

  tearDown(() async {
    await categoryBox.close();
    await Hive.deleteBoxFromDisk('category_test_box');

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('seeds the default food categories', () async {
    await repository.seedDefaultCategories();

    final categories = repository.getAllCategories();

    expect(categories.length, 12);
    expect(categories.any((category) => category.name == 'Fruits'), isTrue);
  });

  test('adds a custom category', () async {
    final category = FoodCategory(
      id: 'custom_bakery',
      name: 'Bakery',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addCategory(category);

    expect(repository.getCategoryById('custom_bakery')?.name, 'Bakery');
  });

  test('rejects duplicate category names', () async {
    await repository.seedDefaultCategories();

    final duplicateCategory = FoodCategory(
      id: 'custom_fruits',
      name: 'fruits',
      iconKey: 'fruit',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    expect(() => repository.addCategory(duplicateCategory), throwsStateError);
  });

  test('updates a custom category', () async {
    final category = FoodCategory(
      id: 'custom_bakery',
      name: 'Bakery',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addCategory(category);

    await repository.updateCategory(
      category.copyWith(name: 'Bread and Bakery'),
    );

    expect(
      repository.getCategoryById('custom_bakery')?.name,
      'Bread and Bakery',
    );
  });

  test('prevents deletion of a default category', () async {
    await repository.seedDefaultCategories();

    expect(
      () => repository.deleteCategory('category_fruits'),
      throwsStateError,
    );
  });
}

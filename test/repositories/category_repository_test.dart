import 'dart:io';

import 'package:flutter_application_final_project/models/food_category.dart';
import 'package:flutter_application_final_project/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  const userOne = 'firebase_user_one';
  const userTwo = 'firebase_user_two';

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

  test('seeds shared default categories', () async {
    await repository.seedDefaultCategories();

    final categories = repository.getCategoriesForUser(userOne);

    expect(categories.length, 12);

    expect(categories.every((category) => category.isDefault), isTrue);
  });

  test('adds a custom category for one user', () async {
    final category = FoodCategory(
      id: 'custom_bakery',
      name: 'Bakery',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addCategory(category, userId: userOne);

    final savedCategory = repository.getCategoryById(
      id: category.id,
      userId: userOne,
    );

    expect(savedCategory?.name, 'Bakery');
    expect(savedCategory?.ownerUserId, userOne);
  });

  test('does not show another users custom category', () async {
    await repository.seedDefaultCategories();

    final category = FoodCategory(
      id: 'custom_bakery',
      name: 'Bakery',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addCategory(category, userId: userOne);

    final userOneCategories = repository.getCategoriesForUser(userOne);

    final userTwoCategories = repository.getCategoriesForUser(userTwo);

    expect(userOneCategories.any((item) => item.id == category.id), isTrue);

    expect(userTwoCategories.any((item) => item.id == category.id), isFalse);
  });

  test('allows different users to use the same custom name', () async {
    await repository.addCategory(
      FoodCategory(
        id: 'user_one_bakery',
        name: 'Bakery',
        iconKey: 'other',
        isDefault: false,
        createdAt: DateTime.now(),
      ),
      userId: userOne,
    );

    await repository.addCategory(
      FoodCategory(
        id: 'user_two_bakery',
        name: 'Bakery',
        iconKey: 'other',
        isDefault: false,
        createdAt: DateTime.now(),
      ),
      userId: userTwo,
    );

    expect(
      repository
          .getCategoriesForUser(userOne)
          .where((category) => category.name == 'Bakery')
          .length,
      1,
    );

    expect(
      repository
          .getCategoriesForUser(userTwo)
          .where((category) => category.name == 'Bakery')
          .length,
      1,
    );
  });

  test('prevents a user editing another users category', () async {
    final category = FoodCategory(
      id: 'custom_bakery',
      name: 'Bakery',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addCategory(category, userId: userOne);

    await expectLater(
      repository.updateCategory(
        category.copyWith(name: 'Bread'),
        userId: userTwo,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('migrates a legacy custom category', () async {
    final legacyCategory = FoodCategory(
      id: 'legacy_bakery',
      name: 'Legacy Bakery',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await categoryBox.put(legacyCategory.id, legacyCategory);

    await repository.migrateLegacyCustomCategories(userOne);

    expect(categoryBox.get(legacyCategory.id)?.ownerUserId, userOne);
  });

  test('prevents deletion of a default category', () async {
    await repository.seedDefaultCategories();

    await expectLater(
      repository.deleteCategory('category_fruits', userId: userOne),
      throwsA(isA<StateError>()),
    );
  });
}

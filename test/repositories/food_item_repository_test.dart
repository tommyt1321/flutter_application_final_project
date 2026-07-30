import 'dart:io';

import 'package:flutter_application_final_project/models/food_item.dart';
import 'package:flutter_application_final_project/repositories/food_item_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  const userOne = 'firebase_user_one';
  const userTwo = 'firebase_user_two';
  const boxName = 'food_item_test_box';

  late Directory temporaryDirectory;
  late Box<FoodItem> foodItemBox;
  late FoodItemRepository repository;

  FoodItem createItem({
    required String id,
    required String ownerUserId,
    String name = 'Milk',
    double quantity = 1,
    String unit = 'carton',
    DateTime? expiryDate,
  }) {
    final now = DateTime.now();

    return FoodItem(
      id: id,
      ownerUserId: ownerUserId,
      name: name,
      quantity: quantity,
      unit: unit,
      categoryId: 'category_dairy',
      storageLocationId: 'location_refrigerator',
      expiryDate: expiryDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_food_item_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FoodItemAdapter());
    }

    foodItemBox = await Hive.openBox<FoodItem>(boxName);

    repository = FoodItemRepository(foodItemBox);
  });

  tearDown(() async {
    if (foodItemBox.isOpen) {
      await foodItemBox.close();
    }

    await Hive.deleteBoxFromDisk(boxName);

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('adds a food item for the current user', () async {
    final item = createItem(id: 'milk_1', ownerUserId: userOne);

    await repository.addItem(item, userId: userOne);

    final savedItem = repository.getItemById(id: item.id, userId: userOne);

    expect(savedItem?.name, 'Milk');
    expect(savedItem?.ownerUserId, userOne);
    expect(savedItem?.quantity, 1);
  });

  test('does not show another users food items', () async {
    await repository.addItem(
      createItem(id: 'user_one_milk', ownerUserId: userOne),
      userId: userOne,
    );

    expect(repository.getItemsForUser(userOne).length, 1);

    expect(repository.getItemsForUser(userTwo), isEmpty);

    expect(
      repository.getItemById(id: 'user_one_milk', userId: userTwo),
      isNull,
    );
  });

  test('updates a food item belonging to the user', () async {
    final item = createItem(id: 'milk_1', ownerUserId: userOne);

    await repository.addItem(item, userId: userOne);

    await repository.updateItem(
      item.copyWith(name: 'Fresh Milk', quantity: 2),
      userId: userOne,
    );

    final updatedItem = repository.getItemById(id: item.id, userId: userOne);

    expect(updatedItem?.name, 'Fresh Milk');
    expect(updatedItem?.quantity, 2);
  });

  test('prevents another user editing the item', () async {
    final item = createItem(id: 'milk_1', ownerUserId: userOne);

    await repository.addItem(item, userId: userOne);

    await expectLater(
      repository.updateItem(
        item.copyWith(name: 'Changed Milk'),
        userId: userTwo,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('deletes a food item belonging to the user', () async {
    final item = createItem(id: 'milk_1', ownerUserId: userOne);

    await repository.addItem(item, userId: userOne);

    await repository.deleteItem(item.id, userId: userOne);

    expect(repository.getItemsForUser(userOne), isEmpty);
  });

  test('prevents another user deleting the item', () async {
    final item = createItem(id: 'milk_1', ownerUserId: userOne);

    await repository.addItem(item, userId: userOne);

    await expectLater(
      repository.deleteItem(item.id, userId: userTwo),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects a quantity of zero', () async {
    final item = createItem(
      id: 'invalid_milk',
      ownerUserId: userOne,
      quantity: 0,
    );

    await expectLater(
      repository.addItem(item, userId: userOne),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('migrates legacy food items to the signed-in user', () async {
    final legacyItem = createItem(
      id: 'legacy_item',
      ownerUserId: '',
      name: 'Legacy Milk',
    );

    await foodItemBox.put(legacyItem.id, legacyItem);

    await repository.migrateLegacyItems(userOne);

    final migratedItem = repository.getItemById(
      id: legacyItem.id,
      userId: userOne,
    );

    expect(migratedItem, isNotNull);
    expect(migratedItem?.ownerUserId, userOne);
    expect(repository.getItemsForUser(userTwo), isEmpty);
  });

  test('sorts items by the nearest expiry date', () async {
    final now = DateTime.now();

    await repository.addItem(
      createItem(
        id: 'later_item',
        ownerUserId: userOne,
        name: 'Later Item',
        expiryDate: now.add(const Duration(days: 10)),
      ),
      userId: userOne,
    );

    await repository.addItem(
      createItem(
        id: 'earlier_item',
        ownerUserId: userOne,
        name: 'Earlier Item',
        expiryDate: now.add(const Duration(days: 2)),
      ),
      userId: userOne,
    );

    final items = repository.getItemsForUser(userOne);

    expect(items.first.name, 'Earlier Item');
    expect(items.last.name, 'Later Item');
  });
}

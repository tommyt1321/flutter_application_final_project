import 'dart:io';

import 'package:flutter_application_final_project/models/food_item.dart';
import 'package:flutter_application_final_project/providers/food_item_provider.dart';
import 'package:flutter_application_final_project/repositories/food_item_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  const userId = 'firebase_user_one';
  const boxName = 'food_item_provider_test_box';

  late Directory temporaryDirectory;
  late Box<FoodItem> foodItemBox;
  late FoodItemRepository repository;
  late FoodItemProvider provider;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_provider_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FoodItemAdapter());
    }

    foodItemBox = await Hive.openBox<FoodItem>(boxName);
    repository = FoodItemRepository(foodItemBox);
    provider = FoodItemProvider(repository);
    provider.updateUserId(userId);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() async {
    provider.dispose();

    if (foodItemBox.isOpen) {
      await foodItemBox.close();
    }

    await Hive.deleteBoxFromDisk(boxName);

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('excludes consumed and discarded items from expiry calculations', () async {
    await provider.addItem(
      name: 'Milk',
      quantity: 1,
      unit: 'carton',
      categoryId: 'category_dairy',
      storageLocationId: 'location_fridge',
      expiryDate: DateTime.now().subtract(const Duration(days: 2)),
      notes: null,
    );

    final item = provider.items.first;

    await provider.updateItem(
      item: item.copyWith(status: FoodItemStatus.consumed.name),
      name: item.name,
      quantity: 0,
      unit: item.unit,
      categoryId: item.categoryId,
      storageLocationId: item.storageLocationId,
      expiryDate: item.expiryDate,
      removeExpiryDate: false,
      notes: item.notes,
    );

    expect(provider.expiredItems, isEmpty);
    expect(provider.expiringSoonItems, isEmpty);
  });
}

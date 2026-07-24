import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_final_project/models/food_category.dart';
import 'package:flutter_application_final_project/models/food_item.dart';
import 'package:flutter_application_final_project/models/storage_location.dart';
import 'package:flutter_application_final_project/providers/category_provider.dart';
import 'package:flutter_application_final_project/providers/food_item_provider.dart';
import 'package:flutter_application_final_project/providers/storage_location_provider.dart';
import 'package:flutter_application_final_project/repositories/category_repository.dart';
import 'package:flutter_application_final_project/repositories/food_item_repository.dart';
import 'package:flutter_application_final_project/repositories/storage_location_repository.dart';
import 'package:flutter_application_final_project/screens/categories/manage_categories_screen.dart';
import 'package:flutter_application_final_project/screens/storage/manage_storage_locations_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

void main() {
  const userId = 'deletion_protection_test_user';

  const categoryBoxName = 'deletion_protection_category_box';

  const locationBoxName = 'deletion_protection_location_box';

  const foodItemBoxName = 'deletion_protection_food_item_box';

  const customCategoryId = 'custom_category_breakfast';

  const customLocationId = 'custom_location_cabinet';

  late Directory temporaryDirectory;

  late Box<FoodCategory> categoryBox;
  late Box<StorageLocation> locationBox;
  late Box<FoodItem> foodItemBox;

  late CategoryProvider categoryProvider;
  late StorageLocationProvider locationProvider;
  late FoodItemProvider foodItemProvider;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_deletion_protection_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FoodCategoryAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StorageLocationAdapter());
    }

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FoodItemAdapter());
    }

    categoryBox = await Hive.openBox<FoodCategory>(categoryBoxName);

    locationBox = await Hive.openBox<StorageLocation>(locationBoxName);

    foodItemBox = await Hive.openBox<FoodItem>(foodItemBoxName);

    final now = DateTime.now();

    await categoryBox.put(
      customCategoryId,
      FoodCategory(
        id: customCategoryId,
        name: 'Breakfast',
        iconKey: 'other',
        isDefault: false,
        createdAt: now,
        ownerUserId: userId,
      ),
    );

    await locationBox.put(
      customLocationId,
      StorageLocation(
        id: customLocationId,
        name: 'Cabinet',
        iconKey: 'cabinet',
        isDefault: false,
        createdAt: now,
        ownerUserId: userId,
      ),
    );

    await foodItemBox.put(
      'food_item_cereal',
      FoodItem(
        id: 'food_item_cereal',
        ownerUserId: userId,
        name: 'Cereal',
        quantity: 1,
        unit: 'box',
        categoryId: customCategoryId,
        storageLocationId: customLocationId,
        createdAt: now,
        updatedAt: now,
      ),
    );

    categoryProvider = CategoryProvider(CategoryRepository(categoryBox));

    locationProvider = StorageLocationProvider(
      StorageLocationRepository(locationBox),
    );

    foodItemProvider = FoodItemProvider(FoodItemRepository(foodItemBox));

    categoryProvider.updateUserId(userId);
    locationProvider.updateUserId(userId);
    foodItemProvider.updateUserId(userId);

    await _waitForProviders(
      categoryProvider: categoryProvider,
      locationProvider: locationProvider,
      foodItemProvider: foodItemProvider,
    );
  });

  tearDown(() async {
    categoryProvider.dispose();
    locationProvider.dispose();
    foodItemProvider.dispose();

    if (categoryBox.isOpen) {
      await categoryBox.close();
    }

    if (locationBox.isOpen) {
      await locationBox.close();
    }

    if (foodItemBox.isOpen) {
      await foodItemBox.close();
    }

    await Hive.deleteBoxFromDisk(categoryBoxName);

    await Hive.deleteBoxFromDisk(locationBoxName);

    await Hive.deleteBoxFromDisk(foodItemBoxName);

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('blocks deletion of a category used by a food item', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoryProvider>.value(
            value: categoryProvider,
          ),
          ChangeNotifierProvider<FoodItemProvider>.value(
            value: foodItemProvider,
          ),
        ],
        child: const MaterialApp(home: ManageCategoriesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Breakfast'), 300);

    final categoryTile = find.ancestor(
      of: find.text('Breakfast'),
      matching: find.byType(ListTile),
    );

    final actionButton = find.descendant(
      of: categoryTile,
      matching: find.byTooltip('Category actions'),
    );

    await tester.tap(actionButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('1 food item uses "Breakfast"'), findsOneWidget);

    expect(categoryProvider.getCategoryById(customCategoryId), isNotNull);

    expect(categoryBox.containsKey(customCategoryId), isTrue);

    expect(find.text('Delete category?'), findsNothing);
  });

  testWidgets('blocks deletion of a location used by a food item', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageLocationProvider>.value(
            value: locationProvider,
          ),
          ChangeNotifierProvider<FoodItemProvider>.value(
            value: foodItemProvider,
          ),
        ],
        child: const MaterialApp(home: ManageStorageLocationsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Cabinet'), 300);

    final locationTile = find.ancestor(
      of: find.text('Cabinet'),
      matching: find.byType(ListTile),
    );

    final actionButton = find.descendant(
      of: locationTile,
      matching: find.byTooltip('Storage location actions'),
    );

    await tester.tap(actionButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('1 food item is stored in "Cabinet"'),
      findsOneWidget,
    );

    expect(locationProvider.getLocationById(customLocationId), isNotNull);

    expect(locationBox.containsKey(customLocationId), isTrue);

    expect(find.text('Delete storage location?'), findsNothing);
  });
}

Future<void> _waitForProviders({
  required CategoryProvider categoryProvider,
  required StorageLocationProvider locationProvider,
  required FoodItemProvider foodItemProvider,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));

  while (DateTime.now().isBefore(deadline)) {
    final categoryReady =
        !categoryProvider.isLoading &&
        categoryProvider.getCategoryById('custom_category_breakfast') != null;

    final locationReady =
        !locationProvider.isLoading &&
        locationProvider.getLocationById('custom_location_cabinet') != null;

    final foodItemsReady =
        !foodItemProvider.isLoading && foodItemProvider.hasItems;

    if (categoryReady && locationReady && foodItemsReady) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  throw StateError('The test providers did not initialize in time.');
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_final_project/models/food_item.dart';
import 'package:flutter_application_final_project/providers/food_item_provider.dart';
import 'package:flutter_application_final_project/repositories/food_item_repository.dart';
import 'package:flutter_application_final_project/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_application_final_project/widgets/dashboard_summary_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

void main() {
  const userId = 'dashboard_test_user';
  const boxName = 'dashboard_food_items_test_box';

  late Directory temporaryDirectory;
  late Box<FoodItem> foodItemBox;
  late FoodItemProvider foodItemProvider;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_dashboard_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FoodItemAdapter());
    }

    foodItemBox = await Hive.openBox<FoodItem>(boxName);

    foodItemProvider = FoodItemProvider(FoodItemRepository(foodItemBox));
  });

  tearDown(() async {
    foodItemProvider.dispose();

    if (foodItemBox.isOpen) {
      await foodItemBox.close();
    }

    await Hive.deleteBoxFromDisk(boxName);

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  Widget createTestApp({
    VoidCallback? onOpenInventory,
    VoidCallback? onOpenUseFirst,
    VoidCallback? onOpenNotifications,
  }) {
    return ChangeNotifierProvider<FoodItemProvider>.value(
      value: foodItemProvider,
      child: MaterialApp(
        home: DashboardScreen(
          onOpenInventory: onOpenInventory,
          onOpenUseFirst: onOpenUseFirst,
          onOpenNotifications: onOpenNotifications,
        ),
      ),
    );
  }

  FoodItem createFoodItem({
    required String id,
    required String name,
    required double quantity,
    DateTime? expiryDate,
  }) {
    final now = DateTime.now();

    return FoodItem(
      id: id,
      ownerUserId: userId,
      name: name,
      quantity: quantity,
      unit: 'item',
      categoryId: 'category_test',
      storageLocationId: 'location_test',
      expiryDate: expiryDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> loadFoodItems(List<FoodItem> items) async {
    await foodItemBox.putAll({for (final item in items) item.id: item});

    foodItemProvider.updateUserId(userId);

    // Allows the provider's scheduled initialization
    // to complete.
    await Future<void>.delayed(Duration.zero);
  }

  DashboardSummaryCard findSummaryCard(WidgetTester tester, String title) {
    final finder = find.byWidgetPredicate((widget) {
      return widget is DashboardSummaryCard && widget.title == title;
    });

    expect(finder, findsOneWidget);

    return tester.widget<DashboardSummaryCard>(finder);
  }

  testWidgets('shows the correct inventory summary counts', (tester) async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    await loadFoodItems([
      createFoodItem(
        id: 'expired_low_stock',
        name: 'Expired Bread',
        quantity: 1,
        expiryDate: today.subtract(const Duration(days: 1)),
      ),
      createFoodItem(
        id: 'expiring_soon',
        name: 'Fresh Milk',
        quantity: 5,
        expiryDate: today.add(const Duration(days: 3)),
      ),
      createFoodItem(id: 'low_stock', name: 'Eggs', quantity: 2),
      createFoodItem(
        id: 'normal_item',
        name: 'Rice',
        quantity: 5,
        expiryDate: today.add(const Duration(days: 30)),
      ),
    ]);

    await tester.pumpWidget(createTestApp());

    await tester.pumpAndSettle();

    expect(findSummaryCard(tester, 'Total Items').value, '4');

    expect(findSummaryCard(tester, 'Expiring Soon').value, '1');

    expect(findSummaryCard(tester, 'Expired').value, '1');

    expect(findSummaryCard(tester, 'Low Stock').value, '2');
  });

  testWidgets('View All calls the Use First callback', (tester) async {
    var useFirstOpened = false;

    await tester.pumpWidget(
      createTestApp(
        onOpenUseFirst: () {
          useFirstOpened = true;
        },
      ),
    );

    await tester.pumpAndSettle();

    final viewAllButton = find.text('View All');

    await tester.ensureVisible(viewAllButton);

    await tester.tap(viewAllButton);
    await tester.pump();

    expect(useFirstOpened, isTrue);
  });

  testWidgets('Low Stock card opens Inventory when items are low', (
    tester,
  ) async {
    var inventoryOpened = false;

    await loadFoodItems([
      createFoodItem(id: 'low_stock_item', name: 'Eggs', quantity: 1),
    ]);

    await tester.pumpWidget(
      createTestApp(
        onOpenInventory: () {
          inventoryOpened = true;
        },
      ),
    );

    await tester.pumpAndSettle();

    final lowStockCard = find.byWidgetPredicate((widget) {
      return widget is DashboardSummaryCard && widget.title == 'Low Stock';
    });

    await tester.ensureVisible(lowStockCard);

    await tester.tap(lowStockCard);
    await tester.pump();

    expect(inventoryOpened, isTrue);
  });

  testWidgets('notification button opens Notifications when alerts exist', (
    tester,
  ) async {
    var notificationsOpened = false;

    await loadFoodItems([
      createFoodItem(id: 'alert_item', name: 'Low Stock Milk', quantity: 1),
    ]);

    await tester.pumpWidget(
      createTestApp(
        onOpenNotifications: () {
          notificationsOpened = true;
        },
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Inventory alerts'));

    await tester.pump();

    expect(notificationsOpened, isTrue);
  });
}

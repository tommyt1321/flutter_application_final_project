import 'package:flutter_application_final_project/models/food_item.dart';
import 'package:flutter_application_final_project/screens/inventory/inventory_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseItem = FoodItem(
    id: 'item-1',
    ownerUserId: 'user-1',
    name: 'Milk',
    quantity: 2,
    unit: 'L',
    categoryId: 'cat-1',
    storageLocationId: 'loc-1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    status: FoodItemStatus.available.name,
  );

  test('available filter keeps stock items that are not consumed, donated, discarded or expired', () {
    expect(
      shouldIncludeItemForFilter(
        item: baseItem,
        filter: FilterOption.available,
        isExpired: false,
        hasConsumed: false,
        hasDonated: false,
        hasDiscarded: false,
      ),
      isTrue,
    );
  });

  test('available filter excludes consumed, donated, discarded, expired and zero-stock items', () {
    expect(
      shouldIncludeItemForFilter(
        item: baseItem.copyWith(quantity: 0),
        filter: FilterOption.available,
        isExpired: false,
        hasConsumed: false,
        hasDonated: false,
        hasDiscarded: false,
      ),
      isFalse,
    );

    expect(
      shouldIncludeItemForFilter(
        item: baseItem,
        filter: FilterOption.available,
        isExpired: true,
        hasConsumed: false,
        hasDonated: false,
        hasDiscarded: false,
      ),
      isFalse,
    );

    expect(
      shouldIncludeItemForFilter(
        item: baseItem,
        filter: FilterOption.available,
        isExpired: false,
        hasConsumed: true,
        hasDonated: false,
        hasDiscarded: false,
      ),
      isFalse,
    );

    expect(
      shouldIncludeItemForFilter(
        item: baseItem,
        filter: FilterOption.available,
        isExpired: false,
        hasConsumed: false,
        hasDonated: true,
        hasDiscarded: false,
      ),
      isFalse,
    );

    expect(
      shouldIncludeItemForFilter(
        item: baseItem,
        filter: FilterOption.available,
        isExpired: false,
        hasConsumed: false,
        hasDonated: false,
        hasDiscarded: true,
      ),
      isFalse,
    );
  });
}

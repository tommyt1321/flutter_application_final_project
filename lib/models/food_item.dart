import 'package:hive_ce_flutter/hive_flutter.dart';

part 'food_item.g.dart';

@HiveType(typeId: 3)
class FoodItem {
  const FoodItem({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.categoryId,
    required this.storageLocationId,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.notes,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ownerUserId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final String categoryId;

  @HiveField(6)
  final String storageLocationId;

  @HiveField(7)
  final DateTime? expiryDate;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  FoodItem copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    double? quantity,
    String? unit,
    String? categoryId,
    String? storageLocationId,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      storageLocationId: storageLocationId ?? this.storageLocationId,
      expiryDate: clearExpiryDate ? null : expiryDate ?? this.expiryDate,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

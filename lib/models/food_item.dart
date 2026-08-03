import 'package:hive_ce_flutter/hive_flutter.dart';

part 'food_item.g.dart';

enum FoodItemStatus { available, consumed, donated, discarded }

extension FoodItemStatusX on FoodItemStatus {
  String get label {
    switch (this) {
      case FoodItemStatus.available:
        return 'Available';
      case FoodItemStatus.consumed:
        return 'Consumed';
      case FoodItemStatus.donated:
        return 'Donated';
      case FoodItemStatus.discarded:
        return 'Discarded';
    }
  }
}

FoodItemStatus parseFoodItemStatus(String? raw) {
  final normalized = raw?.trim().toLowerCase();

  switch (normalized) {
    case 'consumed':
      return FoodItemStatus.consumed;
    case 'donated':
      return FoodItemStatus.donated;
    case 'discarded':
      return FoodItemStatus.discarded;
    default:
      return FoodItemStatus.available;
  }
}

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
    this.expiryDate,
    this.notes,
    this.status,
    this.consumedAt,
    this.donatedAt,
    this.discardedAt,
    required this.createdAt,
    required this.updatedAt,
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
  final String? status;

  @HiveField(10)
  final DateTime? consumedAt;

  @HiveField(11)
  final DateTime? donatedAt;

  @HiveField(12)
  final DateTime? discardedAt;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
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
    String? status,
    bool clearStatus = false,
    bool clearConsumedAt = false,
    bool clearDonatedAt = false,
    bool clearDiscardedAt = false,
    DateTime? consumedAt,
    DateTime? donatedAt,
    DateTime? discardedAt,
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
      status: clearStatus ? null : status ?? this.status,
      consumedAt: clearConsumedAt ? null : consumedAt ?? this.consumedAt,
      donatedAt: clearDonatedAt ? null : donatedAt ?? this.donatedAt,
      discardedAt: clearDiscardedAt ? null : discardedAt ?? this.discardedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  FoodItemStatus get statusEnum => parseFoodItemStatus(status);

  DateTime? get statusTimestamp {
    final status = statusEnum;

    if (status == FoodItemStatus.consumed) {
      return consumedAt;
    }

    if (status == FoodItemStatus.donated) {
      return donatedAt;
    }

    if (status == FoodItemStatus.discarded) {
      return discardedAt;
    }

    return null;
  }
}

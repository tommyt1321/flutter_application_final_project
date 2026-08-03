import 'package:hive_ce_flutter/hive_flutter.dart';

part 'food_activity.g.dart';

/// What happened to a pantry/food item. Stored as an int index rather than
/// its own HiveType to avoid spending an extra typeId.
enum ActivityType { added, consumed, wasted, expired, donated }

@HiveType(typeId: 30)
class FoodActivity {
  const FoodActivity({
    required this.id,
    required this.ownerUserId,
    required this.foodItemId,
    required this.foodItemName,
    required this.activityTypeIndex,
    required this.quantity,
    required this.unit,
    required this.timestamp,
    this.notes,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ownerUserId;

  /// References the FoodItem this activity happened to. Kept as a plain
  /// id (not a direct object reference) so this model doesn't need a hard
  /// dependency on the FoodItem box being open in the same isolate.
  @HiveField(2)
  final String foodItemId;

  /// Denormalised so activity history still reads fine even if the
  /// original FoodItem is later deleted from the pantry.
  @HiveField(3)
  final String foodItemName;

  @HiveField(4)
  final int activityTypeIndex;

  @HiveField(5)
  final double quantity;

  @HiveField(6)
  final String unit;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String? notes;

  ActivityType get activityType => ActivityType.values[activityTypeIndex];

  FoodActivity copyWith({
    String? id,
    String? ownerUserId,
    String? foodItemId,
    String? foodItemName,
    ActivityType? activityType,
    double? quantity,
    String? unit,
    DateTime? timestamp,
    String? notes,
    bool clearNotes = false,
  }) {
    return FoodActivity(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      foodItemId: foodItemId ?? this.foodItemId,
      foodItemName: foodItemName ?? this.foodItemName,
      activityTypeIndex: (activityType ?? this.activityType).index,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
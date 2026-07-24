import 'package:hive_ce_flutter/hive_flutter.dart';

part 'food_category.g.dart';

@HiveType(typeId: 0)
class FoodCategory {
  const FoodCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.isDefault,
    required this.createdAt,
    this.ownerUserId,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconKey;

  @HiveField(3)
  final bool isDefault;

  @HiveField(4)
  final DateTime createdAt;

  // Null for shared default categories.
  // Firebase UID for custom categories.
  @HiveField(5)
  final String? ownerUserId;

  FoodCategory copyWith({
    String? id,
    String? name,
    String? iconKey,
    bool? isDefault,
    DateTime? createdAt,
    String? ownerUserId,
  }) {
    return FoodCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      ownerUserId: ownerUserId ?? this.ownerUserId,
    );
  }
}

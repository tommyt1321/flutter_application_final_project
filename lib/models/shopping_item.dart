import 'package:hive_ce_flutter/hive_flutter.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 4)
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isCompleted,
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
  final bool isCompleted;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  ShoppingItem copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    double? quantity,
    String? unit,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:hive_ce_flutter/hive_flutter.dart';

part 'storage_location.g.dart';

@HiveType(typeId: 1)
class StorageLocation {
  const StorageLocation({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.isDefault,
    required this.createdAt,
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

  StorageLocation copyWith({
    String? id,
    String? name,
    String? iconKey,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return StorageLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

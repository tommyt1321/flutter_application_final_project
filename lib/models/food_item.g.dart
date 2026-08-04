// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodItemAdapter extends TypeAdapter<FoodItem> {
  @override
  final typeId = 3;

  @override
  FoodItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final status = fields[9] as String?;
    final createdAt = (fields[13] as DateTime?) ?? (fields[10] as DateTime);
    final updatedAt = (fields[14] as DateTime?) ?? (fields[11] as DateTime);
    final consumedAt = fields[10] is DateTime ? fields[10] as DateTime? : fields[10] as DateTime?;
    final donatedAt = fields[11] is DateTime ? fields[11] as DateTime? : null;
    final discardedAt = fields[12] is DateTime ? fields[12] as DateTime? : null;

    return FoodItem(
      id: fields[0] as String,
      ownerUserId: fields[1] as String,
      name: fields[2] as String,
      quantity: (fields[3] as num).toDouble(),
      unit: fields[4] as String,
      categoryId: fields[5] as String,
      storageLocationId: fields[6] as String,
      expiryDate: fields[7] as DateTime?,
      notes: fields[8] as String?,
      status: status,
      consumedAt: consumedAt,
      donatedAt: donatedAt,
      discardedAt: discardedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, FoodItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerUserId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.storageLocationId)
      ..writeByte(7)
      ..write(obj.expiryDate)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.consumedAt)
      ..writeByte(11)
      ..write(obj.donatedAt)
      ..writeByte(12)
      ..write(obj.discardedAt)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

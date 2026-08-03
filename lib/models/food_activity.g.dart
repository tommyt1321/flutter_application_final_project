// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodActivityAdapter extends TypeAdapter<FoodActivity> {
  @override
  final typeId = 30;

  @override
  FoodActivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodActivity(
      id: fields[0] as String,
      ownerUserId: fields[1] as String,
      foodItemId: fields[2] as String,
      foodItemName: fields[3] as String,
      activityTypeIndex: (fields[4] as num).toInt(),
      quantity: (fields[5] as num).toDouble(),
      unit: fields[6] as String,
      timestamp: fields[7] as DateTime,
      notes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodActivity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerUserId)
      ..writeByte(2)
      ..write(obj.foodItemId)
      ..writeByte(3)
      ..write(obj.foodItemName)
      ..writeByte(4)
      ..write(obj.activityTypeIndex)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

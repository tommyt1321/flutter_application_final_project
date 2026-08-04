// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnalyticsSummaryAdapter extends TypeAdapter<AnalyticsSummary> {
  @override
  final typeId = 31;

  @override
  AnalyticsSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalyticsSummary(
      id: fields[0] as String,
      ownerUserId: fields[1] as String,
      periodStart: fields[2] as DateTime,
      periodEnd: fields[3] as DateTime,
      totalAdded: (fields[4] as num).toDouble(),
      totalConsumed: (fields[5] as num).toDouble(),
      totalWasted: (fields[6] as num).toDouble(),
      totalExpired: (fields[7] as num).toDouble(),
      wastePercentage: (fields[8] as num).toDouble(),
      generatedAt: fields[9] as DateTime,
      mostWastedItemName: fields[10] as String?,
      totalDonated: fields[11] == null ? 0 : (fields[11] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, AnalyticsSummary obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerUserId)
      ..writeByte(2)
      ..write(obj.periodStart)
      ..writeByte(3)
      ..write(obj.periodEnd)
      ..writeByte(4)
      ..write(obj.totalAdded)
      ..writeByte(5)
      ..write(obj.totalConsumed)
      ..writeByte(6)
      ..write(obj.totalWasted)
      ..writeByte(7)
      ..write(obj.totalExpired)
      ..writeByte(8)
      ..write(obj.wastePercentage)
      ..writeByte(9)
      ..write(obj.generatedAt)
      ..writeByte(10)
      ..write(obj.mostWastedItemName)
      ..writeByte(11)
      ..write(obj.totalDonated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
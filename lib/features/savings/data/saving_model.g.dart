// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingModelAdapter extends TypeAdapter<SavingModel> {
  @override
  final int typeId = 3;

  @override
  SavingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      sourceSessionId: fields[3] as String,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavingModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.sourceSessionId)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

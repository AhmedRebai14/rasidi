// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 1;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as TransactionType,
      categoryId: fields[3] as String,
      date: fields[4] as DateTime,
      note: fields[5] as String?,
      sessionId: fields[6] as String,
      isRecurring: fields[7] as bool,
      recurringInterval: fields[8] as RecurringInterval?,
      receiptImagePath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.sessionId)
      ..writeByte(7)
      ..write(obj.isRecurring)
      ..writeByte(8)
      ..write(obj.recurringInterval)
      ..writeByte(9)
      ..write(obj.receiptImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 6;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringIntervalAdapter extends TypeAdapter<RecurringInterval> {
  @override
  final int typeId = 7;

  @override
  RecurringInterval read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringInterval.daily;
      case 1:
        return RecurringInterval.weekly;
      case 2:
        return RecurringInterval.monthly;
      default:
        return RecurringInterval.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringInterval obj) {
    switch (obj) {
      case RecurringInterval.daily:
        writer.writeByte(0);
        break;
      case RecurringInterval.weekly:
        writer.writeByte(1);
        break;
      case RecurringInterval.monthly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringIntervalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

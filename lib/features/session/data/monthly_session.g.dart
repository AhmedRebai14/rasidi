// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlySessionAdapter extends TypeAdapter<MonthlySession> {
  @override
  final int typeId = 0;

  @override
  MonthlySession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlySession(
      id: fields[0] as String,
      month: fields[1] as String,
      initialBalance: fields[2] as double,
      finalBalance: fields[3] as double,
      status: fields[4] as SessionStatus,
      createdAt: fields[5] as DateTime,
      closedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlySession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.initialBalance)
      ..writeByte(3)
      ..write(obj.finalBalance)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.closedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlySessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionStatusAdapter extends TypeAdapter<SessionStatus> {
  @override
  final int typeId = 5;

  @override
  SessionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionStatus.open;
      case 1:
        return SessionStatus.closed;
      default:
        return SessionStatus.open;
    }
  }

  @override
  void write(BinaryWriter writer, SessionStatus obj) {
    switch (obj) {
      case SessionStatus.open:
        writer.writeByte(0);
        break;
      case SessionStatus.closed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

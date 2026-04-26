// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 4;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      currencySymbol: fields[0] as String,
      language: fields[1] as String,
      isDarkMode: fields[2] as bool,
      isPinEnabled: fields[3] as bool,
      pin: fields[4] as String?,
      isBiometricEnabled: fields[5] as bool,
      lastCategoryUsedId: fields[6] as String?,
      lockTimeoutSeconds: fields[7] as int? ?? 30,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.currencySymbol)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.isDarkMode)
      ..writeByte(3)
      ..write(obj.isPinEnabled)
      ..writeByte(4)
      ..write(obj.pin)
      ..writeByte(5)
      ..write(obj.isBiometricEnabled)
      ..writeByte(6)
      ..write(obj.lastCategoryUsedId)
      ..writeByte(7)
      ..write(obj.lockTimeoutSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

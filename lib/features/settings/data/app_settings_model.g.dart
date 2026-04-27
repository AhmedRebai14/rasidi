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
      // Notification fields — default true for existing records
      notificationsEnabled: fields[8] == null ? true : fields[8] as bool,
      notifyInsights: fields[9] == null ? true : fields[9] as bool,
      notifyStreaks: fields[10] == null ? true : fields[10] as bool,
      notifyBudgetWarnings: fields[11] == null ? true : fields[11] as bool,
      notifyGoalMilestones: fields[12] == null ? true : fields[12] as bool,
      notifyChallenges: fields[13] == null ? true : fields[13] as bool,
      notifySettlement: fields[14] == null ? true : fields[14] as bool,
      notifyWeeklySummary: fields[15] == null ? true : fields[15] as bool,
      notifyBalanceAlerts: fields[16] == null ? true : fields[16] as bool,
      notifyMotivational: fields[17] == null ? false : fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)..write(obj.currencySymbol)
      ..writeByte(1)..write(obj.language)
      ..writeByte(2)..write(obj.isDarkMode)
      ..writeByte(3)..write(obj.isPinEnabled)
      ..writeByte(4)..write(obj.pin)
      ..writeByte(5)..write(obj.isBiometricEnabled)
      ..writeByte(6)..write(obj.lastCategoryUsedId)
      ..writeByte(7)..write(obj.lockTimeoutSeconds)
      ..writeByte(8)..write(obj.notificationsEnabled)
      ..writeByte(9)..write(obj.notifyInsights)
      ..writeByte(10)..write(obj.notifyStreaks)
      ..writeByte(11)..write(obj.notifyBudgetWarnings)
      ..writeByte(12)..write(obj.notifyGoalMilestones)
      ..writeByte(13)..write(obj.notifyChallenges)
      ..writeByte(14)..write(obj.notifySettlement)
      ..writeByte(15)..write(obj.notifyWeeklySummary)
      ..writeByte(16)..write(obj.notifyBalanceAlerts)
      ..writeByte(17)..write(obj.notifyMotivational);
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

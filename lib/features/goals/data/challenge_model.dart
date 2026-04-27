import 'package:hive/hive.dart';

// ── Enums ─────────────────────────────────────────────────────────────────

@HiveType(typeId: 13)
enum ChallengeType {
  @HiveField(0) noSpendDay,
  @HiveField(1) noSpendWeekend,
  @HiveField(2) underBudgetWeek,
  @HiveField(3) logEveryDay,
  @HiveField(4) savingsTarget,
  @HiveField(5) beatLastMonth,
  @HiveField(6) zeroOffBudget,
  @HiveField(7) addReceiptFiveTimes,
  @HiveField(8) firstSettlement,
  @HiveField(9) threeMonthPositive,
}

@HiveType(typeId: 14)
enum ChallengeStatus {
  @HiveField(0) active,
  @HiveField(1) completed,
  @HiveField(2) failed,
  @HiveField(3) locked,
}

// ── Model ─────────────────────────────────────────────────────────────────

@HiveType(typeId: 12)
class ChallengeModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final ChallengeType type;
  @HiveField(2) final String titleKey;
  @HiveField(3) final String descKey;
  @HiveField(4) final int xpReward;
  @HiveField(5) final String badgeIcon;
  @HiveField(6) ChallengeStatus status;
  @HiveField(7) final DateTime startDate;
  @HiveField(8) final DateTime endDate;
  @HiveField(9) final double? targetAmount;
  @HiveField(10) double currentProgress;

  ChallengeModel({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.descKey,
    required this.xpReward,
    required this.badgeIcon,
    this.status = ChallengeStatus.locked,
    required this.startDate,
    required this.endDate,
    this.targetAmount,
    this.currentProgress = 0,
  });

  bool get isActive => status == ChallengeStatus.active;
  bool get isCompleted => status == ChallengeStatus.completed;

  ChallengeModel copyWith({
    ChallengeStatus? status,
    double? currentProgress,
  }) =>
      ChallengeModel(
        id: id,
        type: type,
        titleKey: titleKey,
        descKey: descKey,
        xpReward: xpReward,
        badgeIcon: badgeIcon,
        status: status ?? this.status,
        startDate: startDate,
        endDate: endDate,
        targetAmount: targetAmount,
        currentProgress: currentProgress ?? this.currentProgress,
      );
}

// ── Adapters ──────────────────────────────────────────────────────────────

class ChallengeTypeAdapter extends TypeAdapter<ChallengeType> {
  @override
  final int typeId = 13;
  @override
  ChallengeType read(BinaryReader reader) =>
      ChallengeType.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, ChallengeType obj) =>
      writer.writeByte(obj.index);
}

class ChallengeStatusAdapter extends TypeAdapter<ChallengeStatus> {
  @override
  final int typeId = 14;
  @override
  ChallengeStatus read(BinaryReader reader) =>
      ChallengeStatus.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, ChallengeStatus obj) =>
      writer.writeByte(obj.index);
}

class ChallengeModelAdapter extends TypeAdapter<ChallengeModel> {
  @override
  final int typeId = 12;

  @override
  ChallengeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChallengeModel(
      id: fields[0] as String,
      type: fields[1] as ChallengeType,
      titleKey: fields[2] as String,
      descKey: fields[3] as String,
      xpReward: fields[4] as int,
      badgeIcon: fields[5] as String,
      status: fields[6] as ChallengeStatus? ?? ChallengeStatus.locked,
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime,
      targetAmount: (fields[9] as num?)?.toDouble(),
      currentProgress: (fields[10] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ChallengeModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.type)
      ..writeByte(2)..write(obj.titleKey)
      ..writeByte(3)..write(obj.descKey)
      ..writeByte(4)..write(obj.xpReward)
      ..writeByte(5)..write(obj.badgeIcon)
      ..writeByte(6)..write(obj.status)
      ..writeByte(7)..write(obj.startDate)
      ..writeByte(8)..write(obj.endDate)
      ..writeByte(9)..write(obj.targetAmount)
      ..writeByte(10)..write(obj.currentProgress);
  }
}

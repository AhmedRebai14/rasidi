import 'package:hive/hive.dart';

@HiveType(typeId: 15)
class UserStatsModel extends HiveObject {
  @HiveField(0) int totalXP;
  @HiveField(1) int level;
  @HiveField(2) int dailyLogStreak;
  @HiveField(3) int noOverspendStreak;
  @HiveField(4) int settlementStreak;
  @HiveField(5) List<String> earnedBadges;
  @HiveField(6) DateTime? lastLogDate;
  @HiveField(7) int totalTransactions;
  @HiveField(8) int totalSettlements;

  UserStatsModel({
    this.totalXP = 0,
    this.level = 1,
    this.dailyLogStreak = 0,
    this.noOverspendStreak = 0,
    this.settlementStreak = 0,
    List<String>? earnedBadges,
    this.lastLogDate,
    this.totalTransactions = 0,
    this.totalSettlements = 0,
  }) : earnedBadges = earnedBadges ?? [];

  // ── Level thresholds: 0/100/300/600/1000/1500
  String get levelTitle {
    if (totalXP >= 1500) return 'Rasidi Pro 👑';
    if (totalXP >= 1000) return 'Finance Master';
    if (totalXP >= 600) return 'Smart Tracker';
    if (totalXP >= 300) return 'Budget Aware';
    if (totalXP >= 100) return 'Conscious Spender';
    return 'Beginner Saver';
  }

  int get nextLevelXP {
    const thresholds = [100, 300, 600, 1000, 1500, 9999];
    final idx = (level - 1).clamp(0, thresholds.length - 1);
    return thresholds[idx];
  }

  double get levelProgress =>
      nextLevelXP > 0 ? (totalXP / nextLevelXP).clamp(0.0, 1.0) : 1.0;

  UserStatsModel copyWith({
    int? totalXP,
    int? level,
    int? dailyLogStreak,
    int? noOverspendStreak,
    int? settlementStreak,
    List<String>? earnedBadges,
    DateTime? lastLogDate,
    int? totalTransactions,
    int? totalSettlements,
  }) =>
      UserStatsModel(
        totalXP: totalXP ?? this.totalXP,
        level: level ?? this.level,
        dailyLogStreak: dailyLogStreak ?? this.dailyLogStreak,
        noOverspendStreak: noOverspendStreak ?? this.noOverspendStreak,
        settlementStreak: settlementStreak ?? this.settlementStreak,
        earnedBadges: earnedBadges ?? List.from(this.earnedBadges),
        lastLogDate: lastLogDate ?? this.lastLogDate,
        totalTransactions: totalTransactions ?? this.totalTransactions,
        totalSettlements: totalSettlements ?? this.totalSettlements,
      );
}

// ── Manual TypeAdapter ─────────────────────────────────────────────────────

class UserStatsModelAdapter extends TypeAdapter<UserStatsModel> {
  @override
  final int typeId = 15;

  @override
  UserStatsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStatsModel(
      totalXP: fields[0] as int? ?? 0,
      level: fields[1] as int? ?? 1,
      dailyLogStreak: fields[2] as int? ?? 0,
      noOverspendStreak: fields[3] as int? ?? 0,
      settlementStreak: fields[4] as int? ?? 0,
      earnedBadges: (fields[5] as List?)?.cast<String>() ?? [],
      lastLogDate: fields[6] as DateTime?,
      totalTransactions: fields[7] as int? ?? 0,
      totalSettlements: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, UserStatsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.totalXP)
      ..writeByte(1)..write(obj.level)
      ..writeByte(2)..write(obj.dailyLogStreak)
      ..writeByte(3)..write(obj.noOverspendStreak)
      ..writeByte(4)..write(obj.settlementStreak)
      ..writeByte(5)..write(obj.earnedBadges)
      ..writeByte(6)..write(obj.lastLogDate)
      ..writeByte(7)..write(obj.totalTransactions)
      ..writeByte(8)..write(obj.totalSettlements);
  }
}

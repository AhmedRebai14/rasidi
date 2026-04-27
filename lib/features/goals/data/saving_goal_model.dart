import 'package:hive/hive.dart';

// ── GoalContribution (not a HiveObject, stored inside SavingGoalModel) ────

class GoalContribution {
  final double amount;
  final DateTime date;
  final String note;

  GoalContribution({
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'note': note,
      };

  static GoalContribution fromMap(Map map) => GoalContribution(
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        note: map['note'] as String? ?? '',
      );
}

// ── SavingGoalModel ────────────────────────────────────────────────────────

@HiveType(typeId: 11)
class SavingGoalModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) double targetAmount;
  @HiveField(3) double currentAmount;
  @HiveField(4) String icon;
  @HiveField(5) int color;
  @HiveField(6) final DateTime createdAt;
  @HiveField(7) DateTime? deadline;
  @HiveField(8) bool isCompleted;
  @HiveField(9) DateTime? completedAt;
  /// Stored as list of maps for simplicity (no nested adapter needed)
  @HiveField(10) List<Map<dynamic, dynamic>> contributionMaps;

  SavingGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.icon = '🎯',
    required this.color,
    required this.createdAt,
    this.deadline,
    this.isCompleted = false,
    this.completedAt,
    List<Map<dynamic, dynamic>>? contributionMaps,
  }) : contributionMaps = contributionMaps ?? [];

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  List<GoalContribution> get contributions =>
      contributionMaps.map((m) => GoalContribution.fromMap(m)).toList();

  SavingGoalModel copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    int? color,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? completedAt,
    List<Map<dynamic, dynamic>>? contributionMaps,
  }) =>
      SavingGoalModel(
        id: id,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        createdAt: createdAt,
        deadline: deadline ?? this.deadline,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
        contributionMaps: contributionMaps ?? this.contributionMaps,
      );
}

// ── Manual TypeAdapter ─────────────────────────────────────────────────────

class SavingGoalModelAdapter extends TypeAdapter<SavingGoalModel> {
  @override
  final int typeId = 11;

  @override
  SavingGoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingGoalModel(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: (fields[2] as num).toDouble(),
      currentAmount: (fields[3] as num).toDouble(),
      icon: fields[4] as String? ?? '🎯',
      color: fields[5] as int,
      createdAt: fields[6] as DateTime,
      deadline: fields[7] as DateTime?,
      isCompleted: fields[8] as bool? ?? false,
      completedAt: fields[9] as DateTime?,
      contributionMaps: (fields[10] as List?)
              ?.map((e) => (e as Map))
              .toList() ??
          [],
    );
  }

  @override
  void write(BinaryWriter writer, SavingGoalModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.targetAmount)
      ..writeByte(3)..write(obj.currentAmount)
      ..writeByte(4)..write(obj.icon)
      ..writeByte(5)..write(obj.color)
      ..writeByte(6)..write(obj.createdAt)
      ..writeByte(7)..write(obj.deadline)
      ..writeByte(8)..write(obj.isCompleted)
      ..writeByte(9)..write(obj.completedAt)
      ..writeByte(10)..write(obj.contributionMaps);
  }
}

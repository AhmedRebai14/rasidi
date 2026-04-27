import 'package:hive/hive.dart';

// ── Enums ─────────────────────────────────────────────────────────────────

@HiveType(typeId: 9)
enum InsightType {
  @HiveField(0) weekOverWeek,
  @HiveField(1) categorySpike,
  @HiveField(2) paceWarning,
  @HiveField(3) pacePositive,
  @HiveField(4) noSpendStreak,
  @HiveField(5) biggestExpense,
  @HiveField(6) offBudgetSaved,
  @HiveField(7) incomeGap,
  @HiveField(8) unusualTransaction,
  @HiveField(9) bestDay,
}

@HiveType(typeId: 10)
enum InsightSentiment {
  @HiveField(0) positive,
  @HiveField(1) warning,
  @HiveField(2) critical,
  @HiveField(3) neutral,
  @HiveField(4) tip,
}

// ── Model ─────────────────────────────────────────────────────────────────

@HiveType(typeId: 8)
class InsightModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final InsightType type;
  @HiveField(2) final String titleKey;
  @HiveField(3) final String bodyKey;
  @HiveField(4) final Map<String, String> params;
  @HiveField(5) final DateTime generatedAt;
  @HiveField(6) bool isDismissed;
  @HiveField(7) final String? actionRoute;
  @HiveField(8) final InsightSentiment sentiment;

  InsightModel({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    required this.params,
    required this.generatedAt,
    required this.isDismissed,
    this.actionRoute,
    required this.sentiment,
  });

  InsightModel copyWith({bool? isDismissed}) => InsightModel(
        id: id,
        type: type,
        titleKey: titleKey,
        bodyKey: bodyKey,
        params: params,
        generatedAt: generatedAt,
        isDismissed: isDismissed ?? this.isDismissed,
        actionRoute: actionRoute,
        sentiment: sentiment,
      );
}

// ── Manual TypeAdapters ───────────────────────────────────────────────────

class InsightTypeAdapter extends TypeAdapter<InsightType> {
  @override
  final int typeId = 9;

  @override
  InsightType read(BinaryReader reader) {
    return InsightType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, InsightType obj) {
    writer.writeByte(obj.index);
  }
}

class InsightSentimentAdapter extends TypeAdapter<InsightSentiment> {
  @override
  final int typeId = 10;

  @override
  InsightSentiment read(BinaryReader reader) {
    return InsightSentiment.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, InsightSentiment obj) {
    writer.writeByte(obj.index);
  }
}

class InsightModelAdapter extends TypeAdapter<InsightModel> {
  @override
  final int typeId = 8;

  @override
  InsightModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InsightModel(
      id: fields[0] as String,
      type: fields[1] as InsightType,
      titleKey: fields[2] as String,
      bodyKey: fields[3] as String,
      params: (fields[4] as Map).cast<String, String>(),
      generatedAt: fields[5] as DateTime,
      isDismissed: fields[6] as bool,
      actionRoute: fields[7] as String?,
      sentiment: fields[8] as InsightSentiment,
    );
  }

  @override
  void write(BinaryWriter writer, InsightModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.type)
      ..writeByte(2)..write(obj.titleKey)
      ..writeByte(3)..write(obj.bodyKey)
      ..writeByte(4)..write(obj.params)
      ..writeByte(5)..write(obj.generatedAt)
      ..writeByte(6)..write(obj.isDismissed)
      ..writeByte(7)..write(obj.actionRoute)
      ..writeByte(8)..write(obj.sentiment);
  }
}

import 'package:hive/hive.dart';

part 'saving_model.g.dart';

/// A saving entry — money saved from a monthly settlement
@HiveType(typeId: 3)
class SavingModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String sourceSessionId;

  @HiveField(4)
  String? note;

  SavingModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.sourceSessionId,
    this.note,
  });
}

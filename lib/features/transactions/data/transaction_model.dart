import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

/// Whether a transaction adds or removes from balance
@HiveType(typeId: 6)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

/// How often a recurring transaction repeats
@HiveType(typeId: 7)
enum RecurringInterval {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
}

/// A single income or expense transaction
@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  String sessionId;

  @HiveField(7)
  bool isRecurring;

  @HiveField(8)
  RecurringInterval? recurringInterval;

  @HiveField(9)
  String? receiptImagePath;

  @HiveField(10)
  bool affectsBalance;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    required this.sessionId,
    this.isRecurring = false,
    this.recurringInterval,
    this.receiptImagePath,
    this.affectsBalance = true,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  TransactionModel copyWith({
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? note,
    bool? isRecurring,
    RecurringInterval? recurringInterval,
    String? receiptImagePath,
    bool? affectsBalance,
  }) {
    return TransactionModel(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      sessionId: sessionId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      affectsBalance: affectsBalance ?? this.affectsBalance,
    );
  }
}

import 'package:hive/hive.dart';

part 'monthly_session.g.dart';

/// Status of a monthly financial session
@HiveType(typeId: 5)
enum SessionStatus {
  @HiveField(0)
  open,
  @HiveField(1)
  closed,
}

/// Represents one month's financial cycle/session
@HiveType(typeId: 0)
class MonthlySession extends HiveObject {
  @HiveField(0)
  String id;

  /// Format: YYYY-MM (e.g., "2026-04")
  @HiveField(1)
  String month;

  @HiveField(2)
  double initialBalance;

  @HiveField(3)
  double finalBalance;

  @HiveField(4)
  SessionStatus status;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? closedAt;

  MonthlySession({
    required this.id,
    required this.month,
    required this.initialBalance,
    this.finalBalance = 0,
    this.status = SessionStatus.open,
    required this.createdAt,
    this.closedAt,
  });

  bool get isOpen => status == SessionStatus.open;
  bool get isClosed => status == SessionStatus.closed;

  /// Create a copy with updated fields
  MonthlySession copyWith({
    double? finalBalance,
    SessionStatus? status,
    DateTime? closedAt,
  }) {
    return MonthlySession(
      id: id,
      month: month,
      initialBalance: initialBalance,
      finalBalance: finalBalance ?? this.finalBalance,
      status: status ?? this.status,
      createdAt: createdAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

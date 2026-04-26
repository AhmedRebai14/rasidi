import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../features/transactions/data/transaction_model.dart';
import '../../features/session/data/monthly_session.dart';

/// Checks for due recurring transactions on every app launch and creates them
class RecurringTransactionService {
  RecurringTransactionService._();

  static Future<void> processRecurring() async {
    try {
      final txBox = Hive.box<TransactionModel>(HiveBoxes.transactions);
      final sessionBox = Hive.box<MonthlySession>(HiveBoxes.sessions);

      // Only process if there's an open session
      final openSession = sessionBox.values
          .where((s) => s.isOpen)
          .firstOrNull;
      if (openSession == null) return;

      final now = DateTime.now();
      final recurringTxs = txBox.values
          .where((t) => t.isRecurring && t.recurringInterval != null)
          .toList();

      for (final tx in recurringTxs) {
        if (_isDue(tx, now, openSession)) {
          // Check if we already created this recurring tx today
          final alreadyCreated = txBox.values.any((t) =>
              t.sessionId == openSession.id &&
              !t.isRecurring &&
              t.categoryId == tx.categoryId &&
              t.amount == tx.amount &&
              t.type == tx.type &&
              _isSameDay(t.date, now));

          if (!alreadyCreated) {
            final newTx = TransactionModel(
              id: '${DateTime.now().millisecondsSinceEpoch}_r',
              amount: tx.amount,
              type: tx.type,
              categoryId: tx.categoryId,
              date: now,
              note: tx.note != null ? '${tx.note} (Auto)' : 'Recurring (Auto)',
              sessionId: openSession.id,
              isRecurring: false, // The copy itself is not recurring
            );
            await txBox.put(newTx.id, newTx);
          }
        }
      }
    } catch (e) {
      // Silently fail — never crash the app on startup
    }
  }

  /// Determine if a recurring transaction is due today
  static bool _isDue(
      TransactionModel tx, DateTime now, MonthlySession session) {
    final lastDate = tx.date;

    switch (tx.recurringInterval!) {
      case RecurringInterval.daily:
        // Due every day after initial creation
        return !_isSameDay(lastDate, now);
      case RecurringInterval.weekly:
        final diff = now.difference(lastDate).inDays;
        return diff > 0 && diff % 7 == 0;
      case RecurringInterval.monthly:
        // Due on same day of month in current session
        final sessionParts = session.month.split('-');
        final sessionYear = int.parse(sessionParts[0]);
        final sessionMonth = int.parse(sessionParts[1]);
        return now.year == sessionYear &&
            now.month == sessionMonth &&
            now.day == lastDate.day &&
            !_isSameDay(lastDate, now);
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/monthly_session.dart';
import '../../transactions/data/transaction_model.dart';

/// Notifier that manages the list of all sessions
class SessionNotifier extends StateNotifier<List<MonthlySession>> {
  SessionNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<MonthlySession>(HiveBoxes.sessions);
    state = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get the currently open session (null if none)
  MonthlySession? get activeSession =>
      state.where((s) => s.isOpen).firstOrNull;

  /// Start a new monthly session with given initial balance
  Future<MonthlySession?> startSession({
    required String month,
    required double initialBalance,
  }) async {
    // Rule: only one OPEN session at a time
    if (activeSession != null) return null;

    try {
      final box = Hive.box<MonthlySession>(HiveBoxes.sessions);
      final session = MonthlySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        month: month,
        initialBalance: initialBalance,
        finalBalance: 0,
        status: SessionStatus.open,
        createdAt: DateTime.now(),
      );
      await box.put(session.id, session);
      _load();
      return session;
    } catch (e) {
      return null;
    }
  }

  /// Close a session as part of settlement
  Future<bool> closeSession({
    required String sessionId,
    required double finalBalance,
  }) async {
    try {
      final box = Hive.box<MonthlySession>(HiveBoxes.sessions);
      final session = box.get(sessionId);
      if (session == null) return false;

      session.finalBalance = finalBalance;
      session.status = SessionStatus.closed;
      session.closedAt = DateTime.now();
      await session.save();
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  void refresh() => _load();
}

/// Provider for all sessions
final sessionListProvider =
    StateNotifierProvider<SessionNotifier, List<MonthlySession>>(
  (ref) => SessionNotifier(),
);

/// Provider for the currently active (open) session
final activeSessionProvider = Provider<MonthlySession?>((ref) {
  final sessions = ref.watch(sessionListProvider);
  return sessions.where((s) => s.isOpen).firstOrNull;
});

/// Provider for sorted transaction list of a specific session
final sessionTransactionsProvider =
    Provider.family<List<TransactionModel>, String>((ref, sessionId) {
  final box = Hive.box<TransactionModel>(HiveBoxes.transactions);
  return box.values
      .where((t) => t.sessionId == sessionId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

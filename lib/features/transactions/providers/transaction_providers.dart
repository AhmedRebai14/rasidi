import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/transaction_model.dart';

/// Filter state for the transaction list
enum TransactionFilter { all, income, expense }

/// Sort options for the transaction list
enum TransactionSort { newest, oldest, highest }

/// Manages all transactions in a session
class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<TransactionModel>(HiveBoxes.transactions);
    state = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Transactions for a specific session
  List<TransactionModel> forSession(String sessionId) =>
      state.where((t) => t.sessionId == sessionId).toList();

  /// Add a new transaction
  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final box = Hive.box<TransactionModel>(HiveBoxes.transactions);
      await box.put(transaction.id, transaction);
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing transaction
  Future<bool> updateTransaction(TransactionModel updated) async {
    try {
      final box = Hive.box<TransactionModel>(HiveBoxes.transactions);
      final existing = box.get(updated.id);
      if (existing == null) return false;

      existing.amount = updated.amount;
      existing.type = updated.type;
      existing.categoryId = updated.categoryId;
      existing.date = updated.date;
      existing.note = updated.note;
      existing.isRecurring = updated.isRecurring;
      existing.recurringInterval = updated.recurringInterval;
      await existing.save();
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a transaction by ID
  Future<bool> deleteTransaction(String id) async {
    try {
      final box = Hive.box<TransactionModel>(HiveBoxes.transactions);
      await box.delete(id);
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Duplicate a transaction (create copy with new id and today's date)
  Future<bool> duplicateTransaction(TransactionModel original) async {
    final copy = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: original.amount,
      type: original.type,
      categoryId: original.categoryId,
      date: DateTime.now(),
      note: original.note,
      sessionId: original.sessionId,
      isRecurring: false,
    );
    return addTransaction(copy);
  }

  void refresh() => _load();
}

// ── Providers ──────────────────────────────────────────────────────────────

final transactionsProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  (ref) => TransactionNotifier(),
);

/// Current filter applied to the transaction list
final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter.all);

/// Current sort applied to the transaction list
final transactionSortProvider =
    StateProvider<TransactionSort>((ref) => TransactionSort.newest);

/// Current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered + sorted transactions for a given session
final filteredTransactionsProvider =
    Provider.family<List<TransactionModel>, String>((ref, sessionId) {
  final all = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  final sort = ref.watch(transactionSortProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  var filtered = all.where((t) => t.sessionId == sessionId).toList();

  // Apply type filter
  if (filter == TransactionFilter.income) {
    filtered = filtered.where((t) => t.isIncome).toList();
  } else if (filter == TransactionFilter.expense) {
    filtered = filtered.where((t) => t.isExpense).toList();
  }

  // Apply search
  if (query.isNotEmpty) {
    filtered = filtered.where((t) {
      final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
      return noteMatch || t.categoryId.toLowerCase().contains(query);
    }).toList();
  }

  // Apply sort
  switch (sort) {
    case TransactionSort.newest:
      filtered.sort((a, b) => b.date.compareTo(a.date));
    case TransactionSort.oldest:
      filtered.sort((a, b) => a.date.compareTo(b.date));
    case TransactionSort.highest:
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
  }

  return filtered;
});

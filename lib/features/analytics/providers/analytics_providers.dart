import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/balance_calculator.dart';
import '../../session/providers/session_providers.dart';
import '../../transactions/data/transaction_model.dart';
import '../../transactions/providers/transaction_providers.dart';

/// Computed analytics data for a session
class AnalyticsData {
  final double totalIncome;
  final double totalExpenses;
  final double remainingBalance;
  final double initialBalance;
  final double dailyAverage;
  final double projectedBalance;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeByCategory;
  final Map<DateTime, double> dailySpending;
  final List<FlSpot> balanceOverTime;
  final int transactionCount;
  final String? biggestSpendingCategoryId;

  const AnalyticsData({
    this.totalIncome = 0,
    this.totalExpenses = 0,
    this.remainingBalance = 0,
    this.initialBalance = 0,
    this.dailyAverage = 0,
    this.projectedBalance = 0,
    this.expensesByCategory = const {},
    this.incomeByCategory = const {},
    this.dailySpending = const {},
    this.balanceOverTime = const [],
    this.transactionCount = 0,
    this.biggestSpendingCategoryId,
  });
}

/// Computed analytics for the active session
final analyticsProvider = Provider<AnalyticsData>((ref) {
  final session = ref.watch(activeSessionProvider);
  if (session == null) return const AnalyticsData();

  final allTransactions = ref.watch(transactionsProvider);
  final transactions =
      allTransactions.where((t) => t.sessionId == session.id).toList();

  // Aggregate totals
  double totalIncome = 0;
  double totalExpenses = 0;
  final Map<String, double> expensesByCategory = {};
  final Map<String, double> incomeByCategory = {};
  final Map<String, double> dailySpendingByDay = {};

  for (final tx in transactions) {
    if (tx.isIncome) {
      totalIncome += tx.amount;
      incomeByCategory[tx.categoryId] =
          (incomeByCategory[tx.categoryId] ?? 0) + tx.amount;
    } else {
      totalExpenses += tx.amount;
      expensesByCategory[tx.categoryId] =
          (expensesByCategory[tx.categoryId] ?? 0) + tx.amount;

      // Daily spending aggregation — keyed by day number
      final dayKey = tx.date.day.toString();
      dailySpendingByDay[dayKey] =
          (dailySpendingByDay[dayKey] ?? 0) + tx.amount;
    }
  }

  final remaining = BalanceCalculator.remaining(
    initialBalance: session.initialBalance,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
  );

  final dailyAvg = BalanceCalculator.dailyAverage(
    totalExpenses: totalExpenses,
    monthKey: session.month,
  );

  final projected = BalanceCalculator.projectedBalance(
    currentBalance: remaining,
    totalExpenses: totalExpenses,
    monthKey: session.month,
  );

  // Build balance-over-time line chart spots
  final sortedTx = List<TransactionModel>.from(transactions)
    ..sort((a, b) => a.date.compareTo(b.date));

  double runningBalance = session.initialBalance;
  final List<FlSpot> balanceSpots = [
    FlSpot(0, session.initialBalance),
  ];

  for (final tx in sortedTx) {
    if (tx.isIncome) {
      runningBalance += tx.amount;
    } else {
      runningBalance -= tx.amount;
    }
    balanceSpots.add(FlSpot(tx.date.day.toDouble(), runningBalance));
  }

  // Find biggest spending category
  String? biggestCategoryId;
  if (expensesByCategory.isNotEmpty) {
    biggestCategoryId = expensesByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Convert dailySpending to DateTime keys
  final Map<DateTime, double> dailyMap = {};
  dailySpendingByDay.forEach((day, amount) {
    final parts = session.month.split('-');
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(day));
    dailyMap[date] = amount;
  });

  return AnalyticsData(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    remainingBalance: remaining,
    initialBalance: session.initialBalance,
    dailyAverage: dailyAvg,
    projectedBalance: projected,
    expensesByCategory: expensesByCategory,
    incomeByCategory: incomeByCategory,
    dailySpending: dailyMap,
    balanceOverTime: balanceSpots,
    transactionCount: transactions.length,
    biggestSpendingCategoryId: biggestCategoryId,
  );
});

/// Analytics for a specific closed session (for history tab)
final sessionAnalyticsProvider =
    Provider.family<AnalyticsData, String>((ref, sessionId) {
  final box = ref.watch(transactionsProvider);
  final transactions = box.where((t) => t.sessionId == sessionId).toList();

  double totalIncome = 0;
  double totalExpenses = 0;
  final Map<String, double> expensesByCategory = {};
  final Map<String, double> incomeByCategory = {};

  for (final tx in transactions) {
    if (tx.isIncome) {
      totalIncome += tx.amount;
      incomeByCategory[tx.categoryId] =
          (incomeByCategory[tx.categoryId] ?? 0) + tx.amount;
    } else {
      totalExpenses += tx.amount;
      expensesByCategory[tx.categoryId] =
          (expensesByCategory[tx.categoryId] ?? 0) + tx.amount;
    }
  }

  return AnalyticsData(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    expensesByCategory: expensesByCategory,
    incomeByCategory: incomeByCategory,
    transactionCount: transactions.length,
  );
});

import '../utils/date_utils.dart';

/// Business logic for balance calculations
class BalanceCalculator {
  BalanceCalculator._();

  /// Remaining balance = initial + income - expenses
  static double remaining({
    required double initialBalance,
    required double totalIncome,
    required double totalExpenses,
  }) {
    return initialBalance + totalIncome - totalExpenses;
  }

  /// Daily average spending based on days passed
  static double dailyAverage({
    required double totalExpenses,
    required String monthKey,
  }) {
    final days = AppDateUtils.daysPassed(monthKey);
    if (days == 0) return 0;
    return totalExpenses / days;
  }

  /// Projected end-of-month balance
  static double projectedBalance({
    required double currentBalance,
    required double totalExpenses,
    required String monthKey,
  }) {
    final avgDaily = dailyAverage(totalExpenses: totalExpenses, monthKey: monthKey);
    final daysLeft = AppDateUtils.remainingDays(monthKey);
    return currentBalance - (avgDaily * daysLeft);
  }

  /// Balance health status
  /// Returns 'healthy', 'tight', or 'danger'
  static String balanceHealth({
    required double projectedBalance,
    required double initialBalance,
  }) {
    if (initialBalance <= 0) return 'danger';
    final ratio = projectedBalance / initialBalance;
    if (ratio > 0.20) return 'healthy';
    if (ratio >= 0) return 'tight';
    return 'danger';
  }

  /// Returns percentage of budget used (0.0 to 1.0+)
  static double budgetUsageRatio({
    required double spent,
    required double limit,
  }) {
    if (limit <= 0) return 0;
    return spent / limit;
  }

  /// Check if a category is over budget
  static bool isOverBudget({
    required double spent,
    required double? limit,
  }) {
    if (limit == null || limit <= 0) return false;
    return spent >= limit;
  }

  /// Check if a category is approaching budget (80%)
  static bool isApproachingBudget({
    required double spent,
    required double? limit,
  }) {
    if (limit == null || limit <= 0) return false;
    return spent >= limit * 0.80 && spent < limit;
  }
}

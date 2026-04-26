import 'package:intl/intl.dart';

/// Formats currency amounts consistently across the app
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format a number as currency with the given symbol
  static String format(double amount, {String symbol = 'DA', bool showSign = false}) {
    final formatted = NumberFormat('#,##0.00').format(amount.abs());
    final sign = showSign && amount > 0 ? '+' : '';
    final negative = amount < 0 ? '-' : '';
    return '$negative$sign$formatted $symbol';
  }

  /// Format a number as compact currency (e.g. 85K DA)
  static String formatCompact(double amount, {String symbol = 'DA'}) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $symbol';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $symbol';
    }
    return format(amount, symbol: symbol);
  }

  /// Format without decimal if whole number
  static String formatClean(double amount, {String symbol = 'DA'}) {
    final prefix = amount < 0 ? '-' : '';
    if (amount == amount.roundToDouble()) {
      return '$prefix${NumberFormat('#,##0').format(amount.abs())} $symbol';
    }
    return format(amount, symbol: symbol);
  }
}

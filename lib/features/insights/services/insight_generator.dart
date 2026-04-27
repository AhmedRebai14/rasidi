import '../data/insight_model.dart';
import '../../session/data/monthly_session.dart';
import '../../transactions/data/transaction_model.dart';
import '../../categories/data/category_model.dart';

/// Generates up to 3 daily smart insights from current session data.
class InsightGenerator {

  List<InsightModel> generate({
    required MonthlySession session,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
  }) {
    final insights = <InsightModel>[];
    final now = DateTime.now();
    final expenses = transactions.where((t) => t.isExpense).toList();

    // ── 1. Week-over-week spending ─────────────────────────────────────────
    final thisWeek = _weekTotal(expenses, 0);
    final lastWeek = _weekTotal(expenses, 1);
    if (lastWeek > 0) {
      final pct = ((thisWeek - lastWeek) / lastWeek * 100).round();
      if (pct.abs() >= 20) {
        insights.add(InsightModel(
          id: 'wow_${_weekKey()}',
          type: InsightType.weekOverWeek,
          titleKey: 'insight_wow_title',
          bodyKey: 'insight_wow_body',
          params: {'pct': '${pct.abs()}', 'dir': pct > 0 ? 'more' : 'less'},
          sentiment: pct > 0 ? InsightSentiment.warning : InsightSentiment.positive,
          generatedAt: now,
          isDismissed: false,
          actionRoute: '/transactions',
        ));
      }
    }

    // ── 2. Category spike ──────────────────────────────────────────────────
    for (final cat in categories.where((c) => c.type == TransactionType.expense)) {
      final thisWeekCat = _weekCatTotal(expenses, cat.id, 0);
      final avgWeeklyCat = _avgWeeklyCat(expenses, cat.id);
      if (avgWeeklyCat > 0 && thisWeekCat > 0) {
        final pct = ((thisWeekCat - avgWeeklyCat) / avgWeeklyCat * 100).round();
        if (pct >= 40) {
          insights.add(InsightModel(
            id: 'catspike_${cat.id}_${_weekKey()}',
            type: InsightType.categorySpike,
            titleKey: 'insight_catspike_title',
            bodyKey: 'insight_catspike_body',
            params: {'cat': cat.name, 'pct': '$pct'},
            sentiment: InsightSentiment.warning,
            generatedAt: now,
            isDismissed: false,
            actionRoute: '/analytics',
          ));
          break;
        }
      }
    }

    // ── 3. Pace warning / positive ─────────────────────────────────────────
    final remaining = _remainingBalance(session, transactions);
    final dailyAvg = _dailyAvg(expenses);
    final daysLeft = _daysLeft(session);
    if (dailyAvg > 0 && daysLeft > 0) {
      final projected = remaining - (dailyAvg * daysLeft);
      if (projected < 0) {
        final daysUntilZero = dailyAvg > 0
            ? (remaining / dailyAvg).floor().clamp(0, 999)
            : 0;
        insights.add(InsightModel(
          id: 'pace_warn_${now.day}',
          type: InsightType.paceWarning,
          titleKey: 'insight_pace_warn_title',
          bodyKey: 'insight_pace_warn_body',
          params: {'days': '$daysUntilZero'},
          sentiment: InsightSentiment.critical,
          generatedAt: now,
          isDismissed: false,
          actionRoute: '/analytics',
        ));
      } else if (projected > session.initialBalance * 0.15) {
        insights.add(InsightModel(
          id: 'pace_pos_${now.day}',
          type: InsightType.pacePositive,
          titleKey: 'insight_pace_pos_title',
          bodyKey: 'insight_pace_pos_body',
          params: {'amount': projected.toStringAsFixed(0)},
          sentiment: InsightSentiment.positive,
          generatedAt: now,
          isDismissed: false,
          actionRoute: '/savings',
        ));
      }
    }

    // ── 4. No-spend streak ─────────────────────────────────────────────────
    final streak = _noSpendStreak(expenses);
    if (streak >= 2) {
      insights.add(InsightModel(
        id: 'noSpend_${now.day}',
        type: InsightType.noSpendStreak,
        titleKey: 'insight_nospend_title',
        bodyKey: 'insight_nospend_body',
        params: {'days': '$streak'},
        sentiment: InsightSentiment.positive,
        generatedAt: now,
        isDismissed: false,
        actionRoute: null,
      ));
    }

    // ── 5. Off-budget usage ─────────────────────────────────────────────────
    final offBudgetTxs =
        transactions.where((t) => !t.affectsBalance && t.isExpense).toList();
    if (offBudgetTxs.isNotEmpty) {
      final total = offBudgetTxs.fold(0.0, (s, t) => s + t.amount);
      insights.add(InsightModel(
        id: 'offbudget_${now.month}',
        type: InsightType.offBudgetSaved,
        titleKey: 'insight_offbudget_title',
        bodyKey: 'insight_offbudget_body',
        params: {
          'count': '${offBudgetTxs.length}',
          'amount': total.toStringAsFixed(0),
        },
        sentiment: InsightSentiment.tip,
        generatedAt: now,
        isDismissed: false,
        actionRoute: '/transactions',
      ));
    }

    // ── 6. Best spending day ───────────────────────────────────────────────
    final bestDay = _bestDay(expenses);
    if (bestDay != null) {
      insights.add(InsightModel(
        id: 'bestday_${now.month}',
        type: InsightType.bestDay,
        titleKey: 'insight_bestday_title',
        bodyKey: 'insight_bestday_body',
        params: {'day': bestDay},
        sentiment: InsightSentiment.neutral,
        generatedAt: now,
        isDismissed: false,
        actionRoute: null,
      ));
    }

    // Sort by severity and return max 3
    insights.sort((a, b) =>
        _sentimentPriority(a.sentiment).compareTo(_sentimentPriority(b.sentiment)));
    return insights.take(3).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _sentimentPriority(InsightSentiment s) {
    switch (s) {
      case InsightSentiment.critical: return 0;
      case InsightSentiment.warning:  return 1;
      case InsightSentiment.positive: return 2;
      case InsightSentiment.tip:      return 3;
      case InsightSentiment.neutral:  return 4;
    }
  }

  double _weekTotal(List<TransactionModel> txns, int weeksAgo) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + weeksAgo * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return txns
        .where((t) =>
            !t.date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)) &&
            !t.date.isAfter(DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59)))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double _weekCatTotal(
      List<TransactionModel> txns, String catId, int weeksAgo) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + weeksAgo * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return txns
        .where((t) =>
            t.categoryId == catId &&
            !t.date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day)) &&
            !t.date.isAfter(DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59)))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double _avgWeeklyCat(List<TransactionModel> txns, String catId) {
    if (txns.isEmpty) return 0;
    // Use last 4 weeks of data
    double total = 0;
    int weeks = 0;
    for (int i = 1; i <= 4; i++) {
      final w = _weekCatTotal(txns, catId, i);
      if (w > 0) {
        total += w;
        weeks++;
      }
    }
    return weeks > 0 ? total / weeks : 0;
  }

  double _remainingBalance(
      MonthlySession session, List<TransactionModel> txns) {
    final income = txns
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = txns
        .where((t) => t.isExpense && t.affectsBalance)
        .fold(0.0, (s, t) => s + t.amount);
    return session.initialBalance + income - expenses;
  }

  double _dailyAvg(List<TransactionModel> expenses) {
    if (expenses.isEmpty) return 0;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysPassed = now.difference(monthStart).inDays + 1;
    final total = expenses
        .where((t) => !t.date.isBefore(monthStart))
        .fold(0.0, (s, t) => s + t.amount);
    return daysPassed > 0 ? total / daysPassed : 0;
  }

  int _daysLeft(MonthlySession session) {
    final now = DateTime.now();
    final parts = session.month.split('-');
    if (parts.length < 2) return 0;
    final year = int.tryParse(parts[0]) ?? now.year;
    final month = int.tryParse(parts[1]) ?? now.month;
    final lastDay = DateTime(year, month + 1, 0);
    return lastDay.difference(now).inDays.clamp(0, 31);
  }

  int _noSpendStreak(List<TransactionModel> expenses) {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 1; i <= 30; i++) {
      final day = now.subtract(Duration(days: i));
      final hadExpense = expenses.any((t) =>
          t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day);
      if (!hadExpense) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String? _bestDay(List<TransactionModel> expenses) {
    if (expenses.isEmpty) return null;
    final totals = <int, double>{};
    for (final t in expenses) {
      totals[t.date.weekday] = (totals[t.date.weekday] ?? 0) + t.amount;
    }
    if (totals.isEmpty) return null;
    final maxDay = totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[maxDay];
  }

  String _weekKey() {
    final now = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    final week = ((now.difference(jan1).inDays) / 7).ceil();
    return '${now.year}_W$week';
  }
}

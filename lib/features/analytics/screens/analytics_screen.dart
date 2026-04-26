import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/l10n/category_name_localizer.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/balance_calculator.dart';
import '../providers/analytics_providers.dart';
import '../../session/providers/session_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../shared/widgets/empty_state.dart';

/// Analytics screen with two tabs: This Month and History
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('analytics_title')),
          bottom: TabBar(
            tabs: [
              Tab(text: t('analytics_this_month')),
              Tab(text: t('analytics_history')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ThisMonthTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _ThisMonthTab extends ConsumerWidget {
  const _ThisMonthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final analytics = ref.watch(analyticsProvider);
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);
    final categories = ref.watch(categoriesProvider);

    if (session == null) {
      return EmptyState(
        icon: Icons.bar_chart,
        message: t('analytics_no_session'),
        subtitle: t('analytics_no_session_sub'),
      );
    }

    final health = BalanceCalculator.balanceHealth(
      projectedBalance: analytics.projectedBalance,
      initialBalance: analytics.initialBalance,
    );
    Color healthColor;
    switch (health) {
      case 'healthy':
        healthColor = AppColors.healthGreen;
      case 'tight':
        healthColor = AppColors.healthOrange;
      default:
        healthColor = AppColors.healthRed;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI cards row
          _buildKpiRow(analytics, currency, healthColor),
          const SizedBox(height: 20),
          // Pie chart
          if (analytics.expensesByCategory.isNotEmpty) ...[
            Text(t('analytics_spending_by_category'), style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _buildPieChart(analytics, categories, currency, t),
            const SizedBox(height: 20),
          ],
          // Bar chart - daily spending
          Text(t('analytics_daily_spending'), style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          _buildDailyBarChart(analytics, currency, session.month),
          const SizedBox(height: 20),
          // Balance over time line chart
          if (analytics.balanceOverTime.length > 1) ...[
            Text(t('analytics_balance_over_time'), style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            _buildBalanceLineChart(analytics, currency),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow(AnalyticsData analytics, String currency, Color healthColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kpiCard('analytics_remaining', CurrencyFormatter.formatClean(analytics.remainingBalance, symbol: currency), AppColors.primary),
          _kpiCard('income', CurrencyFormatter.formatClean(analytics.totalIncome, symbol: currency), AppColors.incomeGreen),
          _kpiCard('expense', CurrencyFormatter.formatClean(analytics.totalExpenses, symbol: currency), AppColors.expenseRed),
          _kpiCard('analytics_daily_avg', CurrencyFormatter.formatClean(analytics.dailyAverage, symbol: currency), AppColors.warning),
          _kpiCard('projected_balance', CurrencyFormatter.formatClean(analytics.projectedBalance, symbol: currency), healthColor),
          _kpiCard('tx_count', '${analytics.transactionCount}', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _kpiCard(String labelKey, String value, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final t = ref.watch(tProvider);
              return Text(t(labelKey), style: AppTextStyles.kpiLabel);
            },
          ),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.kpiValue.copyWith(color: color, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPieChart(AnalyticsData analytics, List categories, String currency,
      String Function(String) t) {
    final entries = analytics.expensesByCategory.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    final sections = entries.asMap().entries.map((me) {
      final entry = me.value;
      final cat = categories.where((c) => c.id == entry.key).firstOrNull;
      final color = cat != null
          ? Color(cat.color)
          : AppColors.categoryPresetColors[me.key % AppColors.categoryPresetColors.length];
      final pct = total > 0 ? entry.value / total * 100 : 0.0;
      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return SizedBox(
      height: 260,
      child: Row(
        children: [
          Expanded(
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(width: 12),
          // Legend
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((me) {
              final entry = me.value;
              final cat = categories.where((c) => c.id == entry.key).firstOrNull;
              final color = cat != null
                  ? Color(cat.color)
                  : AppColors.categoryPresetColors[me.key % AppColors.categoryPresetColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 6),
                    Text(
                      localizeCategoryName(cat?.name ?? t('cat_other'), t),
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBarChart(AnalyticsData analytics, String currency, String monthKey) {
    final daysInMonth = AppDateUtils.daysInMonth(monthKey);
    final dailyMap = <int, double>{};
    analytics.dailySpending.forEach((date, amount) {
      dailyMap[date.day] = amount;
    });

    final barGroups = List.generate(daysInMonth, (i) {
      final day = i + 1;
      final amount = dailyMap[day] ?? 0.0;
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: AppColors.expenseRed.withAlpha(179),
            width: 6,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });

    return SizedBox(
      height: 180,
      child: BarChart(BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                if (value.toInt() % 5 != 0 && value.toInt() != 1) {
                  return const SizedBox.shrink();
                }
                return Text('${value.toInt()}',
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
              },
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildBalanceLineChart(AnalyticsData analytics, String currency) {
    return SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: analytics.balanceOverTime,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withAlpha(38),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      )),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListProvider);
    final closedSessions = sessions.where((s) => s.isClosed).toList();
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);

    if (closedSessions.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        message: t('analytics_no_history'),
        subtitle: t('analytics_no_history_sub'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: closedSessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final session = closedSessions[i];
        final net = session.finalBalance - session.initialBalance;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.monthKeyToDisplay(session.month),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('initial_balance')}: ${CurrencyFormatter.formatClean(session.initialBalance, symbol: currency)}',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '${t('final_balance')}: ${CurrencyFormatter.formatClean(session.finalBalance, symbol: currency)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (net >= 0 ? AppColors.incomeGreen : AppColors.expenseRed).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${net >= 0 ? '+' : ''}${CurrencyFormatter.formatClean(net, symbol: currency)}',
                      style: AppTextStyles.caption.copyWith(
                        color: net >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/balance_calculator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/session_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/data/transaction_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/insight_card.dart';
import '../../../features/insights/providers/insights_provider.dart';
import '../../../features/gamification/providers/user_stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);
    final isRtl = settings.language == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: session == null
            ? _buildNoSessionState(context, ref, t, isDark)
            : _buildSessionDashboard(context, ref, session, currency, settings.language, t, isDark),
        floatingActionButton: session != null && session.isOpen
            ? _buildFAB(context)
            : null,
      ),
    );
  }

  Widget _buildNoSessionState(BuildContext context, WidgetRef ref,
      String Function(String) t, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(77),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 28),
            Text(t('home_no_session'),
                style: AppTextStyles.pageTitle.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              t('home_no_session_sub'),
              style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: () => context.push('/session/new'),
              icon: const Icon(Icons.add_rounded),
              label: Text(t('home_start_session')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDashboard(BuildContext context, WidgetRef ref,
      session, String currency, String language,
      String Function(String) t, bool isDark) {
    final allTransactions = ref.watch(transactionsProvider);
    final sessionTxs = allTransactions
        .where((tx) => tx.sessionId == session.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome = sessionTxs
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpenses = sessionTxs
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final remaining = BalanceCalculator.remaining(
      initialBalance: session.initialBalance,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
    );
    final burnRate = session.initialBalance > 0
        ? (totalExpenses / session.initialBalance).clamp(0.0, 1.0)
        : 0.0;
    final healthStatus = BalanceCalculator.balanceHealth(
      projectedBalance: BalanceCalculator.projectedBalance(
        currentBalance: remaining,
        totalExpenses: totalExpenses,
        monthKey: session.month,
      ),
      initialBalance: session.initialBalance,
    );

    final recentTxs =
        sessionTxs.take(AppConstants.recentTransactionsCount).toList();

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, ref, session, language, t, isDark),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeroCard(context, remaining, totalIncome, totalExpenses,
                  currency, burnRate, healthStatus, session.isOpen, t, isDark),
              const SizedBox(height: 12),
              _buildGamificationBar(ref, t, isDark),
              const SizedBox(height: 8),
              _buildInsightsSection(ref, t, isDark),
              const SizedBox(height: 4),
              if (session.isClosed) _buildClosedBanner(context, t, isDark),
              _buildBudgetWarning(ref, session.id, t, isDark),
              const SizedBox(height: 4),
              _buildRecentSection(context, ref, recentTxs, currency, session.id, t, isDark),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, WidgetRef ref,
      session, String language, String Function(String) t, bool isDark) {
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDateUtils.getMonthName(session.month, language),
                  style: AppTextStyles.pageTitle.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusPill(session.isOpen, t),
        ],
      ),
      actions: [
        if (session.isOpen)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonal(
              onPressed: () => context.push('/settlement'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withAlpha(26),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(t('home_settle'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusPill(bool isOpen, String Function(String) t) {
    final color = isOpen ? AppColors.incomeGreen : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? t('session_open') : t('session_closed'),
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationBar(WidgetRef ref, String Function(String) t, bool isDark) {
    final stats = ref.watch(userStatsProvider);
    final levelProgress = stats.levelProgress;
    final streak = stats.dailyLogStreak;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Streak pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('$streak', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // XP level bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(stats.levelTitle, style: AppTextStyles.labelSmall.copyWith(color: textPrimary, fontWeight: FontWeight.w600)),
                      Text('${stats.totalXP} XP', style: AppTextStyles.labelSmall.copyWith(color: textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      backgroundColor: AppColors.primary.withAlpha(40),
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(WidgetRef ref, String Function(String) t, bool isDark) {
    final settings = ref.watch(settingsProvider);
    final insights = ref.watch(insightsProvider).where((i) => !i.isDismissed).toList();
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(t('insights_title'),
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              )),
        ),
        SizedBox(
          height: 110,
          child: PageView.builder(
            padEnds: false,
            itemCount: insights.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 16 : 8, right: index == insights.length - 1 ? 16 : 0),
                child: InsightCard(
                  insight: insights[index],
                  language: settings.language,
                  onDismiss: () => ref.read(insightsProvider.notifier).dismiss(insights[index].id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    double remaining,
    double totalIncome,
    double totalExpenses,
    String currency,
    double burnRate,
    String healthStatus,
    bool isOpen,
    String Function(String) t,
    bool isDark,
  ) {
    final isOverBudget = remaining < 0;
    final cardGradient = isOverBudget ? AppColors.expenseGradient : AppColors.primaryGradient;
    final glowColor = isOverBudget ? AppColors.expenseRed : AppColors.primary;

    Color burnColor;
    switch (healthStatus) {
      case 'healthy':
        burnColor = AppColors.healthGreen;
      case 'tight':
        burnColor = AppColors.healthOrange;
      default:
        burnColor = AppColors.healthRed;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glowColor.withAlpha(100),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles — glassmorphism feel
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: [
                // Label
                Text(
                  isOverBudget ? t('over_budget') : t('remaining_balance'),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withAlpha(180),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Big balance number
                Text(
                  CurrencyFormatter.formatClean(remaining.abs(), symbol: currency),
                  style: AppTextStyles.balanceHeroLight,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Burn rate bar
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: burnRate,
                        minHeight: 6,
                        backgroundColor: Colors.white.withAlpha(50),
                        valueColor: AlwaysStoppedAnimation<Color>(burnColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(burnRate * 100).toStringAsFixed(1)}% ${t('home_spent')}',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white.withAlpha(160)),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: burnColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Income / Expense chips row
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildHeroChip(
                          label: t('home_income'),
                          amount: totalIncome,
                          currency: currency,
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.incomeGreen,
                        ),
                      ),
                      Container(
                        width: 1,
                        color: Colors.white.withAlpha(40),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Expanded(
                        child: _buildHeroChip(
                          label: t('home_expenses'),
                          amount: totalExpenses,
                          currency: currency,
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.expenseRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip({
    required String label,
    required double amount,
    required String currency,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white.withAlpha(160))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatClean(amount, symbol: currency),
          style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildClosedBanner(BuildContext context, String Function(String) t,
      bool isDark) {
    final bg = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t('home_closed_view_only'),
                style: AppTextStyles.caption),
          ),
          FilledButton(
            onPressed: () => context.push('/session/new'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: Text(t('new_session')),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetWarning(WidgetRef ref, String sessionId,
      String Function(String) t, bool isDark) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider);

    int overCount = 0;
    for (final cat in categories) {
      if (cat.budgetLimit == null || cat.budgetLimit! <= 0) continue;
      final spent = transactions
          .where((tx) =>
              tx.sessionId == sessionId &&
              tx.categoryId == cat.id &&
              tx.isExpense)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      if (spent >= cat.budgetLimit!) overCount++;
    }

    if (overCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠️  $overCount ${overCount == 1 ? t('category') : t('categories')} ${t('home_over_budget_count')}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context, WidgetRef ref,
      List<TransactionModel> transactions, String currency, String sessionId,
      String Function(String) t, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('home_recent'),
                  style: AppTextStyles.sectionTitle
                      .copyWith(color: textPrimary)),
              TextButton(
                onPressed: () => context.go('/transactions'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                ),
                child: Text(t('home_see_all'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              message: t('home_no_transactions'),
              subtitle: t('home_add_first'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => TransactionTile(
              transaction: transactions[index],
              currency: currency,
              onTap: () => showAddTransactionSheet(context,
                  existingTransaction: transactions[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'add_tx_fab',
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onPressed: () => showAddTransactionSheet(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

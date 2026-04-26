import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../data/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../../session/providers/session_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/add_transaction_sheet.dart';

/// Full transaction list screen with filter, sort and search
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('transactions_title'))),
        body: EmptyState(
            icon: Icons.receipt_long, message: t('transactions_no_session')),
      );
    }

    final filtered =
        ref.watch(filteredTransactionsProvider(session.id));
    final allForSession = ref.watch(transactionsProvider)
        .where((t) => t.sessionId == session.id)
        .toList();

    double totalIncome =
        allForSession.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    double totalExpenses =
        allForSession.where((t) => t.isExpense && t.affectsBalance).fold(0.0, (s, t) => s + t.amount);
    double remaining = session.initialBalance + totalIncome - totalExpenses;

    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in filtered) {
      final key = AppDateUtils.relativeDay(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppDateUtils.getMonthName(session.month, settings.language)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Summary strip
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _kpiChip(t('income'),
                        CurrencyFormatter.formatClean(totalIncome,
                            symbol: currency),
                        AppColors.incomeGreen),
                    const SizedBox(width: 8),
                    _kpiChip(t('expense'),
                        CurrencyFormatter.formatClean(totalExpenses,
                            symbol: currency),
                        AppColors.expenseRed),
                    const SizedBox(width: 8),
                    _kpiChip(t('remaining_balance'),
                        CurrencyFormatter.formatClean(remaining,
                            symbol: currency),
                        AppColors.primary),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: t('transactions_search_full'),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter + Sort bar
          _buildFilterBar(ref, t),
          // List
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: t('transactions_empty'),
                    subtitle: t('transactions_empty_sub'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (ctx, i) {
                      final key = sortedKeys[i];
                      final dayTxs = grouped[key]!;
                      final dayTotal = dayTxs.fold(
                          0.0,
                          (s, t) =>
                              s + (t.isExpense ? -t.amount : t.amount));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day header
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(key,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary)),
                                Text(
                                  CurrencyFormatter.formatClean(
                                      dayTotal.abs(),
                                      symbol: currency),
                                  style: AppTextStyles.caption.copyWith(
                                    color: dayTotal >= 0
                                        ? AppColors.incomeGreen
                                        : AppColors.expenseRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...dayTxs.map((tx) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TransactionTile(
                                  transaction: tx,
                                  currency: currency,
                                  onTap: session.isOpen
                                      ? () => _editTx(context, tx,
                                          session.id, currency)
                                      : null,
                                ),
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kpiChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(color: color)),
            Text(value,
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(WidgetRef ref, String Function(String) t) {
    final filter = ref.watch(transactionFilterProvider);
    ref.watch(transactionSortProvider); // used in PopupMenuButton onSelected

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TransactionFilter.values.map((f) {
                  final isActive = filter == f;
                  final label = switch (f) {
                    TransactionFilter.all => t('transactions_all'),
                    TransactionFilter.income => t('transactions_income'),
                    TransactionFilter.expense => t('transactions_expense'),
                    TransactionFilter.offBudget => t('off_budget_filter'),
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isActive,
                      onSelected: (_) =>
                          ref.read(transactionFilterProvider.notifier).state = f,
                      selectedColor: AppColors.primary.withAlpha(51),
                      labelStyle: AppTextStyles.chip.copyWith(
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          PopupMenuButton<TransactionSort>(
            icon: const Icon(Icons.sort, size: 20),
            onSelected: (v) =>
                ref.read(transactionSortProvider.notifier).state = v,
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: TransactionSort.newest,
                  child: Text(t('transactions_sort_newest'))),
              PopupMenuItem(
                  value: TransactionSort.oldest,
                  child: Text(t('transactions_sort_oldest'))),
              PopupMenuItem(
                  value: TransactionSort.highest,
                  child: Text(t('transactions_sort_highest'))),
            ],
          ),
        ],
      ),
    );
  }

  void _editTx(BuildContext context, TransactionModel tx, String sessionId,
      String currency) {
    showAddTransactionSheet(context, existingTransaction: tx);
  }
}

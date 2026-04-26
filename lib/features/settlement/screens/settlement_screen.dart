import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/category_name_localizer.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../session/providers/session_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../savings/data/saving_model.dart';
import '../../savings/providers/savings_providers.dart';
import 'package:uuid/uuid.dart';

/// 3-step settlement flow for closing a monthly session
class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  int _step = 0; // 0=summary, 1=options, 2=confirm
  int _selectedOption = 0; // 0=carry, 1=save, 2=split, 3=reset
  double _splitRatio = 0.5; // For split option
  bool _isProcessing = false;

  static final _uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('settlement_screen_title'))),
        body: Center(child: Text(t('settlement_no_session'))),
      );
    }

    final allTxs = ref.watch(transactionsProvider);
    final sessionTxs = allTxs.where((t) => t.sessionId == session.id).toList();
    final totalIncome =
        sessionTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpenses =
        sessionTxs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final finalBalance =
        session.initialBalance + totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('settlement_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _step == 0
            ? _buildSummaryStep(session, totalIncome, totalExpenses,
                finalBalance, currency, settings.language, t)
            : _step == 1
                ? _buildOptionsStep(finalBalance, currency, t)
                : _buildConfirmStep(
                    session, finalBalance, currency, totalIncome, totalExpenses, t),
      ),
    );
  }

  Widget _buildSummaryStep(session, double totalIncome, double totalExpenses,
      double finalBalance, String currency, String language,
      String Function(String) t) {
    final categories = ref.watch(categoriesProvider);
    final allTxs = ref.watch(transactionsProvider);
    final sessionTxs = allTxs.where((t) => t.sessionId == session.id).toList();

    // Top 3 categories
    final expenseMap = <String, double>{};
    for (final tx in sessionTxs.where((t) => t.isExpense)) {
      expenseMap[tx.categoryId] = (expenseMap[tx.categoryId] ?? 0) + tx.amount;
    }
    final top3 = expenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = top3.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month name
          Text(
            AppDateUtils.getMonthName(session.month, language),
            style: AppTextStyles.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Summary cards
          _summaryRow(t('initial_balance'),
              CurrencyFormatter.formatClean(session.initialBalance, symbol: currency),
              AppColors.textSecondary),
          _summaryRow(t('analytics_total_income'),
              '+${CurrencyFormatter.formatClean(totalIncome, symbol: currency)}',
              AppColors.incomeGreen),
          _summaryRow(t('analytics_total_expenses'),
              '-${CurrencyFormatter.formatClean(totalExpenses, symbol: currency)}',
              AppColors.expenseRed),
          const Divider(height: 24),
          _summaryRow(
            t('remaining_balance'),
            CurrencyFormatter.formatClean(finalBalance, symbol: currency),
            finalBalance >= 0 ? AppColors.primary : AppColors.expenseRed,
            isBold: true,
          ),
          _summaryRow(t('transactions_title'), '${sessionTxs.length}', AppColors.textSecondary),
          const SizedBox(height: 24),
          // Top categories
          if (topEntries.isNotEmpty) ...[
            Text(t('settlement_top_categories'), style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            ...topEntries.map((e) {
              final cat = categories.where((c) => c.id == e.key).firstOrNull;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(localizeCategoryName(cat?.name ?? t('cat_unknown'), t),
                        style: AppTextStyles.body),
                    Text(
                      CurrencyFormatter.formatClean(e.value, symbol: currency),
                      style: AppTextStyles.amountExpense,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: Text('${t('settlement_choose_option')} →'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: isBold ? AppTextStyles.bodyMedium : AppTextStyles.body),
          Text(value,
              style: (isBold ? AppTextStyles.kpiValue : AppTextStyles.bodyMedium)
                  .copyWith(color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildOptionsStep(
      double finalBalance, String currency, String Function(String) t) {
    final carryAmount = finalBalance * _splitRatio;
    final saveAmount = finalBalance * (1 - _splitRatio);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t('settlement_choose'),
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          Text(
            CurrencyFormatter.formatClean(finalBalance, symbol: currency),
            style: AppTextStyles.kpiValue.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            index: 0,
            title: '🔄 ${t('settlement_carry')}',
            description: t('carry_over_desc'),
            detail: CurrencyFormatter.formatClean(finalBalance, symbol: currency),
          ),
          _buildOptionCard(
            index: 1,
            title: '💰 ${t('settlement_save')}',
            description: t('save_to_savings_desc'),
            detail: CurrencyFormatter.formatClean(finalBalance, symbol: currency),
          ),
          _buildOptionCard(
            index: 2,
            title: '⚖️ ${t('settlement_split')}',
            description: t('split_desc'),
            detail: null,
            extra: _selectedOption == 2
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      Slider(
                        value: _splitRatio,
                        onChanged: (v) => setState(() => _splitRatio = v),
                        activeColor: AppColors.primary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${t('carry_label')}: ${CurrencyFormatter.formatClean(carryAmount, symbol: currency)}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary),
                          ),
                          Text(
                            '${t('save_label')}: ${CurrencyFormatter.formatClean(saveAmount, symbol: currency)}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.incomeGreen),
                          ),
                        ],
                      ),
                    ],
                  )
                : null,
          ),
          _buildOptionCard(
            index: 3,
            title: '🔁 ${t('settlement_reset')}',
            description: t('settlement_reset_desc'),
            detail: t('settlement_discarded'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  child: Text('← ${t('back')}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = 2),
                  child: Text('${t('settlement_review')} →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required int index,
    required String title,
    required String description,
    String? detail,
    Widget? extra,
  }) {
    final isSelected = _selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      )),
                ),
                if (detail != null)
                  Text(detail,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                const SizedBox(width: 4),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
            Text(description, style: AppTextStyles.caption),
            if (extra != null && isSelected) extra,
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmStep(session, double finalBalance, String currency,
    double totalIncome, double totalExpenses, String Function(String) t) {
    final carryAmount = _selectedOption == 2
        ? finalBalance * _splitRatio
        : _selectedOption == 0
            ? finalBalance
            : 0.0;
    final saveAmount = _selectedOption == 2
        ? finalBalance * (1 - _splitRatio)
        : _selectedOption == 1
            ? finalBalance
            : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 64, color: AppColors.incomeGreen),
          const SizedBox(height: 16),
          Text(t('settlement_confirm_title'), style: AppTextStyles.sectionTitle,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  _optionSummary(finalBalance, currency, carryAmount, saveAmount, t),
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                if (carryAmount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${t('carry_over')}: ${CurrencyFormatter.formatClean(carryAmount, symbol: currency)}',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                ],
                if (saveAmount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t('save_label')}: ${CurrencyFormatter.formatClean(saveAmount, symbol: currency)}',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.incomeGreen),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _confirmSettlement(
                    session, finalBalance, carryAmount, saveAmount, currency),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.incomeGreen,
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : Text('✅ ${t('confirm_settlement')}'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _step = 1),
            child: Text('← ${t('settlement_change_option')}'),
          ),
        ],
      ),
    );
  }

  String _optionSummary(double finalBalance, String currency,
      double carryAmount, double saveAmount, String Function(String) t) {
    switch (_selectedOption) {
      case 0:
        return '${t('carry_over_desc')}: ${CurrencyFormatter.formatClean(finalBalance, symbol: currency)}';
      case 1:
        return '${t('save_to_savings_desc')}: ${CurrencyFormatter.formatClean(finalBalance, symbol: currency)}';
      case 2:
        return '${t('split_desc')}: ${CurrencyFormatter.formatClean(carryAmount, symbol: currency)} / ${CurrencyFormatter.formatClean(saveAmount, symbol: currency)}';
      case 3:
        return t('settlement_reset_desc');
      default:
        return '';
    }
  }

  Future<void> _confirmSettlement(session, double finalBalance,
      double carryAmount, double saveAmount, String currency) async {
    setState(() => _isProcessing = true);
    try {
      // Close the current session
      await ref.read(sessionListProvider.notifier).closeSession(
            sessionId: session.id,
            finalBalance: finalBalance,
          );

      // Handle savings
      if (saveAmount > 0) {
        final saving = SavingModel(
          id: _uuid.v4(),
          amount: saveAmount,
          date: DateTime.now(),
          sourceSessionId: session.id,
          note: 'Settlement from ${AppDateUtils.getMonthName(session.month, ref.read(settingsProvider).language)}',
        );
        await ref.read(savingsProvider.notifier).addSaving(saving);
      }

      // Navigate to new session or home
      if (mounted) {
        if (carryAmount > 0) {
          context.go('/session/new', extra: carryAmount);
        } else {
          context.go('/');
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

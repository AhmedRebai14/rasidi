import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../providers/savings_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../shared/widgets/empty_state.dart';

/// Savings ledger screen
class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = ref.watch(savingsProvider);
    final total = ref.watch(totalSavingsProvider);
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('savings_title'))),
      body: Column(
        children: [
          // Hero total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.incomeGreen, AppColors.incomeGreen.withAlpha(179)],
              ),
            ),
            child: Column(
              children: [
                Text(t('savings_total'),
                    style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.formatClean(total, symbol: currency),
                  style: AppTextStyles.balanceHeroLight,
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: savings.isEmpty
                ? EmptyState(
                    icon: Icons.savings_outlined,
                    message: t('savings_empty'),
                    subtitle: t('savings_empty_sub'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: savings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final saving = savings[i];
                      double running = 0;
                      for (int j = savings.length - 1; j >= i; j--) {
                        running += savings[j].amount;
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.incomeGreen.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.savings,
                                  color: AppColors.incomeGreen, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppDateUtils.formatFull(saving.date),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  if (saving.note != null &&
                                      saving.note!.isNotEmpty)
                                    Text(saving.note!,
                                        style: AppTextStyles.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${t('savings_cumulative')}: ${CurrencyFormatter.formatClean(running, symbol: currency)}',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${CurrencyFormatter.formatClean(saving.amount, symbol: currency)}',
                              style: AppTextStyles.amountIncome,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

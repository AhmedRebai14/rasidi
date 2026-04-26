import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/category_name_localizer.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../features/transactions/data/transaction_model.dart';
import '../../features/categories/providers/category_providers.dart';
import '../../core/utils/icon_resolver.dart';

/// A single transaction list item — tap to edit
class TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;
  final String currency;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategories = ref.watch(categoriesProvider);
    final t = ref.watch(tProvider);
    // Also look in the full box for archived categories
    final category = allCategories
        .where((c) => c.id == transaction.categoryId)
        .firstOrNull;

    final catColor = category != null
        ? Color(category.color)
        : AppColors.textSecondary;
    final catIcon = category != null
        ? IconResolver.resolve(category.icon)
        : Icons.category;
  final catName = localizeCategoryName(category?.name ?? t('cat_unknown'), t);

    final isExpense = transaction.isExpense;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Rounded square category icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: catColor.withAlpha(28),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(catIcon, color: catColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(catName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (transaction.isRecurring) ...[
                        const SizedBox(width: 5),
                        Icon(Icons.repeat_rounded,
                            size: 13, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.note != null && transaction.note!.isNotEmpty
                        ? transaction.note!
                        : AppDateUtils.formatDay(transaction.date),
                    style:
                        AppTextStyles.caption.copyWith(color: textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount + time column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isExpense ? '-' : '+'}${CurrencyFormatter.formatClean(transaction.amount, symbol: currency)}',
                      style: (isExpense
                              ? AppTextStyles.amountExpense
                              : AppTextStyles.amountIncome)
                          .copyWith(fontSize: 15),
                    ),
                    if (isExpense && !transaction.affectsBalance) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.incomeGreen.withAlpha(38),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.incomeGreen.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          t('off_budget_badge'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.incomeGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateUtils.formatTime(transaction.date),
                  style: AppTextStyles.caption.copyWith(color: textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

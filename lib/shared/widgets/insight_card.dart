import 'package:flutter/material.dart';
import '../../core/l10n/app_translations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/insights/data/insight_model.dart';

/// Color map for insight sentiment
Color sentimentColor(InsightSentiment s) {
  switch (s) {
    case InsightSentiment.positive: return const Color(0xFF22c55e);
    case InsightSentiment.warning:  return const Color(0xFFf97316);
    case InsightSentiment.critical: return const Color(0xFFef4444);
    case InsightSentiment.neutral:  return const Color(0xFF3b82f6);
    case InsightSentiment.tip:      return const Color(0xFF0891b2);
  }
}

IconData _sentimentIcon(InsightType type) {
  switch (type) {
    case InsightType.weekOverWeek:     return Icons.trending_up_rounded;
    case InsightType.categorySpike:    return Icons.warning_amber_rounded;
    case InsightType.paceWarning:      return Icons.speed_rounded;
    case InsightType.pacePositive:     return Icons.celebration_rounded;
    case InsightType.noSpendStreak:    return Icons.local_fire_department_rounded;
    case InsightType.biggestExpense:   return Icons.receipt_long_rounded;
    case InsightType.offBudgetSaved:   return Icons.card_giftcard_rounded;
    case InsightType.incomeGap:        return Icons.account_balance_wallet_rounded;
    case InsightType.unusualTransaction: return Icons.bolt_rounded;
    case InsightType.bestDay:          return Icons.calendar_today_rounded;
  }
}

class InsightCard extends StatelessWidget {
  final InsightModel insight;
  final String language;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.insight,
    required this.language,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = sentimentColor(insight.sentiment);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    String title = AppTranslations.t(insight.titleKey, language);
    String body = AppTranslations.t(insight.bodyKey, language);
    insight.params.forEach((k, v) {
      title = title.replaceAll('{$k}', v);
      body = body.replaceAll('{$k}', v);
    });

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_sentimentIcon(insight.type), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: textPrimary, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(body,
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Dismiss
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

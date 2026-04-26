import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/balance_calculator.dart';

/// Hero balance card widget for dashboard
class BalanceCard extends ConsumerWidget {
  final double remainingBalance;
  final double initialBalance;
  final double totalExpenses;
  final String monthKey;
  final String currency;

  const BalanceCard({
    super.key,
    required this.remainingBalance,
    required this.initialBalance,
    required this.totalExpenses,
    required this.monthKey,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projected = BalanceCalculator.projectedBalance(
      currentBalance: remainingBalance,
      totalExpenses: totalExpenses,
      monthKey: monthKey,
    );
    final health = BalanceCalculator.balanceHealth(
      projectedBalance: projected,
      initialBalance: initialBalance,
    );
    final burnRate = initialBalance > 0
        ? (totalExpenses / initialBalance).clamp(0.0, 1.0)
        : 0.0;

    Color healthColor;
    switch (health) {
      case 'healthy':
        healthColor = AppColors.healthGreen;
      case 'tight':
        healthColor = AppColors.healthOrange;
      default:
        healthColor = AppColors.healthRed;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Remaining Balance',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatClean(remainingBalance, symbol: currency),
            style: AppTextStyles.balanceHeroLight,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: burnRate,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              burnRate < 0.5
                  ? Colors.greenAccent
                  : burnRate < 0.8
                      ? Colors.orangeAccent
                      : Colors.redAccent,
            ),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(burnRate * 100).toStringAsFixed(1)}% spent',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: healthColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: healthColor.withAlpha(128)),
                ),
                child: Text(
                  'Projected: ${CurrencyFormatter.formatClean(projected, symbol: currency)}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

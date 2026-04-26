import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography system for Rasidi — Modern Fintech Design
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle balanceHero = TextStyle(
    fontSize: 46, fontWeight: FontWeight.w800,
    color: AppColors.primary, letterSpacing: -2,
  );
  static const TextStyle balanceHeroLight = TextStyle(
    fontSize: 46, fontWeight: FontWeight.w800,
    color: Colors.white, letterSpacing: -2,
  );
  static const TextStyle pageTitle = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.8,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.2,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.normal,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.normal,
    color: AppColors.textSecondary, height: 1.4,
  );
  static const TextStyle captionBold = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
  static const TextStyle amountIncome = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: AppColors.incomeGreen, letterSpacing: -0.3,
  );
  static const TextStyle amountExpense = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: AppColors.expenseRed, letterSpacing: -0.3,
  );
  static const TextStyle amountLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textSecondary, letterSpacing: 0.8,
  );
  static const TextStyle chip = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
  static const TextStyle monthHeader = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle kpiValue = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle kpiLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.2,
  );
  static const TextStyle button = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}

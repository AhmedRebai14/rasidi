import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/session_providers.dart';
import '../../settings/providers/settings_providers.dart';

class NewSessionScreen extends ConsumerStatefulWidget {
  final double? carryOverBalance;
  const NewSessionScreen({super.key, this.carryOverBalance});
  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final _balanceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.carryOverBalance != null) {
      _balanceController.text = widget.carryOverBalance!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final t = ref.read(tProvider);
    final amount = double.tryParse(_balanceController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('new_session_invalid_balance'))),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final monthKey = AppDateUtils.currentMonthKey;
      final result = await ref
          .read(sessionListProvider.notifier)
          .startSession(month: monthKey, initialBalance: amount);
      if (result != null && mounted) {
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('new_session_fail'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.language == 'ar';
    final currentMonth = AppDateUtils.monthKeyToDisplay(
      AppDateUtils.currentMonthKey,
      arabic: isRtl,
    );
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            t('new_session_title'),
            style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
            color: textSecondary,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              24, 16, 24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight - 56,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.calendar_month_rounded, size: 44, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentMonth,
                      style: AppTextStyles.pageTitle.copyWith(color: textPrimary, fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('new_session_balance_hint'),
                      style: AppTextStyles.body.copyWith(color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark ? null : [
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: TextField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.kpiValue.copyWith(
                          fontSize: 36, color: AppColors.primary, letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: AppTextStyles.kpiValue.copyWith(
                            fontSize: 36, color: AppColors.primary.withAlpha(60), letterSpacing: -1,
                          ),
                          suffixText: ref.watch(localizedCurrencyProvider),
                          suffixStyle: AppTextStyles.sectionTitle.copyWith(color: textSecondary),
                          labelText: t('new_session_balance_label'),
                          labelStyle: AppTextStyles.caption.copyWith(color: textSecondary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (widget.carryOverBalance != null) ...[ 
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.incomeGreen.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.incomeGreen.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.savings_outlined, color: AppColors.incomeGreen, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                t('new_session_carry_note')
                                    .replaceAll('{amount}', widget.carryOverBalance!.toStringAsFixed(2))
                                    .replaceAll('{currency}', ref.watch(localizedCurrencyProvider)),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.incomeGreen, fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _startSession,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withAlpha(80),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                        label: Text(
                          t('new_session_start'),
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

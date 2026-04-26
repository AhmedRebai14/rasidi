import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../shared/services/hive_service.dart';
// setAppLocked drives GoRouter's ValueNotifier-based redirect
import '../../../core/router/app_router.dart' show setAppLocked;

// ── Lock state provider ────────────────────────────────────────────────────

/// True when the app is currently locked (PIN required)
final appLockedProvider = StateProvider<bool>((ref) => false);

// ── Lock Screen Widget ─────────────────────────────────────────────────────

class LockScreen extends ConsumerStatefulWidget {
  /// If true, user is setting a new PIN (not unlocking)
  final bool isSettingPin;

  const LockScreen({super.key, this.isSettingPin = false});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxAttempts = 3;
  static const int _cooldownSeconds = 30;

  String _enteredPin = '';
  String? _firstPin; // used only when isSettingPin=true
  bool _isConfirmStep = false;
  int _failedAttempts = 0;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;
  bool _shaking = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _shakeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeCtrl.reset();
        setState(() {
          _shaking = false;
          _enteredPin = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── PIN input ─────────────────────────────────────────────────────────

  void _onKey(String digit) {
    if (_cooldownRemaining > 0) return;
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _enteredPin += digit);
    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 80), _verify);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
  }

  void _verify() {
    if (widget.isSettingPin) {
      _handleSetPin();
    } else {
      _handleUnlock();
    }
  }

  void _handleUnlock() {
    final storedPin = ref.read(settingsProvider).pin ?? '';
    if (_enteredPin == storedPin) {
      // ✅ Correct — clear lock state and navigate home
      HapticFeedback.mediumImpact();
      setAppLocked(false); // tell GoRouter to lift the /lock redirect
      ref.read(appLockedProvider.notifier).state = false;
      context.go('/');
    } else {
      // ❌ Wrong
      HapticFeedback.heavyImpact();
      _failedAttempts++;
      _triggerShake();
      if (_failedAttempts >= _maxAttempts) {
        _startCooldown();
      }
    }
  }

  void _handleSetPin() {
    if (!_isConfirmStep) {
      // First entry — store and move to confirm
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirmStep = true;
      });
    } else {
      // Confirm entry
      if (_enteredPin == _firstPin) {
        // Save PIN
        ref.read(settingsProvider.notifier).setPinEnabled(true, pin: _enteredPin);
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        final t = ref.read(tProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('pin_set_success'))),
        );
      } else {
        // Mismatch — restart
        _triggerShake();
        setState(() {
          _firstPin = null;
          _isConfirmStep = false;
        });
      }
    }
  }

  void _triggerShake() {
    setState(() => _shaking = true);
    _shakeCtrl.forward();
  }

  void _startCooldown() {
    setState(() => _cooldownRemaining = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _cooldownRemaining--;
        if (_cooldownRemaining <= 0) {
          _cooldownTimer?.cancel();
          _failedAttempts = 0;
        }
      });
    });
  }

  void _showForgotPinDialog() {
    final t = ref.read(tProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('forgot_pin')),
        content: Text(t('forgot_pin_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed),
            onPressed: () async {
              Navigator.pop(context);
              await HiveService.clearAll();
              if (mounted) context.go('/onboarding');
            },
            child: Text(t('erase_and_reset')),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final onBg = Theme.of(context).colorScheme.onSurface;

    String subtitle;
    if (widget.isSettingPin) {
      subtitle = _isConfirmStep ? t('confirm_pin') : t('set_pin');
    } else {
      subtitle = t('enter_pin');
    }

    return PopScope(
      // In unlock mode the back button must be blocked — user cannot escape the lock screen.
      // In isSettingPin mode (shown from Settings) we allow pop so the sheet can close.
      canPop: widget.isSettingPin,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo ─────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'ر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rasidi',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 22,
                  color: onBg,
                ),
              ),
              const SizedBox(height: 32),

              // ── Subtitle ──────────────────────────────────────
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: onBg.withAlpha(180),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // ── PIN dots ──────────────────────────────────────
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) {
                  final offset =
                      _shaking ? (8 * (0.5 - _shakeAnim.value).abs() * 4) : 0.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _enteredPin.length;
                    final isError = _shaking && filled;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isError
                            ? AppColors.expenseRed
                            : filled
                                ? AppColors.primary
                                : Colors.transparent,
                        border: Border.all(
                          color: isError
                              ? AppColors.expenseRed
                              : filled
                                  ? AppColors.primary
                                  : onBg.withAlpha(100),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // ── Cooldown message ──────────────────────────────
              if (_cooldownRemaining > 0) ...[
                const SizedBox(height: 16),
                Text(
                  '${t('too_many_attempts')} ${t('try_again_in')} $_cooldownRemaining ${t('seconds')}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.expenseRed),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(flex: 1),

              // ── Numpad ────────────────────────────────────────
              _buildNumpad(isDark),

              const SizedBox(height: 24),

              // ── Forgot PIN link (unlock mode only) ────────────
              if (!widget.isSettingPin)
                TextButton(
                  onPressed: _showForgotPinDialog,
                  child: Text(
                    t('forgot_pin'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

              const Spacer(flex: 1),
            ],         // Column.children
          ),           // Column
        ),             // Padding
      ),               // SafeArea
    ),                 // Scaffold  ← child of PopScope
  );                   // PopScope
  }                    // end build

  Widget _buildNumpad(bool isDark) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 64);
            final isBackspace = key == '⌫';
            return Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                width: 80,
                height: 64,
                child: Material(
                  color: isDark
                      ? AppColors.darkSurface2
                      : AppColors.lightSurface2,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isBackspace ? _onBackspace : () => _onKey(key),
                    child: Center(
                      child: isBackspace
                          ? const Icon(Icons.backspace_outlined, size: 22)
                          : Text(
                              key,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

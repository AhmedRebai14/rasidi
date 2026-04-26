import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Reusable PIN entry pad — dots + numpad.
///
/// Access via [GlobalKey<PinPadState>] to call [shakeAndClear()] when the
/// parent detects a wrong PIN.
///
/// Example:
/// ```dart
/// final _key = GlobalKey<PinPadState>();
/// PinPad(key: _key, title: 'Enter PIN', onComplete: (pin) { ... });
/// // On wrong PIN:
/// _key.currentState?.shakeAndClear();
/// ```
class PinPad extends StatefulWidget {
  final String title;
  final String? errorText;
  final void Function(String pin) onComplete;

  const PinPad({
    super.key,
    required this.title,
    required this.onComplete,
    this.errorText,
  });

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _pin = '';
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
        setState(() => _pin = '');
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  /// Shake the dots and clear the entered PIN.
  void shakeAndClear() => _shakeCtrl.forward(from: 0);

  /// Silently clear without shaking (e.g. after advancing a step).
  void clear() => setState(() => _pin = '');

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      // Small delay so last dot animates in before callback
      Future.delayed(const Duration(milliseconds: 80), () {
        final pin = _pin;
        widget.onComplete(pin);
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title ────────────────────────────────────────────
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // ── Dots (with shake) ────────────────────────────────
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) {
            final offset = sin(_shakeAnim.value * pi * 6) * 10;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _pin.length;
              final hasError = widget.errorText != null;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasError && filled
                      ? AppColors.expenseRed
                      : filled
                          ? AppColors.primary
                          : Colors.transparent,
                  border: Border.all(
                    color: hasError && filled
                        ? AppColors.expenseRed
                        : filled
                            ? AppColors.primary
                            : onSurface.withAlpha(100),
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Error text (animated in/out) ─────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: widget.errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      color: AppColors.expenseRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 28),

        // ── Numpad ────────────────────────────────────────────
        _buildNumpad(isDark, onSurface),
      ],
    );
  }

  Widget _buildNumpad(bool isDark, Color onSurface) {
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
                    onTap: key == '⌫' ? _onBackspace : () => _onKey(key),
                    child: Center(
                      child: key == '⌫'
                          ? Icon(
                              Icons.backspace_outlined,
                              size: 22,
                              color: onSurface.withAlpha(153),
                            )
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Large amount input widget with quick-amount chips
class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const AmountInput({
    super.key,
    required this.controller,
    required this.currency,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large amount text field
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          onChanged: onChanged,
          style: AppTextStyles.balanceHero.copyWith(
            fontSize: 40,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            hintText: '0.00',
            hintStyle: AppTextStyles.balanceHero.copyWith(
              fontSize: 40,
              color: AppColors.textHint,
            ),
            suffixText: currency,
            suffixStyle: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Quick amount chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppConstants.quickAmounts.map((amount) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text('+${amount.toInt()}'),
                  onPressed: () {
                    final current =
                        double.tryParse(controller.text) ?? 0;
                    controller.text =
                        (current + amount).toStringAsFixed(2);
                    onChanged?.call(controller.text);
                  },
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: AppTextStyles.chip,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

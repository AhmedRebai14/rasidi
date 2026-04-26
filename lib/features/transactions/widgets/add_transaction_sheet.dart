import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/l10n/category_name_localizer.dart';
import '../../analytics/providers/analytics_providers.dart';
import '../../categories/data/category_model.dart';
import '../../categories/providers/category_providers.dart';
import '../../session/providers/session_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../../../core/utils/icon_resolver.dart';

// ─── Entry point ────────────────────────────────────────────────────────────

/// Convenience function — call this from any screen.
void showAddTransactionSheet(
  BuildContext context, {
  TransactionType initialType = TransactionType.expense,
  TransactionModel? existingTransaction,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => AddTransactionSheet(
      initialType: initialType,
      existingTransaction: existingTransaction,
    ),
  );
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final TransactionModel? existingTransaction;

  const AddTransactionSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.existingTransaction,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────
  late TransactionType _type;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController(text: '');
  final _amountFocusNode = FocusNode();
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();
  bool _isRecurring = false;
  RecurringInterval _recurringInterval = RecurringInterval.monthly;
  String? _receiptImagePath;
  bool _isSaving = false;
  bool _showCategoryError = false;
  bool _affectsBalance = true;

  // ── Animation ─────────────────────────────────────────────────────────
  late AnimationController _warningAnimCtrl;
  late Animation<double> _warningSlide;

  // ── Helpers ────────────────────────────────────────────────────────────
  static const _uuid = Uuid();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      // Edit mode — pre-fill all fields
      _type = existing.type;
      _amountController.text = existing.amount % 1 == 0
          ? existing.amount.toInt().toString()
          : existing.amount.toString();
      _selectedCategoryId = existing.categoryId;
      _selectedDate = existing.date;
      _noteController.text = existing.note ?? '';
      _isRecurring = existing.isRecurring;
      _recurringInterval =
          existing.recurringInterval ?? RecurringInterval.monthly;
      _receiptImagePath = existing.receiptImagePath;
      _affectsBalance = existing.affectsBalance;
    } else {
      _type = widget.initialType;
    }

    _warningAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _warningSlide = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: _warningAnimCtrl, curve: Curves.easeOut),
    );

    // Re-evaluate warning whenever amount changes
    _amountController.addListener(() {
      setState(() {
        if (_exceedsBalance) {
          _warningAnimCtrl.forward();
        } else {
          _warningAnimCtrl.reverse();
        }
      });
    });

    // Pre-select last used category after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lastId = ref.read(settingsProvider).lastCategoryUsedId;
      if (lastId != null && mounted) {
        final cats = ref.read(categoriesProvider);
        final match = cats.where((c) => c.id == lastId && c.type == _type);
        if (match.isNotEmpty) {
          setState(() => _selectedCategoryId = lastId);
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _warningAnimCtrl.dispose();
    super.dispose();
  }

  // ── Computed ────────────────────────────────────────────────────────────

  double get _parsedAmount {
    final v = double.tryParse(_amountController.text);
    return v ?? 0.0;
  }

  bool get _amountIsZero => _parsedAmount == 0.0;

  bool get _exceedsBalance {
    if (_type == TransactionType.income) return false;
    final analytics = ref.read(analyticsProvider);
    return _parsedAmount > analytics.remainingBalance;
  }

  Color get _accentColor =>
      _type == TransactionType.expense ? AppColors.expenseRed : AppColors.incomeGreen;

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final session = ref.read(activeSessionProvider);
    DateTime firstDate;
    DateTime lastDate;

    if (session != null) {
      final parts = session.month.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      firstDate = DateTime(year, month, 1);
      lastDate = DateTime(year, month + 1, 0); // last day of month
    } else {
      firstDate = DateTime(2020);
      lastDate = DateTime(2030);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(lastDate)
          ? lastDate
          : _selectedDate.isBefore(firstDate)
              ? firstDate
              : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Receipt photo ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (picked != null) setState(() => _receiptImagePath = picked.path);
    } catch (e) {
      if (mounted) {
        final t = ref.read(tProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('err_camera'))),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    final t = ref.read(tProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(t('add_tx_camera')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(t('add_tx_gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage() {
    if (_receiptImagePath == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.file(File(_receiptImagePath!), fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final t = ref.read(tProvider);
    // Validate amount
    if (_amountIsZero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('err_enter_amount'))),
      );
      return;
    }

    // Validate category
    if (_selectedCategoryId == null) {
      setState(() => _showCategoryError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('err_select_category'))),
      );
      return;
    }

    final session = ref.read(activeSessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('err_no_session'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isEditing = widget.existingTransaction != null;

      final transaction = TransactionModel(
        id: isEditing ? widget.existingTransaction!.id : _uuid.v4(),
        amount: _parsedAmount,
        type: _type,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        sessionId: session.id,
        isRecurring: _isRecurring,
        recurringInterval: _isRecurring ? _recurringInterval : null,
        receiptImagePath: _receiptImagePath,
        affectsBalance: _type == TransactionType.income ? true : _affectsBalance,
      );

      final bool success;
      if (isEditing) {
        success = await ref
            .read(transactionsProvider.notifier)
            .updateTransaction(transaction);
      } else {
        success =
            await ref.read(transactionsProvider.notifier).addTransaction(transaction);
      }

      if (!success) throw Exception(t('err_save'));

      // Save last used category
      await ref
          .read(settingsProvider.notifier)
          .setLastCategoryUsed(_selectedCategoryId!);

      if (mounted) {
        Navigator.pop(context);
        final String snackLabel;
        if (isEditing) {
          snackLabel = t('tx_updated');
        } else {
          snackLabel = _type == TransactionType.expense
              ? t('tx_added_expense')
              : t('tx_added_income');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackLabel),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('err_save')}: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag handle ─────────────────────────────────────────
          _buildDragHandle(t),

          // ── Type toggle ─────────────────────────────────────────
          _buildTypeToggle(t),

          // ── Scrollable content ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount display
                  _buildAmountDisplay(t),

                  // Warning banner
                  _buildWarningBanner(t),

                  const Divider(height: 1),

                  // Category row
                  _buildCategoryRow(t),

                  const Divider(height: 1),

                  // Off-budget toggle (expense only)
                  if (_type == TransactionType.expense) ...[
                    _buildAffectsBalanceToggle(t),
                    const Divider(height: 1),
                  ],

                  // Description field
                  _buildDescriptionField(t),

                  const Divider(height: 1),

                  // Date picker
                  _buildDateRow(t),

                  const Divider(height: 1),

                  // Receipt photo
                  _buildReceiptRow(t),

                  const Divider(height: 1),

                  // Recurring toggle
                  _buildRecurringRow(t),

                  const SizedBox(height: 8),

                  // Save button
                  _buildSaveButton(t),

                  // Bottom padding for safe area
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).padding.bottom +
                        16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildDragHandle(String Function(String) t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingTransaction != null;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? t('edit_tx_title') : t('add_tx_title'),
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(String Function(String) t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(child: _typeButton(TransactionType.expense, t('transactions_expense'))),
            Expanded(child: _typeButton(TransactionType.income, t('transactions_income'))),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(TransactionType type, String label) {
    final isSelected = _type == type;
    final color = type == TransactionType.expense
        ? AppColors.expenseRed
        : AppColors.incomeGreen;

    return GestureDetector(
      onTap: () {
        if (_type == type) return;
        HapticFeedback.selectionClick();
        setState(() {
          _type = type;
          _selectedCategoryId = null;
          _showCategoryError = false;
          _warningAnimCtrl.reverse();
          if (type == TransactionType.income) _affectsBalance = true;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == TransactionType.expense
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 15,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay(String Function(String) t) {
    final currency = ref.watch(localizedCurrencyProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          // "Amount (MAD)" label
          Text(
            '${t('add_tx_amount')} ($currency)',
            style: AppTextStyles.sectionTitle.copyWith(color: _accentColor),
          ),
          const SizedBox(height: 4),
          // Big amount input — borderless, centered
          TextField(
            controller: _amountController,
            focusNode: _amountFocusNode,
            autofocus: widget.existingTransaction == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: AppTextStyles.balanceHero.copyWith(
              fontSize: 52,
              color: _accentColor,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: AppTextStyles.balanceHero.copyWith(
                fontSize: 52,
                color: _accentColor.withAlpha(50),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _accentColor.withAlpha(80), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String Function(String) t) {
    return AnimatedBuilder(
      animation: _warningSlide,
      builder: (_, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: (_warningSlide.value + 1).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withAlpha(100)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('add_tx_balance_warning'),
                style: AppTextStyles.caption.copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String Function(String) t) {
    final allCats = ref.watch(categoriesProvider);
    final filtered = allCats
        .where((c) => c.type == _type && !c.isArchived)
        .toList()
      ..sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            t('add_tx_category'),
            style: AppTextStyles.labelSmall.copyWith(
              color: _showCategoryError ? AppColors.error : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: filtered.isEmpty
              ? Center(
                  child: Text(t('add_tx_no_categories'),
                      style: AppTextStyles.caption),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _buildCategoryChip(filtered[i], t),
                ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCategoryChip(CategoryModel cat, String Function(String) t) {
    final isSelected = _selectedCategoryId == cat.id;
    final color = Color(cat.color);
    final iconData = IconResolver.resolve(cat.icon);
    final displayName = localizeCategoryName(cat.name, t);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategoryId = isSelected ? null : cat.id;
          _showCategoryError = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _showCategoryError && _selectedCategoryId == null
                ? AppColors.error
                : isSelected
                    ? color
                    : color.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffectsBalanceToggle(String Function(String) t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _affectsBalance
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : (isDark
                  ? const Color(0xFF1A2A1A)
                  : AppColors.incomeGreen.withAlpha(15)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _affectsBalance
                ? Theme.of(context).dividerColor
                : AppColors.incomeGreen.withAlpha(100),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              _affectsBalance ? '💳' : '🎁',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _affectsBalance
                        ? t('affects_balance')
                        : t('off_budget'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _affectsBalance
                        ? t('affects_balance_desc')
                        : t('off_budget_desc'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _affectsBalance,
              onChanged: (val) => setState(() => _affectsBalance = val),
              activeColor: AppColors.expenseRed,
              inactiveThumbColor: AppColors.incomeGreen,
              inactiveTrackColor: AppColors.incomeGreen.withAlpha(77),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(String Function(String) t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _type == TransactionType.expense
        ? AppColors.expenseRed
        : AppColors.incomeGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _noteController,
            focusNode: _noteFocusNode,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            maxLines: 5,
            minLines: 3,
            maxLength: 300,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            onChanged: (val) => setState(() {}),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: t('desc_hint_multiline'),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(89),
                fontSize: 13,
                height: 1.5,
              ),
              prefixIcon: Icon(
                Icons.notes_rounded,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 0,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurface
                  : Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_noteController.text.length}/300',
            style: TextStyle(
              fontSize: 10,
              color: _noteController.text.length > 240
                  ? AppColors.warning
                  : Theme.of(context).colorScheme.onSurface.withAlpha(76),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String Function(String) t) {
    final language = ref.watch(settingsProvider).language;
    final locale = language == 'ar' ? 'ar' : language == 'fr' ? 'fr' : 'en';
    final formatted = DateFormat('EEEE, d MMMM yyyy', locale).format(_selectedDate);
    return InkWell(
      onTap: _pickDate,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(formatted, style: AppTextStyles.body),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.camera_alt_outlined,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          if (_receiptImagePath == null)
            TextButton(
              onPressed: _showImageSourceSheet,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(t('add_tx_add_receipt'),
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w500)),
            )
          else ...[
            GestureDetector(
              onTap: _showFullscreenImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_receiptImagePath!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _receiptImagePath = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurringRow(String Function(String) t) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.repeat, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t('add_tx_recurring'), style: AppTextStyles.body),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeTrackColor: _accentColor,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: _isRecurring ? 52 : 0,
          child: _isRecurring
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
                  child: DropdownButtonFormField<RecurringInterval>(
                    value: _recurringInterval,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: RecurringInterval.daily,
                          child: Text(t('daily'))),
                      DropdownMenuItem(
                          value: RecurringInterval.weekly,
                          child: Text(t('weekly'))),
                      DropdownMenuItem(
                          value: RecurringInterval.monthly,
                          child: Text(t('monthly'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _recurringInterval = v);
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(String Function(String) t) {
    final isEditing = widget.existingTransaction != null;
    final String label;
    if (isEditing) {
      label = _type == TransactionType.expense
          ? t('update_expense')
          : t('update_income');
    } else {
      label = _type == TransactionType.expense
          ? t('save_expense')
          : t('save_income');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _amountIsZero || _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _amountIsZero ? Colors.grey.shade300 : _accentColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: _amountIsZero ? 0 : 2,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_outline, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

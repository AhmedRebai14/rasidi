import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/balance_calculator.dart';
import '../../../core/utils/date_utils.dart';
import '../data/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../categories/data/category_model.dart';
import '../../session/providers/session_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../shared/widgets/amount_input.dart';
import '../../../shared/widgets/category_chip.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet modal for adding or editing a transaction
class AddTransactionSheet extends ConsumerStatefulWidget {
  final String sessionId;
  final String currency;
  final TransactionModel? existingTransaction;
  final TransactionType initialType;

  const AddTransactionSheet({
    super.key,
    required this.sessionId,
    required this.currency,
    this.existingTransaction,
    this.initialType = TransactionType.expense,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  RecurringInterval? _recurringInterval;
  String? _receiptImagePath;
  bool _isSaving = false;

  static final _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _type = widget.existingTransaction?.type ?? widget.initialType;

    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _noteController.text = tx.note ?? '';
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
      _isRecurring = tx.isRecurring;
      _recurringInterval = tx.recurringInterval;
      _receiptImagePath = tx.receiptImagePath;
    } else {
      // Pre-select last used category
      final lastUsed = ref.read(settingsProvider).lastCategoryUsedId;
      if (lastUsed != null) _selectedCategoryId = lastUsed;
    }

    // Auto-focus the amount input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  List<CategoryModel> get _currentCategories {
    final all = _type == TransactionType.expense
        ? ref.read(expenseCategoriesProvider)
        : ref.read(incomeCategoriesProvider);
    return all;
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    // Check balance warning for expenses
    if (_type == TransactionType.expense) {
      final session = ref.read(activeSessionProvider);
      if (session != null) {
        final allTxs = ref.read(transactionsProvider);
        final sessionTxs = allTxs.where((t) => t.sessionId == session.id);
        final income =
            sessionTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
        final expenses =
            sessionTxs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
        final remaining = BalanceCalculator.remaining(
          initialBalance: session.initialBalance,
          totalIncome: income,
          totalExpenses: expenses,
        );
        if (amount > remaining) {
          final proceed = await _showBalanceWarning(amount, remaining);
          if (!proceed) return;
        }
      }
    }

    // Check category budget warning
    await _checkCategoryBudget(amount);

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(transactionsProvider.notifier);
      if (widget.existingTransaction != null) {
        final updated = widget.existingTransaction!.copyWith(
          amount: amount,
          type: _type,
          categoryId: _selectedCategoryId,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          isRecurring: _isRecurring,
          recurringInterval: _isRecurring ? _recurringInterval : null,
          receiptImagePath: _receiptImagePath,
        );
        await notifier.updateTransaction(updated);
      } else {
        final tx = TransactionModel(
          id: _uuid.v4(),
          amount: amount,
          type: _type,
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          sessionId: widget.sessionId,
          isRecurring: _isRecurring,
          recurringInterval: _isRecurring ? _recurringInterval : null,
          receiptImagePath: _receiptImagePath,
        );
        await notifier.addTransaction(tx);
        // Remember last used category
        await ref
            .read(settingsProvider.notifier)
            .setLastCategoryUsed(_selectedCategoryId);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _showBalanceWarning(double amount, double remaining) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('⚠️ Balance Warning'),
            content: Text(
              'This expense (${widget.currency} $amount) exceeds your remaining balance (${widget.currency} ${remaining.toStringAsFixed(2)}).\n\nDo you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                child: const Text('Proceed Anyway',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _checkCategoryBudget(double amount) async {
    if (_selectedCategoryId == null) return;
    final allCats = ref.read(categoriesProvider);
    final cat = allCats.where((c) => c.id == _selectedCategoryId).firstOrNull;
    if (cat == null || cat.budgetLimit == null || cat.budgetLimit! <= 0) return;

    final session = ref.read(activeSessionProvider);
    if (session == null) return;
    final allTxs = ref.read(transactionsProvider);
    final spent = allTxs
        .where((t) =>
            t.sessionId == session.id &&
            t.categoryId == _selectedCategoryId &&
            t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);

    final newTotal = spent + amount;
    final usage = BalanceCalculator.budgetUsageRatio(
        spent: newTotal, limit: cat.budgetLimit!);

    if (usage >= 1.0) {
      _showBudgetAlert('🔴 You\'ve exceeded your budget for ${cat.name}!',
          AppColors.expenseRed);
    } else if (usage >= 0.8) {
      _showBudgetAlert(
          '🟡 Warning: 80%+ of your ${cat.name} budget used', AppColors.warning);
    }
  }

  void _showBudgetAlert(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) setState(() => _receiptImagePath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _currentCategories;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomPadding + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Type toggle
          _buildTypeToggle(),
          const SizedBox(height: 20),
          // Amount input
          AmountInput(
            controller: _amountController,
            currency: widget.currency,
            focusNode: _amountFocus,
          ),
          const SizedBox(height: 16),
          // Category selector
          Text('Category', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final icon = IconData(
                  int.tryParse(cat.icon) ?? Icons.category.codePoint,
                  fontFamily: 'MaterialIcons',
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: cat.name,
                    icon: icon,
                    color: Color(cat.color),
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () =>
                        setState(() => _selectedCategoryId = cat.id),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Date + Note row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(AppDateUtils.formatDay(_selectedDate),
                            style: AppTextStyles.body),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Note (optional)',
                    prefixIcon: Icon(Icons.notes, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Receipt + Recurring row
          Row(
            children: [
              // Receipt button
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: Icon(
                  _receiptImagePath != null
                      ? Icons.receipt
                      : Icons.add_a_photo_outlined,
                  size: 16,
                ),
                label: Text(_receiptImagePath != null ? 'Receipt ✓' : 'Receipt'),
              ),
              const Spacer(),
              // Recurring toggle
              Row(
                children: [
                  Text('Recurring', style: AppTextStyles.caption),
                  const SizedBox(width: 4),
                  Switch(
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Interval: ', style: AppTextStyles.bodyMedium),
                const SizedBox(width: 8),
                DropdownButton<RecurringInterval>(
                  value: _recurringInterval ?? RecurringInterval.monthly,
                  onChanged: (v) =>
                      setState(() => _recurringInterval = v),
                  items: const [
                    DropdownMenuItem(
                        value: RecurringInterval.daily,
                        child: Text('Daily')),
                    DropdownMenuItem(
                        value: RecurringInterval.weekly,
                        child: Text('Weekly')),
                    DropdownMenuItem(
                        value: RecurringInterval.monthly,
                        child: Text('Monthly')),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _type == TransactionType.expense
                  ? AppColors.expenseRed
                  : AppColors.incomeGreen,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(widget.existingTransaction != null
                    ? 'Update Transaction'
                    : 'Save Transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              'EXPENSE',
              TransactionType.expense,
              AppColors.expenseRed,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              'INCOME',
              TransactionType.income,
              AppColors.incomeGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String label, TransactionType type, Color activeColor) {
    final isActive = _type == type;
    return GestureDetector(
      onTap: () => setState(() {
        _type = type;
        _selectedCategoryId = null; // reset when type changes
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.button.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/category_model.dart';
import '../providers/category_providers.dart';
import '../../transactions/data/transaction_model.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../core/utils/icon_resolver.dart';
import 'package:uuid/uuid.dart';

/// Screen for adding or editing a category
class AddCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? existingCategory;
  const AddCategoryScreen({super.key, this.existingCategory});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  int _selectedColor = AppColors.categoryPresetColors[0].value;
  IconData _selectedIcon = Icons.category;
  bool _isSaving = false;

  static final _uuid = Uuid();

  // Available icons for picker — single source of truth in IconResolver
  static List<IconData> get _availableIcons => IconResolver.availableIcons;

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      final cat = widget.existingCategory!;
      _nameController.text = cat.name;
      _type = cat.type;
      _selectedColor = cat.color;
      _selectedIcon = IconResolver.resolve(cat.icon);
      if (cat.budgetLimit != null) {
        _budgetController.text = cat.budgetLimit!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final budget = double.tryParse(_budgetController.text);
      final notifier = ref.read(categoriesProvider.notifier);

      if (widget.existingCategory != null) {
        final updated = widget.existingCategory!.copyWith(
          name: name,
          icon: '${_selectedIcon.codePoint}',
          color: _selectedColor,
          budgetLimit: budget,
        );
        await notifier.updateCategory(updated);
      } else {
        final cat = CategoryModel(
          id: _uuid.v4(),
          name: name,
          type: _type,
          icon: '${_selectedIcon.codePoint}',
          color: _selectedColor,
          budgetLimit: budget,
        );
        await notifier.addCategory(cat);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCategory != null
            ? 'Edit Category'
            : 'Add Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(_selectedColor).withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_selectedIcon,
                    color: Color(_selectedColor), size: 40),
              ),
            ),
            const SizedBox(height: 24),
            // Type selector (only for new categories)
            if (widget.existingCategory == null) ...[
              Text('Type', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeBtn(
                        'Expense', TransactionType.expense, AppColors.expenseRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeBtn(
                        'Income', TransactionType.income, AppColors.incomeGreen),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Name
            Text('Name', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Category name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            // Budget limit
            Text('Monthly Budget Limit (Optional)',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'No limit',
                suffixText: ref.watch(localizedCurrencyProvider),
              ),
            ),
            const SizedBox(height: 16),
            // Color picker
            Text('Color', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppColors.categoryPresetColors.map((c) {
                final isSelected = c.value == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c.value),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.textPrimary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Icon picker
            Text('Icon', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _availableIcons.length,
              itemBuilder: (ctx, i) {
                final icon = _availableIcons[i];
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(_selectedColor).withAlpha(51)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Color(_selectedColor), width: 2)
                          : null,
                    ),
                    child: Icon(icon,
                        size: 22,
                        color: isSelected
                            ? Color(_selectedColor)
                            : AppColors.textSecondary),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)
                  : Text(widget.existingCategory != null
                      ? 'Save Changes'
                      : 'Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBtn(
      String label, TransactionType type, Color activeColor) {
    final isActive = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : AppColors.surfaceVariant,
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

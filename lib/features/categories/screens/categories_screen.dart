import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/category_model.dart';
import '../providers/category_providers.dart';
import '../../transactions/data/transaction_model.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../session/providers/session_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/icon_resolver.dart';

/// Displays all categories in two tabs: Expenses and Income
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(localizedCurrencyProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/categories/add'),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _CategoryList(type: TransactionType.expense, currency: currency),
            _CategoryList(type: TransactionType.income, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final TransactionType type;
  final String currency;

  const _CategoryList({required this.type, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = type == TransactionType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    if (categories.isEmpty) {
      return const EmptyState(
          icon: Icons.category_outlined, message: 'No categories');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        return _CategoryTile(
          category: cat,
          currency: currency,
          onToggleFavorite: () =>
              ref.read(categoriesProvider.notifier).toggleFavorite(cat.id),
          onArchive: () => _confirmArchive(context, ref, cat),
          onEdit: () => context.push('/categories/add', extra: cat),
        );
      },
    );
  }

  void _confirmArchive(
      BuildContext context, WidgetRef ref, CategoryModel cat) {
    if (cat.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default categories cannot be archived')),
      );
      return;
    }
    ConfirmationDialog.show(
      context,
      title: 'Archive Category',
      message:
          'Archive "${cat.name}"? Existing transactions will be preserved.',
      confirmLabel: 'Archive',
      onConfirm: () =>
          ref.read(categoriesProvider.notifier).archiveCategory(cat.id),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final CategoryModel category;
  final String currency;
  final VoidCallback onToggleFavorite;
  final VoidCallback onArchive;
  final VoidCallback onEdit;

  const _CategoryTile({
    required this.category,
    required this.currency,
    required this.onToggleFavorite,
    required this.onArchive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(category.color);
    final icon = IconResolver.resolve(category.icon);
    final session = ref.watch(activeSessionProvider);

    // Calculate spending if session exists
    double spent = 0;
    if (session != null) {
      final txs = ref.watch(transactionsProvider);
      spent = txs
          .where((t) =>
              t.sessionId == session.id &&
              t.categoryId == category.id &&
              t.isExpense)
          .fold(0.0, (s, t) => s + t.amount);
    }

    final hasLimit = category.budgetLimit != null && category.budgetLimit! > 0;
    final usage = hasLimit
        ? (spent / category.budgetLimit!).clamp(0.0, double.infinity)
        : 0.0;

    return GestureDetector(
      onLongPress: onArchive,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(category.name, style: AppTextStyles.bodyMedium),
                      if (category.isDefault)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Default',
                                style: AppTextStyles.labelSmall
                                    .copyWith(fontSize: 9)),
                          ),
                        ),
                    ],
                  ),
                  if (hasLimit) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: usage.clamp(0.0, 1.0),
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                usage >= 1.0
                                    ? AppColors.expenseRed
                                    : usage >= 0.8
                                        ? AppColors.warning
                                        : AppColors.incomeGreen,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${CurrencyFormatter.formatClean(spent, symbol: currency)} / ${CurrencyFormatter.formatClean(category.budgetLimit!, symbol: currency)}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Favorite toggle
            IconButton(
              icon: Icon(
                category.isFavorite ? Icons.star : Icons.star_border,
                color: category.isFavorite
                    ? Colors.amber
                    : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleFavorite,
            ),
            if (!category.isDefault)
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textSecondary),
                onPressed: onEdit,
              ),
          ],
        ),
      ),
    );
  }
}

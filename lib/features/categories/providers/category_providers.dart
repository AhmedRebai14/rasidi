import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/category_model.dart';
import '../../transactions/data/transaction_model.dart';

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  CategoryNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<CategoryModel>(HiveBoxes.categories);
    state = box.values
        .where((c) => !c.isArchived)
        .toList()
      ..sort((a, b) {
        // Favorites first, then by sortOrder
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
  }

  Future<bool> addCategory(CategoryModel category) async {
    try {
      final box = Hive.box<CategoryModel>(HiveBoxes.categories);
      await box.put(category.id, category);
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCategory(CategoryModel updated) async {
    try {
      final box = Hive.box<CategoryModel>(HiveBoxes.categories);
      final existing = box.get(updated.id);
      if (existing == null) return false;
      existing.name = updated.name;
      existing.icon = updated.icon;
      existing.color = updated.color;
      existing.isFavorite = updated.isFavorite;
      existing.sortOrder = updated.sortOrder;
      existing.budgetLimit = updated.budgetLimit;
      await existing.save();
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String id) async {
    try {
      final box = Hive.box<CategoryModel>(HiveBoxes.categories);
      final cat = box.get(id);
      if (cat == null) return false;
      cat.isFavorite = !cat.isFavorite;
      await cat.save();
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> archiveCategory(String id) async {
    try {
      final box = Hive.box<CategoryModel>(HiveBoxes.categories);
      final cat = box.get(id);
      if (cat == null) return false;
      cat.isArchived = true;
      await cat.save();
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setBudgetLimit(String id, double? limit) async {
    try {
      final box = Hive.box<CategoryModel>(HiveBoxes.categories);
      final cat = box.get(id);
      if (cat == null) return false;
      cat.budgetLimit = limit;
      await cat.save();
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  void refresh() => _load();
}

// ── Providers ──────────────────────────────────────────────────────────────

final categoriesProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>(
  (ref) => CategoryNotifier(),
);

final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref
      .watch(categoriesProvider)
      .where((c) => c.type == TransactionType.expense)
      .toList();
});

final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref
      .watch(categoriesProvider)
      .where((c) => c.type == TransactionType.income)
      .toList();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/saving_model.dart';

class SavingNotifier extends StateNotifier<List<SavingModel>> {
  SavingNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<SavingModel>(HiveBoxes.savings);
    state = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<bool> addSaving(SavingModel saving) async {
    try {
      final box = Hive.box<SavingModel>(HiveBoxes.savings);
      await box.put(saving.id, saving);
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSaving(String id) async {
    try {
      final box = Hive.box<SavingModel>(HiveBoxes.savings);
      await box.delete(id);
      _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  void refresh() => _load();
}

// ── Providers ──────────────────────────────────────────────────────────────

final savingsProvider =
    StateNotifierProvider<SavingNotifier, List<SavingModel>>(
  (ref) => SavingNotifier(),
);

final totalSavingsProvider = Provider<double>((ref) {
  final savings = ref.watch(savingsProvider);
  return savings.fold(0.0, (sum, s) => sum + s.amount);
});

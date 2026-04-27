import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/saving_goal_model.dart';
import '../../gamification/providers/user_stats_provider.dart';
import '../../gamification/services/xp_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../settings/providers/settings_providers.dart';
import 'challenges_provider.dart';

const _uuid = Uuid();

class GoalsNotifier extends StateNotifier<List<SavingGoalModel>> {
  final Ref _ref;

  GoalsNotifier(this._ref) : super([]) {
    _load();
  }

  Box<SavingGoalModel> get _box =>
      Hive.box<SavingGoalModel>(HiveBoxes.goals);

  void _load() {
    state = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addGoal(SavingGoalModel goal) async {
    await _box.put(goal.id, goal);
    _load();
    await _ref.read(userStatsProvider.notifier).awardXP(XPService.addGoal, 'add_goal');
  }

  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
    _load();
  }

  Future<XPResult?> addFunds({
    required String goalId,
    required double amount,
    required String note,
  }) async {
    final goal = _box.get(goalId);
    if (goal == null) return null;

    final prevPct = (goal.progress * 100).floor();
    goal.currentAmount = (goal.currentAmount + amount).clamp(0, goal.targetAmount * 2);
    final newPct = (goal.progress * 100).floor();

    final contribution = GoalContribution(
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    goal.contributionMaps.add(contribution.toMap().cast<dynamic, dynamic>());

    XPResult? xpResult;
    final lang = _ref.read(settingsProvider).language;

    // Milestone checks
    for (final milestone in [25, 50, 75]) {
      if (prevPct < milestone && newPct >= milestone) {
        xpResult = await _ref
            .read(userStatsProvider.notifier)
            .awardXP(XPService.goalMilestone25, 'goal_$milestone');
        if (_ref.read(settingsProvider).notifyGoalMilestones) {
          NotificationService.instance.sendGoalMilestone(
            goalName: goal.name,
            pct: milestone,
            icon: goal.icon,
            language: lang,
          );
        }
      }
    }

    if (!goal.isCompleted && goal.currentAmount >= goal.targetAmount) {
      goal.isCompleted = true;
      goal.completedAt = DateTime.now();
      xpResult = await _ref
          .read(userStatsProvider.notifier)
          .awardXP(XPService.hitSavingGoal, 'goal_completed');
      await _ref.read(userStatsProvider.notifier).awardBadge('goal_crusher');
      if (_ref.read(settingsProvider).notifyGoalMilestones) {
        NotificationService.instance.sendGoalMilestone(
          goalName: goal.name,
          pct: 100,
          icon: goal.icon,
          language: lang,
        );
      }
    }

    await goal.save();
    _load();

    // Update Big Saver challenge — total across all goals
    final totalSaved = _box.values.fold(0.0, (sum, g) => sum + g.currentAmount);
    await _ref
        .read(challengesProvider.notifier)
        .updateProgress(id: 'save_goal_10k', progress: totalSaved);

    return xpResult;
  }

  Future<SavingGoalModel> createGoal({
    required String name,
    required double targetAmount,
    required String icon,
    required int color,
    DateTime? deadline,
  }) async {
    final goal = SavingGoalModel(
      id: _uuid.v4(),
      name: name,
      targetAmount: targetAmount,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
      deadline: deadline,
    );
    await addGoal(goal);
    return goal;
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<SavingGoalModel>>(
  (ref) => GoalsNotifier(ref),
);

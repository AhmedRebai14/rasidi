import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/challenge_model.dart';
import '../../gamification/providers/user_stats_provider.dart';
import '../../gamification/services/xp_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../settings/providers/settings_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../session/providers/session_providers.dart';

/// Predefined challenge templates (seeded on first launch)
List<ChallengeModel> get defaultChallenges {
  final now = DateTime.now();
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  return [
    ChallengeModel(
      id: 'no_spend_day',
      type: ChallengeType.noSpendDay,
      titleKey: 'challenge_nospend_title',
      descKey: 'challenge_nospend_desc',
      xpReward: 20,
      badgeIcon: '🧘',
      status: ChallengeStatus.locked,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      targetAmount: 7,
    ),
    ChallengeModel(
      id: 'log_streak_7',
      type: ChallengeType.logEveryDay,
      titleKey: 'challenge_log7_title',
      descKey: 'challenge_log7_desc',
      xpReward: 75,
      badgeIcon: '🔥',
      status: ChallengeStatus.locked,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      targetAmount: 7,
    ),
    ChallengeModel(
      id: 'beat_last_month',
      type: ChallengeType.beatLastMonth,
      titleKey: 'challenge_beat_title',
      descKey: 'challenge_beat_desc',
      xpReward: 100,
      badgeIcon: '📉',
      status: ChallengeStatus.locked,
      startDate: now,
      endDate: monthEnd,
    ),
    ChallengeModel(
      id: 'add_receipt_5',
      type: ChallengeType.addReceiptFiveTimes,
      titleKey: 'challenge_receipt_title',
      descKey: 'challenge_receipt_desc',
      xpReward: 50,
      badgeIcon: '📷',
      status: ChallengeStatus.locked,
      startDate: now,
      endDate: monthEnd,
      targetAmount: 5,
    ),
    ChallengeModel(
      id: 'save_goal_10k',
      type: ChallengeType.savingsTarget,
      titleKey: 'challenge_save10k_title',
      descKey: 'challenge_save10k_desc',
      xpReward: 150,
      badgeIcon: '🏆',
      status: ChallengeStatus.locked,
      startDate: now,
      endDate: monthEnd,
      targetAmount: 10000,
    ),
    ChallengeModel(
      id: 'three_month_positive',
      type: ChallengeType.threeMonthPositive,
      titleKey: 'challenge_3month_title',
      descKey: 'challenge_3month_desc',
      xpReward: 300,
      badgeIcon: '👑',
      status: ChallengeStatus.locked,
      startDate: now,
      endDate: now.add(const Duration(days: 90)),
      targetAmount: 3,
    ),
  ];
}

class ChallengesNotifier extends StateNotifier<List<ChallengeModel>> {
  final Ref _ref;

  ChallengesNotifier(this._ref) : super([]) {
    _loadOrSeed();
    _checkExpiredChallenges();
    _checkDailyNoSpend();
  }

  Box<ChallengeModel> get _box =>
      Hive.box<ChallengeModel>(HiveBoxes.challenges);

  // Untyped box for storing metadata (last-checked dates, etc.)
  Box get _metaBox => Hive.box(HiveBoxes.insights);

  void _loadOrSeed() {
    if (_box.isEmpty) {
      for (final c in defaultChallenges) {
        _box.put(c.id, c);
      }
    }
    state = _box.values.toList();
  }

  /// Marks any active challenges whose endDate has passed as failed.
  Future<void> _checkExpiredChallenges() async {
    final now = DateTime.now();
    bool changed = false;
    for (final ch in _box.values) {
      if (ch.isActive && now.isAfter(ch.endDate)) {
        ch.status = ChallengeStatus.failed;
        await ch.save();
        changed = true;
      }
    }
    if (changed) _loadOrSeed();
  }

  /// Runs once on app start.
  /// has no expense transactions, increments the streak by 1 day.
  /// Uses a Hive key to ensure it only runs once per calendar day.
  Future<void> _checkDailyNoSpend() async {
    final ch = _box.get('no_spend_day');
    if (ch == null || !ch.isActive) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    // Use a separate box entry to track last-checked date
    final lastChecked = _metaBox.get('_nospend_last_checked') as String? ?? '';
    if (lastChecked == today) return; // already checked today

    // Check if today has any expense transactions in the active session
    final session = _ref.read(activeSessionProvider);
    if (session == null) return;

    final txns = _ref.read(transactionsProvider);
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final hasExpenseToday = txns.any((t) =>
        t.sessionId == session.id &&
        t.isExpense &&
        t.date.isAfter(todayStart));

    if (!hasExpenseToday) {
      // No expense today — increment no-spend streak
      await incrementProgress('no_spend_day');
    }
    // Mark today as checked
    await _metaBox.put('_nospend_last_checked', today);
    _loadOrSeed();
  }

  Future<void> startChallenge(String id) async {
    final ch = _box.get(id);
    if (ch == null) return;
    ch.status = ChallengeStatus.active;
    await ch.save();
    _loadOrSeed();
  }

  Future<XPResult?> updateProgress({
    required String id,
    required double progress,
  }) async {
    final ch = _box.get(id);
    if (ch == null || !ch.isActive) return null;
    ch.currentProgress = progress;

    XPResult? result;
    final target = ch.targetAmount ?? 1;

    if (progress >= target && !ch.isCompleted) {
      ch.status = ChallengeStatus.completed;
      await ch.save();
      result = await _ref
          .read(userStatsProvider.notifier)
          .awardXP(ch.xpReward, 'challenge_${ch.id}');

      // Award the badge linked to this challenge
      const _challengeBadgeMap = {
        'no_spend_day': 'no_spender',
        'log_streak_7': 'week_warrior',
        'beat_last_month': 'month_master',
        'add_receipt_5': 'receipt_keeper',
        'save_goal_10k': 'saver',
      };
      final badgeId = _challengeBadgeMap[ch.id];
      if (badgeId != null) {
        await _ref.read(userStatsProvider.notifier).awardBadge(badgeId);
      }

      final lang = _ref.read(settingsProvider).language;
      NotificationService.instance.sendChallengeCompleted(
        titleKey: ch.titleKey,
        xp: ch.xpReward,
        language: lang,
      );
    } else {
      await ch.save();
    }
    _loadOrSeed();
    return result;
  }

  /// Increments an active challenge's progress by [amount] (default 1).
  /// Ignores if challenge doesn't exist or is not active.
  Future<XPResult?> incrementProgress(String id, {double amount = 1}) async {
    final ch = _box.get(id);
    if (ch == null || !ch.isActive) return null;
    return updateProgress(id: id, progress: ch.currentProgress + amount);
  }

  /// Resets an active challenge's progress back to 0 (e.g. broken streak).
  Future<void> resetProgress(String id) async {
    final ch = _box.get(id);
    if (ch == null || !ch.isActive) return;
    ch.currentProgress = 0;
    await ch.save();
    _loadOrSeed();
  }

  void refresh() => _loadOrSeed();
}

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<ChallengeModel>>(
  (ref) => ChallengesNotifier(ref),
);

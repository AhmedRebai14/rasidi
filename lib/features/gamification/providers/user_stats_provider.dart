import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/user_stats_model.dart';
import '../services/xp_service.dart';

class UserStatsNotifier extends StateNotifier<UserStatsModel> {
  UserStatsNotifier() : super(UserStatsModel()) {
    _load();
  }

  Box<UserStatsModel> get _box => Hive.box<UserStatsModel>(HiveBoxes.userStats);

  void _load() {
    state = _box.get('stats') ?? UserStatsModel();
  }

  Future<void> _save() async {
    await _box.put('stats', state);
  }

  // ── XP ──────────────────────────────────────────────────────────────────

  Future<XPResult> awardXP(int amount, String reason) async {
    final oldLevel = state.level;
    final newXP = state.totalXP + amount;
    final newLevel = _calculateLevel(newXP);
    final leveledUp = newLevel > oldLevel;

    state = state.copyWith(totalXP: newXP, level: newLevel);
    await _save();

    if (leveledUp && newLevel >= 5) {
      await _earnBadge('high_roller');
    }

    return XPResult(
      xpGained: amount,
      newTotal: newXP,
      leveledUp: leveledUp,
      newLevel: newLevel,
      newLevelTitle: state.levelTitle,
      reason: reason,
    );
  }

  int _calculateLevel(int xp) {
    if (xp >= 1500) return 6;
    if (xp >= 1000) return 5;
    if (xp >= 600) return 4;
    if (xp >= 300) return 3;
    if (xp >= 100) return 2;
    return 1;
  }

  // ── Streak / Transaction recording ──────────────────────────────────────

  /// Call on every new transaction added. Returns XPResult.
  Future<XPResult> recordTransaction({bool hasReceipt = false}) async {
    final today = DateTime.now();
    final lastLog = state.lastLogDate;
    int newStreak = state.dailyLogStreak;
    int bonusXP = 0;
    String reason = 'add_transaction';

    if (lastLog == null) {
      newStreak = 1;
    } else {
      final diff = today.difference(
              DateTime(lastLog.year, lastLog.month, lastLog.day))
          .inDays;
      if (diff == 0) {
        // same day — no streak change
      } else if (diff == 1) {
        newStreak += 1;
      } else {
        newStreak = 1;
      }
    }

    // Streak milestone bonuses
    if (newStreak == 7) {
      bonusXP += XPService.sevenDayStreak;
      reason = 'streak_7';
      await _earnBadge('streak_king');
    } else if (newStreak == 14) {
      bonusXP += XPService.fourteenDayStreak;
      reason = 'streak_14';
    } else if (newStreak == 30) {
      bonusXP += XPService.thirtyDayStreak;
      reason = 'streak_30';
    }

    final isFirstEver = state.totalTransactions == 0;
    final baseXP = isFirstEver
        ? XPService.firstTransaction
        : XPService.addTransaction;
    if (isFirstEver) await _earnBadge('first_transaction');
    if (hasReceipt) bonusXP += XPService.addReceipt;

    final newTotal = state.totalTransactions + 1;
    state = state.copyWith(
      dailyLogStreak: newStreak,
      lastLogDate: today,
      totalTransactions: newTotal,
    );
    await _save();

    return awardXP(baseXP + bonusXP, reason);
  }

  // ── Settlement ───────────────────────────────────────────────────────────

  Future<XPResult> recordSettlement() async {
    final newCount = state.totalSettlements + 1;
    final newStreak = state.settlementStreak + 1;
    state = state.copyWith(
      totalSettlements: newCount,
      settlementStreak: newStreak,
    );
    await _save();
    if (newCount == 1) await _earnBadge('first_settlement');
    if (newStreak >= 3) await _earnBadge('three_months');
    return awardXP(XPService.monthlySettlement, 'settlement');
  }

  // ── Badges ───────────────────────────────────────────────────────────────

  Future<void> _earnBadge(String id) async {
    if (state.earnedBadges.contains(id)) return;
    final updated = List<String>.from(state.earnedBadges)..add(id);
    state = state.copyWith(earnedBadges: updated);
    await _save();

    // Auto-award rasidi_pro when all other badges are earned
    if (id != 'rasidi_pro' && !state.earnedBadges.contains('rasidi_pro')) {
      const allOther = ['first_transaction', 'first_settlement',
          'saver', 'no_spender', 'week_warrior', 'month_master',
          'goal_crusher', 'streak_king', 'receipt_keeper', 'three_months',
          'high_roller'];
      if (allOther.every((b) => state.earnedBadges.contains(b))) {
        await _earnBadge('rasidi_pro');
      }
    }
  }

  Future<void> awardBadge(String id) => _earnBadge(id);

  void refresh() => _load();
}

// ── Provider ───────────────────────────────────────────────────────────────

final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, UserStatsModel>(
  (ref) => UserStatsNotifier(),
);

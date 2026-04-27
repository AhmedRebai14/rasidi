/// XP reward constants for every qualifying action.
class XPService {
  XPService._();

  static const int addTransaction    = 5;
  static const int completeChallenge = 50;
  static const int monthlySettlement = 100;
  static const int hitSavingGoal     = 150;
  static const int noSpendDay        = 20;
  static const int sevenDayStreak    = 75;
  static const int fourteenDayStreak = 100;
  static const int thirtyDayStreak   = 150;
  static const int addReceipt        = 10;
  static const int firstTransaction  = 25;
  static const int addGoal           = 10;
  static const int goalMilestone25   = 30;
  static const int goalMilestone50   = 30;
  static const int goalMilestone75   = 30;
  static const int goalCompleted     = 150;
}

/// Result returned by [UserStatsNotifier.awardXP].
class XPResult {
  final int xpGained;
  final int newTotal;
  final bool leveledUp;
  final int newLevel;
  final String newLevelTitle;
  final String reason;

  const XPResult({
    required this.xpGained,
    required this.newTotal,
    required this.leveledUp,
    required this.newLevel,
    required this.newLevelTitle,
    required this.reason,
  });
}

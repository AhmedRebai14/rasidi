/// Hive box names used throughout the app
class HiveBoxes {
  HiveBoxes._();

  static const String sessions = 'sessions';
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String savings = 'savings';
  static const String settings = 'settings';

  // ── New feature boxes ───────────────────────────────────────────────────
  static const String insights = 'insights';
  static const String goals = 'goals';
  static const String challenges = 'challenges';
  static const String userStats = 'user_stats';
}

/// Hive TypeAdapter typeIds
class HiveTypeIds {
  HiveTypeIds._();

  static const int monthlySession = 0;
  static const int transaction = 1;
  static const int category = 2;
  static const int saving = 3;
  static const int appSettings = 4;
  static const int sessionStatus = 5;
  static const int transactionType = 6;
  static const int recurringInterval = 7;
}

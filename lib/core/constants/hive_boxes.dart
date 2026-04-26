/// Hive box names used throughout the app
class HiveBoxes {
  HiveBoxes._();

  static const String sessions = 'sessions';
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String savings = 'savings';
  static const String settings = 'settings';
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

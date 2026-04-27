import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_boxes.dart';
import '../../features/session/data/monthly_session.dart';
import '../../features/transactions/data/transaction_model.dart';
import '../../features/categories/data/category_model.dart';
import '../../features/savings/data/saving_model.dart';
import '../../features/settings/data/app_settings_model.dart';
import '../../features/insights/data/insight_model.dart';
import '../../features/goals/data/saving_goal_model.dart';
import '../../features/goals/data/challenge_model.dart';
import '../../features/gamification/data/user_stats_model.dart';

/// Central service to initialize and access Hive boxes
class HiveService {
  HiveService._();

  static Box<MonthlySession> get sessions => Hive.box<MonthlySession>(HiveBoxes.sessions);
  static Box<TransactionModel> get transactions => Hive.box<TransactionModel>(HiveBoxes.transactions);
  static Box<CategoryModel> get categories => Hive.box<CategoryModel>(HiveBoxes.categories);
  static Box<SavingModel> get savings => Hive.box<SavingModel>(HiveBoxes.savings);
  static Box<AppSettingsModel> get settingsBox => Hive.box<AppSettingsModel>(HiveBoxes.settings);
  static Box<SavingGoalModel> get goals => Hive.box<SavingGoalModel>(HiveBoxes.goals);
  static Box<ChallengeModel> get challenges => Hive.box<ChallengeModel>(HiveBoxes.challenges);
  static Box<UserStatsModel> get userStats => Hive.box<UserStatsModel>(HiveBoxes.userStats);

  /// Initialize Hive and register all adapters, then open boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
  }

  static void _registerAdapters() {
    Hive.registerAdapter(SessionStatusAdapter());
    Hive.registerAdapter(MonthlySessionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(RecurringIntervalAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(SavingModelAdapter());
    Hive.registerAdapter(AppSettingsModelAdapter());
    // New feature adapters
    Hive.registerAdapter(InsightTypeAdapter());
    Hive.registerAdapter(InsightSentimentAdapter());
    Hive.registerAdapter(InsightModelAdapter());
    Hive.registerAdapter(SavingGoalModelAdapter());
    Hive.registerAdapter(ChallengeTypeAdapter());
    Hive.registerAdapter(ChallengeStatusAdapter());
    Hive.registerAdapter(ChallengeModelAdapter());
    Hive.registerAdapter(UserStatsModelAdapter());
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<MonthlySession>(HiveBoxes.sessions);
    await Hive.openBox<TransactionModel>(HiveBoxes.transactions);
    await Hive.openBox<CategoryModel>(HiveBoxes.categories);
    await Hive.openBox<SavingModel>(HiveBoxes.savings);
    await Hive.openBox<AppSettingsModel>(HiveBoxes.settings);
    // New boxes
    await Hive.openBox(HiveBoxes.insights);           // dynamic box
    await Hive.openBox<SavingGoalModel>(HiveBoxes.goals);
    await Hive.openBox<ChallengeModel>(HiveBoxes.challenges);
    await Hive.openBox<UserStatsModel>(HiveBoxes.userStats);
  }

  /// Clear ALL data — used in settings
  static Future<void> clearAll() async {
    await sessions.clear();
    await transactions.clear();
    await categories.clear();
    await savings.clear();
    await settingsBox.clear();
    await goals.clear();
    await challenges.clear();
    await userStats.clear();
    await Hive.box(HiveBoxes.insights).clear();
  }

  /// Get app settings (creates default if not present)
  static AppSettingsModel getSettings() {
    if (settingsBox.isEmpty) {
      final defaults = AppSettingsModel();
      settingsBox.put('settings', defaults);
      return defaults;
    }
    return settingsBox.get('settings') ?? AppSettingsModel();
  }
}

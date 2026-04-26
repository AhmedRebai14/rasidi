import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_boxes.dart';
import '../../features/session/data/monthly_session.dart';
import '../../features/transactions/data/transaction_model.dart';
import '../../features/categories/data/category_model.dart';
import '../../features/savings/data/saving_model.dart';
import '../../features/settings/data/app_settings_model.dart';

/// Central service to initialize and access Hive boxes
class HiveService {
  HiveService._();

  static Box<MonthlySession> get sessions => Hive.box<MonthlySession>(HiveBoxes.sessions);
  static Box<TransactionModel> get transactions => Hive.box<TransactionModel>(HiveBoxes.transactions);
  static Box<CategoryModel> get categories => Hive.box<CategoryModel>(HiveBoxes.categories);
  static Box<SavingModel> get savings => Hive.box<SavingModel>(HiveBoxes.savings);
  static Box<AppSettingsModel> get settingsBox => Hive.box<AppSettingsModel>(HiveBoxes.settings);

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
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<MonthlySession>(HiveBoxes.sessions);
    await Hive.openBox<TransactionModel>(HiveBoxes.transactions);
    await Hive.openBox<CategoryModel>(HiveBoxes.categories);
    await Hive.openBox<SavingModel>(HiveBoxes.savings);
    await Hive.openBox<AppSettingsModel>(HiveBoxes.settings);
  }

  /// Clear ALL data — used in settings
  static Future<void> clearAll() async {
    await sessions.clear();
    await transactions.clear();
    await categories.clear();
    await savings.clear();
    await settingsBox.clear();
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

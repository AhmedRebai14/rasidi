import 'package:hive/hive.dart';

part 'app_settings_model.g.dart';

/// Global app settings stored in Hive
@HiveType(typeId: 4)
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  String currencySymbol;

  @HiveField(1)
  String language;

  @HiveField(2)
  bool isDarkMode;

  @HiveField(3)
  bool isPinEnabled;

  @HiveField(4)
  String? pin;

  @HiveField(5)
  bool isBiometricEnabled;

  @HiveField(6)
  String? lastCategoryUsedId;

  @HiveField(7)
  int lockTimeoutSeconds;

  // ── Notification settings ────────────────────────────────────────────────

  @HiveField(8)
  bool notificationsEnabled;

  @HiveField(9)
  bool notifyInsights;

  @HiveField(10)
  bool notifyStreaks;

  @HiveField(11)
  bool notifyBudgetWarnings;

  @HiveField(12)
  bool notifyGoalMilestones;

  @HiveField(13)
  bool notifyChallenges;

  @HiveField(14)
  bool notifySettlement;

  @HiveField(15)
  bool notifyWeeklySummary;

  @HiveField(16)
  bool notifyBalanceAlerts;

  @HiveField(17)
  bool notifyMotivational;

  AppSettingsModel({
    this.currencySymbol = 'DA',
    this.language = 'ar',
    this.isDarkMode = false,
    this.isPinEnabled = false,
    this.pin,
    this.isBiometricEnabled = false,
    this.lastCategoryUsedId,
    this.lockTimeoutSeconds = 30,
    this.notificationsEnabled = true,
    this.notifyInsights = true,
    this.notifyStreaks = true,
    this.notifyBudgetWarnings = true,
    this.notifyGoalMilestones = true,
    this.notifyChallenges = true,
    this.notifySettlement = true,
    this.notifyWeeklySummary = true,
    this.notifyBalanceAlerts = true,
    this.notifyMotivational = false,
  });

  AppSettingsModel copyWith({
    String? currencySymbol,
    String? language,
    bool? isDarkMode,
    bool? isPinEnabled,
    String? pin,
    bool? isBiometricEnabled,
    String? lastCategoryUsedId,
    int? lockTimeoutSeconds,
    bool? notificationsEnabled,
    bool? notifyInsights,
    bool? notifyStreaks,
    bool? notifyBudgetWarnings,
    bool? notifyGoalMilestones,
    bool? notifyChallenges,
    bool? notifySettlement,
    bool? notifyWeeklySummary,
    bool? notifyBalanceAlerts,
    bool? notifyMotivational,
  }) {
    return AppSettingsModel(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      pin: pin ?? this.pin,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      lastCategoryUsedId: lastCategoryUsedId ?? this.lastCategoryUsedId,
      lockTimeoutSeconds: lockTimeoutSeconds ?? this.lockTimeoutSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyInsights: notifyInsights ?? this.notifyInsights,
      notifyStreaks: notifyStreaks ?? this.notifyStreaks,
      notifyBudgetWarnings: notifyBudgetWarnings ?? this.notifyBudgetWarnings,
      notifyGoalMilestones: notifyGoalMilestones ?? this.notifyGoalMilestones,
      notifyChallenges: notifyChallenges ?? this.notifyChallenges,
      notifySettlement: notifySettlement ?? this.notifySettlement,
      notifyWeeklySummary: notifyWeeklySummary ?? this.notifyWeeklySummary,
      notifyBalanceAlerts: notifyBalanceAlerts ?? this.notifyBalanceAlerts,
      notifyMotivational: notifyMotivational ?? this.notifyMotivational,
    );
  }
}


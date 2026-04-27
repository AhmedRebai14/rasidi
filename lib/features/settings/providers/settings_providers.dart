import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../core/utils/currency_localizer.dart';
import '../data/app_settings_model.dart';

class SettingsNotifier extends StateNotifier<AppSettingsModel> {
  SettingsNotifier() : super(AppSettingsModel()) {
    _load();
  }

  void _load() {
    final box = Hive.box<AppSettingsModel>(HiveBoxes.settings);
    if (box.isNotEmpty) {
      state = box.get('settings') ?? AppSettingsModel();
    }
  }

  Future<void> _save() async {
    final box = Hive.box<AppSettingsModel>(HiveBoxes.settings);
    await box.put('settings', state);
  }

  Future<void> setCurrency(String symbol) async {
    state = state.copyWith(currencySymbol: symbol);
    await _save();
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _save();
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    await _save();
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    await _save();
  }

  Future<void> setPinEnabled(bool value, {String? pin}) async {
    state = state.copyWith(isPinEnabled: value, pin: pin);
    await _save();
  }

  Future<void> enablePin(String pin) async {
    state = state.copyWith(isPinEnabled: true, pin: pin);
    await _save();
  }

  Future<void> disablePin() async {
    state = state.copyWith(isPinEnabled: false, pin: null, isBiometricEnabled: false);
    await _save();
  }

  Future<void> changePin(String newPin) async {
    state = state.copyWith(pin: newPin);
    await _save();
  }

  bool verifyPin(String input) => state.pin == input;

  Future<void> setBiometric(bool value) async {
    state = state.copyWith(isBiometricEnabled: value);
    await _save();
  }

  Future<void> setLastCategoryUsed(String? id) async {
    state = state.copyWith(lastCategoryUsedId: id);
    await _save();
  }

  Future<void> setLockTimeout(int seconds) async {
    state = state.copyWith(lockTimeoutSeconds: seconds);
    await _save();
  }

  Future<void> setNotificationsEnabled(bool v) async {
    state = state.copyWith(notificationsEnabled: v);
    await _save();
  }

  Future<void> setNotifyInsights(bool v) async {
    state = state.copyWith(notifyInsights: v);
    await _save();
  }

  Future<void> setNotifyStreaks(bool v) async {
    state = state.copyWith(notifyStreaks: v);
    await _save();
  }

  Future<void> setNotifyBudgetWarnings(bool v) async {
    state = state.copyWith(notifyBudgetWarnings: v);
    await _save();
  }

  Future<void> setNotifyGoalMilestones(bool v) async {
    state = state.copyWith(notifyGoalMilestones: v);
    await _save();
  }

  Future<void> setNotifyChallenges(bool v) async {
    state = state.copyWith(notifyChallenges: v);
    await _save();
  }

  Future<void> setNotifySettlement(bool v) async {
    state = state.copyWith(notifySettlement: v);
    await _save();
  }

  Future<void> setNotifyWeeklySummary(bool v) async {
    state = state.copyWith(notifyWeeklySummary: v);
    await _save();
  }

  Future<void> setNotifyBalanceAlerts(bool v) async {
    state = state.copyWith(notifyBalanceAlerts: v);
    await _save();
  }

  Future<void> setNotifyMotivational(bool v) async {
    state = state.copyWith(notifyMotivational: v);
    await _save();
  }

  void refresh() => _load();
}

// ── Provider ──────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsModel>(
  (ref) => SettingsNotifier(),
);

/// Returns the currency symbol localized for the current language.
/// e.g. "TND" → "د.ت" when language is Arabic, "TND" in EN/FR.
final localizedCurrencyProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return CurrencyLocalizer.localize(settings.currencySymbol, settings.language);
});

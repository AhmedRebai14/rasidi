import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/settings_providers.dart';
import '../../../shared/services/hive_service.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/pin_pad.dart';

/// Full settings screen with preferences, security, data, and about sections
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _currencyController = TextEditingController();

  @override
  void dispose() {
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(tProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('settings_title'))),
      body: ListView(
        children: [
          // ── Preferences ────────────────────────────────
          _sectionHeader(t('settings_preferences')),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(t('settings_currency')),
            subtitle: Text(settings.currencySymbol),
            onTap: () => _showCurrencyDialog(context, settings.currencySymbol),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t('settings_language')),
            subtitle: Text(
              settings.language == 'ar'
                  ? 'العربية'
                  : settings.language == 'fr'
                      ? 'Français'
                      : 'English',
            ),
            trailing: Wrap(
              spacing: 6,
              children: [
                _langChip('ar', 'ع', settings.language),
                _langChip('en', 'EN', settings.language),
                _langChip('fr', 'FR', settings.language),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(t('settings_dark_mode')),
            value: settings.isDarkMode,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDarkMode(v),
          ),

          const Divider(),
          // ── Security ────────────────────────────────
          _sectionHeader(t('settings_security')),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: Text(t('settings_pin')),
            value: settings.isPinEnabled,
            onChanged: (v) async {
              if (v) {
                await _showSetPinDialog(context);
              } else {
                await _showDisablePinSheet(context);
              }
            },
          ),
          if (settings.isPinEnabled)
            ListTile(
              leading: const Icon(Icons.dialpad),
              title: Text(t('settings_change_pin')),
              onTap: () => _showChangePinSheet(context),
            ),
          if (settings.isPinEnabled)
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(t('lock_timeout')),
              trailing: DropdownButton<int>(
                value: [30, 60, 300].contains(settings.lockTimeoutSeconds)
                    ? settings.lockTimeoutSeconds
                    : 30,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: 30, child: Text(t('lock_timeout_30s'))),
                  DropdownMenuItem(value: 60, child: Text(t('lock_timeout_1m'))),
                  DropdownMenuItem(value: 300, child: Text(t('lock_timeout_5m'))),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(settingsProvider.notifier).setLockTimeout(v);
                  }
                },
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text(t('settings_biometric')),
            subtitle: Text(t('settings_biometric_sub')),
            value: settings.isBiometricEnabled,
            onChanged: (v) async {
              if (v) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('settings_biometric_sub'))),
                );
              } else {
                await ref
                    .read(settingsProvider.notifier)
                    .setBiometric(false);
              }
            },
          ),

          const Divider(),
          // ── Notifications ────────────────────────────────
          _sectionHeader(t('settings_notifications')),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(t('notif_setting_master')),
            value: settings.notificationsEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).setNotificationsEnabled(v),
          ),
          SwitchListTile(
            secondary: Icon(Icons.lightbulb_outline, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_insights'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyInsights,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyInsights(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.local_fire_department_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_streaks'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyStreaks,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyStreaks(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.warning_amber_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_budget'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyBudgetWarnings,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyBudgetWarnings(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.flag_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_goals'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyGoalMilestones,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyGoalMilestones(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.emoji_events_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_challenges'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyChallenges,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyChallenges(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.handshake_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_settlement'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifySettlement,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifySettlement(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.calendar_today_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_weekly'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyWeeklySummary,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyWeeklySummary(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.account_balance_wallet_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_balance'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyBalanceAlerts,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyBalanceAlerts(v) : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.celebration_outlined, color: settings.notificationsEnabled ? null : Colors.grey),
            title: Text(t('notif_setting_motivational'), style: TextStyle(color: settings.notificationsEnabled ? null : Colors.grey)),
            value: settings.notificationsEnabled && settings.notifyMotivational,
            onChanged: settings.notificationsEnabled ? (v) => ref.read(settingsProvider.notifier).setNotifyMotivational(v) : null,
          ),

          const Divider(),
          // ── Data ────────────────────────────────
          _sectionHeader(t('settings_data')),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(t('settings_clear'),
                style: const TextStyle(color: AppColors.error)),
            onTap: () => _confirmClearData(context),
          ),

          const Divider(),
          // ── About ────────────────────────────────
          _sectionHeader(t('settings_about')),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('ر',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22)),
              ),
            ),
            title: Text(AppConstants.appName,
                style: AppTextStyles.bodyMedium),
            subtitle: Text(
                '${AppConstants.appNameLatin} v1.0.0\n${AppConstants.appTagline}'),
            isThreeLine: true,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _langChip(String code, String label, String currentLang) {
    final isSelected = currentLang == code;
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _showCurrencyDialog(
      BuildContext context, String current) async {
    _currencyController.text = current;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Currency Symbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currencyController,
              decoration: const InputDecoration(hintText: 'e.g. DA, \$, €'),
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.currencyOptions.map((c) {
                return ActionChip(
                  label: Text(c),
                  onPressed: () {
                    _currencyController.text = c;
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = _currencyController.text.trim();
              if (val.isNotEmpty) {
                ref.read(settingsProvider.notifier).setCurrency(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows a PinPad bottom sheet. Returns the entered PIN or null if dismissed.
  Future<String?> _showPinSheet(BuildContext context, String title) async {
    String? result;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              PinPad(
                title: title,
                onComplete: (pin) {
                  result = pin;
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  Future<void> _showSetPinDialog(BuildContext context) async {
    final t = ref.read(tProvider);
    // Step 1: create
    final pin1 = await _showPinSheet(context, t('create_pin'));
    if (pin1 == null || !mounted) return;
    // Step 2: confirm
    final pin2 = await _showPinSheet(context, t('confirm_pin'));
    if (pin2 == null || !mounted) return;
    if (pin1 == pin2) {
      await ref.read(settingsProvider.notifier).enablePin(pin1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('pin_set_success'))),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('pin_no_match')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showDisablePinSheet(BuildContext context) async {
    final t = ref.read(tProvider);
    final pin = await _showPinSheet(context, t('disable_lock_verify'));
    if (pin == null || !mounted) return;
    if (ref.read(settingsProvider.notifier).verifyPin(pin)) {
      await ref.read(settingsProvider.notifier).disablePin();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('wrong_pin')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showChangePinSheet(BuildContext context) async {
    final t = ref.read(tProvider);
    // Step 1: verify current
    final current = await _showPinSheet(context, t('current_pin'));
    if (current == null || !mounted) return;
    if (!ref.read(settingsProvider.notifier).verifyPin(current)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('wrong_pin')), backgroundColor: Colors.red),
        );
      }
      return;
    }
    // Step 2: new pin
    final pin1 = await _showPinSheet(context, t('new_pin'));
    if (pin1 == null || !mounted) return;
    // Step 3: confirm new pin
    final pin2 = await _showPinSheet(context, t('confirm_pin'));
    if (pin2 == null || !mounted) return;
    if (pin1 == pin2) {
      await ref.read(settingsProvider.notifier).changePin(pin1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('pin_changed_success'))),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('pin_no_match')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmClearData(BuildContext context) {
    ConfirmationDialog.show(
      context,
      title: 'Clear All Data',
      message:
          'This will permanently delete ALL your sessions, transactions, categories, and savings. This cannot be undone.\n\nAre you absolutely sure?',
      confirmLabel: 'Clear Everything',
      onConfirm: () async {
        await HiveService.clearAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('All data cleared. Please restart the app.')),
          );
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/settings_providers.dart';
import '../../../shared/services/hive_service.dart';
import '../../../shared/widgets/confirmation_dialog.dart';

/// Full settings screen with preferences, security, data, and about sections
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _pinController = TextEditingController();
  final _currencyController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
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
                await ref
                    .read(settingsProvider.notifier)
                    .setPinEnabled(false);
              }
            },
          ),
          if (settings.isPinEnabled)
            ListTile(
              leading: const Icon(Icons.dialpad),
              title: Text(t('settings_change_pin')),
              onTap: () => _showSetPinDialog(context),
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

  Future<void> _showSetPinDialog(BuildContext context) async {
    _pinController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: AppConstants.pinLength,
          obscureText: true,
          decoration: const InputDecoration(
              hintText: '4-digit PIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.length ==
                  AppConstants.pinLength) {
                ref.read(settingsProvider.notifier).setPinEnabled(
                    true,
                    pin: _pinController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
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

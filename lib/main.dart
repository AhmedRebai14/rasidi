import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/hive_boxes.dart';
import 'features/settings/data/app_settings_model.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/lock/screens/lock_screen.dart';
import 'shared/services/hive_service.dart';
import 'shared/services/recurring_transaction_service.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // ── Pre-lock BEFORE runApp so GoRouter's initial redirect sees the lock ──
  // This prevents a flash of the home screen on cold start when PIN is enabled.
  final settingsBox = Hive.box<AppSettingsModel>(HiveBoxes.settings);
  final savedSettings = settingsBox.get('settings') ?? AppSettingsModel();
  if (savedSettings.isPinEnabled && (savedSettings.pin ?? '').isNotEmpty) {
    setAppLocked(true);
  }

  await RecurringTransactionService.processRecurring();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: RasidiApp()));
}

class RasidiApp extends ConsumerStatefulWidget {
  const RasidiApp({super.key});

  @override
  ConsumerState<RasidiApp> createState() => _RasidiAppState();
}

class _RasidiAppState extends ConsumerState<RasidiApp>
    with WidgetsBindingObserver {
  /// Set to true when the app moves to background, cleared on resume.
  bool _didGoToBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep Riverpod appLockedProvider in sync with the ValueNotifier
    // (used by any UI that reads the Riverpod provider directly).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (isAppLocked) {
        ref.read(appLockedProvider.notifier).state = true;
      }
      // Schedule daily notifications
      final settings = ref.read(settingsProvider);
      if (settings.notificationsEnabled) {
        await NotificationService.instance.scheduleAllDailyNotifications(
          settings: settings,
          session: null,
          transactions: const [],
          dailyLogStreak: 0,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsProvider);
    // Only act when PIN lock is actually enabled and set
    if (!settings.isPinEnabled || (settings.pin ?? '').isEmpty) return;

    if (state == AppLifecycleState.paused) {
      _didGoToBackground = true;
    }

    if (state == AppLifecycleState.resumed && _didGoToBackground) {
      _didGoToBackground = false;
      // Lock immediately — setAppLocked updates ValueNotifier which
      // GoRouter listens to via refreshListenable, no direct navigation needed.
      setAppLocked(true);
      ref.read(appLockedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'رصيدي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(settings.language),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: settings.language == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}

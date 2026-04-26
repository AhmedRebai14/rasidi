import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/lock/screens/lock_screen.dart';
import 'shared/services/hive_service.dart';
import 'shared/services/recurring_transaction_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await RecurringTransactionService.processRecurring();
  runApp(const ProviderScope(child: RasidiApp()));
}

class RasidiApp extends ConsumerStatefulWidget {
  const RasidiApp({super.key});

  @override
  ConsumerState<RasidiApp> createState() => _RasidiAppState();
}

class _RasidiAppState extends ConsumerState<RasidiApp>
    with WidgetsBindingObserver {
  DateTime? _lastPausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock on startup if PIN is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (settings.isPinEnabled) {
        ref.read(appLockedProvider.notifier).state = true;
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
    if (!settings.isPinEnabled) return;

    if (state == AppLifecycleState.paused) {
      _lastPausedAt = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      if (_lastPausedAt != null) {
        final elapsed = DateTime.now().difference(_lastPausedAt!);
        if (elapsed.inSeconds >= settings.lockTimeoutSeconds) {
          ref.read(appLockedProvider.notifier).state = true;
          final router = ref.read(appRouterProvider);
          router.go('/lock');
        }
        _lastPausedAt = null;
      }
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

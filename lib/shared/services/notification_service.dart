import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../core/l10n/app_translations.dart';
import '../../features/insights/data/insight_model.dart';
import '../../features/settings/data/app_settings_model.dart';
import '../../features/session/data/monthly_session.dart';
import '../../features/transactions/data/transaction_model.dart';

const _channelId = 'rasidi_main';
const _channelName = 'Rasidi Notifications';

/// Global notification service — call [initialize] in main().
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: _onTap,
    );
    await _createChannel();
    _initialized = true;
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Instant notifications ────────────────────────────────────────────────

  Future<void> sendBudgetWarning({
    required String categoryName,
    required double pct,
    required double spent,
    required double limit,
    required String currency,
    required String language,
  }) async {
    final isOver = pct >= 100;
    await _show(
      id: categoryName.hashCode & 0x7fffffff,
      title: isOver
          ? '🚨 $categoryName ${AppTranslations.t('notif_budget_exceeded', language)}'
          : '⚠️ $categoryName ${AppTranslations.t('notif_budget_at', language)} ${pct.round()}%',
      body: isOver
          ? '$currency ${spent.toStringAsFixed(0)} — ${AppTranslations.t('notif_limit_was', language)} $currency ${limit.toStringAsFixed(0)}'
          : '${AppTranslations.t('notif_only', language)} $currency ${(limit - spent).toStringAsFixed(0)} ${AppTranslations.t('notif_remaining', language)}',
      payload: '/analytics',
    );
  }

  Future<void> sendBalanceAlert({
    required double balance,
    required String currency,
    required String language,
  }) async {
    await _show(
      id: 9001,
      title: '🚨 ${AppTranslations.t('notif_balance_alert', language)}',
      body: '$currency ${balance.toStringAsFixed(0)}',
      payload: '/transactions',
    );
  }

  Future<void> sendGoalMilestone({
    required String goalName,
    required int pct,
    required String icon,
    required String language,
  }) async {
    await _show(
      id: (goalName.hashCode + pct) & 0x7fffffff,
      title: '$icon $goalName — $pct%!',
      body: pct == 100
          ? '🎉 ${AppTranslations.t('notif_goal_completed', language)}'
          : '🎉 ${AppTranslations.t('notif_great_progress', language)}',
      payload: '/goals',
    );
  }

  Future<void> sendXPLevelUp({
    required int xp,
    required String levelTitle,
    required String language,
  }) async {
    await _show(
      id: 8001,
      title: '⭐ ${AppTranslations.t('notif_level_up', language)}',
      body: '$levelTitle! +$xp XP',
      payload: '/goals',
    );
  }

  Future<void> sendChallengeCompleted({
    required String titleKey,
    required int xp,
    required String language,
  }) async {
    await _show(
      id: titleKey.hashCode & 0x7fffffff,
      title: '🏆 ${AppTranslations.t('notif_challenge_done', language)}',
      body: '${AppTranslations.t(titleKey, language)} — +$xp XP',
      payload: '/goals',
    );
  }

  Future<void> sendInsightNotifications(
      List<InsightModel> insights, String language) async {
    for (int i = 0; i < insights.length && i < 3; i++) {
      final insight = insights[i];
      String title = AppTranslations.t(insight.titleKey, language);
      String body = AppTranslations.t(insight.bodyKey, language);
      insight.params.forEach((k, v) {
        title = title.replaceAll('{$k}', v);
        body = body.replaceAll('{$k}', v);
      });
      await _show(
        id: insight.id.hashCode & 0x7fffffff,
        title: title,
        body: body,
        payload: insight.actionRoute ?? '/',
      );
    }
  }

  // ── Scheduled notifications ──────────────────────────────────────────────

  Future<void> scheduleAllDailyNotifications({
    required AppSettingsModel settings,
    required MonthlySession? session,
    required List<TransactionModel> transactions,
    required int dailyLogStreak,
  }) async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Stale/corrupt scheduled notification data — safe to ignore.
    }
    if (!settings.notificationsEnabled) return;

    if (settings.notifyInsights) {
      await _scheduleDaily(
        id: 1001,
        title: '💡 ${AppTranslations.t('notif_daily_insight_title', settings.language)}',
        body: AppTranslations.t('notif_daily_insight_body', settings.language),
        hour: 9,
        minute: 0,
        payload: '/',
      );
    }

    if (settings.notifyStreaks) {
      await _scheduleDaily(
        id: 1002,
        title: '🔥 ${AppTranslations.t('notif_streak_title', settings.language)}',
        body: AppTranslations.t('notif_streak_body', settings.language)
            .replaceAll('{days}', '$dailyLogStreak'),
        hour: 20,
        minute: 0,
        payload: '/transactions',
      );
    }

    if (settings.notifyWeeklySummary) {
      await _scheduleWeekly(
        id: 1003,
        title: '📊 ${AppTranslations.t('notif_weekly_title', settings.language)}',
        body: AppTranslations.t('notif_weekly_body', settings.language),
        weekday: DateTime.sunday,
        hour: 18,
        minute: 0,
        payload: '/analytics',
      );
    }

    if (settings.notifyChallenges) {
      await _scheduleDaily(
        id: 1004,
        title: '🏆 ${AppTranslations.t('notif_challenge_title', settings.language)}',
        body: AppTranslations.t('notif_challenge_body', settings.language),
        hour: 10,
        minute: 0,
        payload: '/goals',
      );
    }

    if (settings.notifySettlement && session != null) {
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0);
      for (int i = 1; i <= 3; i++) {
        final reminderDay = lastDay.subtract(Duration(days: i - 1));
        if (reminderDay.isAfter(now)) {
          await _scheduleOnce(
            id: 2000 + i,
            title:
                '📅 ${AppTranslations.t('notif_settle_title', settings.language)} $i ${i > 1 ? AppTranslations.t('days', settings.language) : AppTranslations.t('day', settings.language)}',
            body: AppTranslations.t('notif_settle_body', settings.language),
            scheduledDate: tz.TZDateTime(
              tz.local,
              reminderDay.year,
              reminderDay.month,
              reminderDay.day,
              19,
              0,
            ),
            payload: '/settlement',
          );
        }
      }
    }
  }

  Future<void> cancelStreakReminder() async {
    try {
      await _plugin.cancel(1002);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName,
            importance: Importance.defaultImportance),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName,
            importance: Importance.defaultImportance),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  Future<void> _scheduleOnce({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName,
            importance: Importance.high),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  void _onTap(NotificationResponse response) {
    // Navigation handled externally via notificationRouteProvider
    final route = response.payload;
    if (route != null && pendingNotificationRoute == null) {
      pendingNotificationRoute = route;
    }
  }
}

/// Set by NotificationService._onTap; consumed by main.dart on next resume.
String? pendingNotificationRoute;

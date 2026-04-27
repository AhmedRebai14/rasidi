import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../data/insight_model.dart';
import '../services/insight_generator.dart';
import '../../session/providers/session_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../shared/services/notification_service.dart';

class InsightNotifier extends StateNotifier<List<InsightModel>> {
  final Ref _ref;

  InsightNotifier(this._ref) : super([]) {
    _loadOrGenerate();
  }

  Box get _box => Hive.box(HiveBoxes.insights);

  Future<void> _loadOrGenerate() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _box.get('lastInsightDate') as String?;

    if (lastDate == today) {
      final cached = _box.get('cachedInsights');
      if (cached is List && cached.isNotEmpty) {
        state = cached.cast<InsightModel>();
        return;
      }
    }

    // Generate fresh
    final session = _ref.read(activeSessionProvider);
    if (session == null) return;

    final txns = _ref.read(transactionsProvider)
        .where((t) => t.sessionId == session.id)
        .toList();
    final cats = _ref.read(categoriesProvider);

    final insights = InsightGenerator().generate(
      session: session,
      transactions: txns,
      categories: cats,
    );

    state = insights;
    await _box.put('cachedInsights', insights);
    await _box.put('lastInsightDate', today);

    // Fire push notifications
    final lang = _ref.read(settingsProvider).language;
    NotificationService.instance.sendInsightNotifications(insights, lang);
  }

  void dismiss(String id) {
    state = state.map((i) => i.id == id ? i.copyWith(isDismissed: true) : i).toList();
    _box.put('cachedInsights', state);
  }

  Future<void> refresh() => _loadOrGenerate();
}

final insightsProvider =
    StateNotifierProvider<InsightNotifier, List<InsightModel>>(
  (ref) => InsightNotifier(ref),
);

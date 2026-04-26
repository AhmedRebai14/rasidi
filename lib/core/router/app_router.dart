import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/session/screens/home_screen.dart';
import '../../features/session/screens/new_session_screen.dart';
import '../../features/transactions/screens/transaction_list_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/categories/screens/add_category_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/settlement/screens/settlement_screen.dart';
import '../../features/savings/screens/savings_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/data/app_settings_model.dart';
import '../../features/lock/screens/lock_screen.dart';
import '../../core/l10n/locale_provider.dart';
import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';

// ── Lock state ──────────────────────────────────────────────────────────────

/// Single source of truth for app lock state.
/// GoRouter listens to this via [refreshListenable].
/// Calling [setAppLocked] immediately triggers a redirect evaluation.
final _lockNotifier = ValueNotifier<bool>(false);

/// Lock or unlock the app.
/// • Called with `true` from [main.dart] on resume / cold start.
/// • Called with `false` from [LockScreen] on successful PIN entry.
void setAppLocked(bool locked) => _lockNotifier.value = locked;

/// Read-only current lock state (outside Riverpod).
bool get isAppLocked => _lockNotifier.value;

/// Navigation shell — provides the bottom navigation bar
class _AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  int _currentIndex = 0;

  static const _tabs = ['/', '/transactions', '/analytics', '/savings', '/settings'];

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          context.go(_tabs[index]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: t('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: t('nav_transactions'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: t('nav_analytics'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: const Icon(Icons.savings_rounded),
            label: t('nav_savings'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: t('nav_settings'),
          ),
        ],
      ),
    );
  }
}

/// Check if onboarding has been completed
bool _hasCompletedOnboarding() {
  final box = Hive.box<AppSettingsModel>(HiveBoxes.settings);
  return box.containsKey('onboarding_done');
}

// ── GoRouter singleton ──────────────────────────────────────────────────────
// IMPORTANT: GoRouter is created ONCE and never recreated.
// Lock/unlock uses [_lockNotifier] + refreshListenable — no navigation state reset.

GoRouter? _routerInstance;

GoRouter _buildRouter() => GoRouter(
      initialLocation: _hasCompletedOnboarding() ? '/' : '/onboarding',
      refreshListenable: _lockNotifier,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        // 1. Lock takes priority (except on /onboarding and /lock itself)
        if (_lockNotifier.value && loc != '/lock' && loc != '/onboarding') {
          return '/lock';
        }
        // 2. Force onboarding if not yet completed
        if (!_hasCompletedOnboarding() && loc != '/onboarding') {
          return '/onboarding';
        }
        // 3. Skip onboarding if already completed
        if (_hasCompletedOnboarding() && loc == '/onboarding') {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/lock',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LockScreen(),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => _AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionListScreen(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/savings',
              builder: (context, state) => const SavingsScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/session/new',
          builder: (context, state) {
            final carryOver = state.extra as double?;
            return NewSessionScreen(carryOverBalance: carryOver);
          },
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/categories/add',
          builder: (context, state) => const AddCategoryScreen(),
        ),
        GoRoute(
          path: '/settlement',
          builder: (context, state) => const SettlementScreen(),
        ),
      ],
    );

/// Application router provider.
///
/// Returns the same singleton [GoRouter] instance on every call — never
/// recreated. Lock/unlock is driven by [_lockNotifier] (a [ValueNotifier]
/// used as [refreshListenable]), so the redirect fires without rebuilding
/// the entire navigation stack.
final appRouterProvider = Provider<GoRouter>((ref) {
  _routerInstance ??= _buildRouter();
  return _routerInstance!;
});

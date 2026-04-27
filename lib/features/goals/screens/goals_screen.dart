import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../data/saving_goal_model.dart';
import '../data/challenge_model.dart';
import '../providers/goals_provider.dart';
import '../providers/challenges_provider.dart';
import '../../gamification/providers/user_stats_provider.dart';
import '../../gamification/data/badge_definitions.dart';
import '../../settings/providers/settings_providers.dart';
import '../../savings/providers/savings_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/xp_toast.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('goals_title')),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? Colors.white54 : Colors.black45,
          tabs: [
            Tab(text: t('goals_tab_goals')),
            Tab(text: t('goals_tab_challenges')),
            Tab(text: t('goals_tab_badges')),
            Tab(text: t('nav_savings')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          const _GoalsTab(),
          const _ChallengesTab(),
          const _BadgesTab(),
          const _SavingsTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GOALS TAB
// ═══════════════════════════════════════════════════════════

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);

    return Scaffold(
      body: goals.isEmpty
          ? EmptyState(
              icon: Icons.flag_outlined,
              message: t('goals_empty'),
              subtitle: t('goals_empty_sub'),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: goals.length,
              itemBuilder: (ctx, i) => _GoalCard(
                goal: goals[i],
                currency: currency,
                t: t,
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_goal_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddGoalSheet(context, ref, t, currency),
        icon: const Icon(Icons.add_rounded),
        label: Text(t('goals_new')),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext ctx, WidgetRef ref,
      String Function(String) t, String currency) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheet(currency: currency),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final SavingGoalModel goal;
  final String currency;
  final String Function(String) t;

  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.t,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(goal.color);
    final pct = goal.progress;

    String subtitle;
    if (goal.isCompleted) {
      subtitle = '✅ ${t('goals_completed')}';
    } else if (goal.deadline != null) {
      final daysLeft = goal.deadline!.difference(DateTime.now()).inDays;
      subtitle = '${(pct * 100).toStringAsFixed(0)}% · $daysLeft ${t('days')} ${t('left')}';
    } else {
      subtitle = '${(pct * 100).toStringAsFixed(0)}%';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            context.push('/goals/${goal.id}', extra: goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(goal.icon,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700)),
                        Text(subtitle,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatClean(goal.currentAmount,
                            symbol: currency),
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w800, color: color),
                      ),
                      Text(
                        '/ ${CurrencyFormatter.formatClean(goal.targetAmount, symbol: currency)}',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor:
                      isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Goal Sheet ──────────────────────────────────────────────────────────

class _AddGoalSheet extends ConsumerStatefulWidget {
  final String currency;
  const _AddGoalSheet({required this.currency});

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _icon = '🎯';
  int _color = 0xFF6366F1;
  DateTime? _deadline;
  bool _saving = false;

  static const _icons = [
    '🎯','🏖️','🚗','📱','🏠','🎓','💍','✈️','🎮','🎸','📚','💻',
    '🎨','🏋️','🌍','🐶','👶','💰','🎁','🌟',
  ];
  static const _colors = [
    0xFF6366F1, 0xFF22c55e, 0xFFf97316, 0xFFef4444,
    0xFF3b82f6, 0xFF0891b2, 0xFFa855f7, 0xFFec4899,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(t('goals_new'),
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            // Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: t('goals_name')),
            ),
            const SizedBox(height: 12),
            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: t('goals_target_amount'),
                  prefixText: '${widget.currency} '),
            ),
            const SizedBox(height: 16),
            // Icon picker
            Text(t('goals_icon'),
                style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _icons.map((e) => GestureDetector(
                onTap: () => setState(() => _icon = e),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _icon == e
                        ? AppColors.primary.withAlpha(40)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: _icon == e
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                      child: Text(e,
                          style: const TextStyle(fontSize: 20))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Color picker
            Text(t('goals_color'),
                style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: _color == c
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: _color == c
                        ? [BoxShadow(
                            color: Color(c).withAlpha(100),
                            blurRadius: 8)]
                        : null,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Deadline
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(_deadline == null
                  ? t('goals_add_deadline')
                  : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(t('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || amount == null || amount <= 0) return;
    setState(() => _saving = true);
    await ref.read(goalsProvider.notifier).createGoal(
          name: name,
          targetAmount: amount,
          icon: _icon,
          color: _color,
          deadline: _deadline,
        );
    if (mounted) {
      Navigator.pop(context);
      // Show XP toast
      showXPToast(context, await ref
          .read(userStatsProvider.notifier)
          .awardXP(0, 'goal_created')); // already awarded inside createGoal
    }
  }
}

// ═══════════════════════════════════════════════════════════
// CHALLENGES TAB
// ═══════════════════════════════════════════════════════════

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengesProvider);
    final t = ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final active =
        challenges.where((c) => c.status == ChallengeStatus.active).toList();
    final available =
        challenges.where((c) => c.status == ChallengeStatus.locked).toList();
    final completed = challenges
        .where((c) => c.status == ChallengeStatus.completed)
        .toList();
    final failed =
        challenges.where((c) => c.status == ChallengeStatus.failed).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _sectionLabel(t('challenge_section_active'), isDark),
          ...active.map((c) => _ChallengeCard(challenge: c, t: t, ref: ref)),
          const SizedBox(height: 16),
        ],
        if (available.isNotEmpty) ...[
          _sectionLabel(t('challenge_section_available'), isDark),
          ...available.map((c) => _ChallengeCard(challenge: c, t: t, ref: ref)),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          _sectionLabel(t('challenge_section_completed'), isDark),
          ...completed.map((c) => _ChallengeCard(challenge: c, t: t, ref: ref)),
          const SizedBox(height: 16),
        ],
        if (failed.isNotEmpty) ...[
          _sectionLabel(t('challenge_section_failed'), isDark),
          ...failed.map((c) => _ChallengeCard(challenge: c, t: t, ref: ref)),
        ],
        if (challenges.isEmpty)
          EmptyState(
              icon: Icons.emoji_events_outlined,
              message: t('goals_empty'),
              subtitle: t('goals_empty_sub')),
      ],
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: AppTextStyles.sectionTitle
                .copyWith(color: isDark ? Colors.white70 : Colors.black54)),
      );
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final String Function(String) t;
  final WidgetRef ref;

  const _ChallengeCard(
      {required this.challenge, required this.t, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = challenge.isCompleted;
    final isActive = challenge.isActive;
    final isLocked = challenge.status == ChallengeStatus.locked;

    Color statusColor;
    if (isCompleted) statusColor = const Color(0xFF22c55e);
    else if (isActive) statusColor = AppColors.primary;
    else statusColor = Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withAlpha(isActive ? 80 : 30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.badgeIcon,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t(challenge.titleKey),
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700)),
                    Text(t(challenge.descKey),
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+${challenge.xpReward} XP',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (challenge.targetAmount != null && (isActive || isCompleted)) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: challenge.targetAmount! > 0
                    ? (challenge.currentProgress /
                            challenge.targetAmount!)
                        .clamp(0.0, 1.0)
                    : 0.0,
                backgroundColor:
                    isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
                '${challenge.currentProgress.toStringAsFixed(0)} / ${challenge.targetAmount!.toStringAsFixed(0)}',
                style: AppTextStyles.caption
                    .copyWith(color: Colors.grey)),
          ],
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(challengesProvider.notifier)
                      .startChallenge(challenge.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withAlpha(80)),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(t('challenge_start')),
                ),
              ),
            ),
          if (isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF22c55e), size: 16),
                  const SizedBox(width: 4),
                  Text(t('challenge_completed'),
                      style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF22c55e),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BADGES TAB
// ═══════════════════════════════════════════════════════════

class _BadgesTab extends ConsumerWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final t = ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: allBadges.length,
      itemBuilder: (ctx, i) {
        final badge = allBadges[i];
        final earned = stats.earnedBadges.contains(badge.id);
        return GestureDetector(
          onTap: () => _showBadgeDetail(ctx, badge, earned, t, isDark),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
              border: Border.all(
                color: earned
                    ? AppColors.primary.withAlpha(80)
                    : Colors.grey.withAlpha(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: earned ? 1.0 : 0.3,
                    child: Text(badge.icon,
                        style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    earned
                        ? t(badge.titleKey)
                        : (badge.isSecret ? '???' : t(badge.titleKey)),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: earned
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (earned)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF22c55e), size: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext ctx, BadgeDefinition badge,
      bool earned, String Function(String) t, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.icon,
                style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(earned ? t(badge.titleKey) : '???',
                style: AppTextStyles.pageTitle),
            const SizedBox(height: 8),
            Text(
              earned
                  ? t(badge.descKey)
                  : (badge.isSecret ? t('badge_secret_hint') : t(badge.descKey)),
              style: AppTextStyles.body
                  .copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!earned)
              Text(t('badge_locked'),
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GOAL DETAIL SCREEN
// ═══════════════════════════════════════════════════════════

class GoalDetailScreen extends ConsumerStatefulWidget {
  final SavingGoalModel goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailScreen> createState() =>
      _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _progressAnim = Tween<double>(begin: 0, end: widget.goal.progress)
        .animate(CurvedAnimation(
            parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get live goal from provider
    final goals = ref.watch(goalsProvider);
    final goal = goals.firstWhere(
      (g) => g.id == widget.goal.id,
      orElse: () => widget.goal,
    );
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);
    final color = Color(goal.color);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.expenseRed,
            onPressed: () => _confirmDelete(context, goal, t),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Animated progress circle
            SizedBox(
              width: 180,
              height: 180,
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: goal.progress,
                        strokeWidth: 14,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(goal.icon,
                            style: const TextStyle(fontSize: 36)),
                        Text(
                          '${(goal.progress * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.pageTitle
                              .copyWith(color: color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${CurrencyFormatter.formatClean(goal.currentAmount, symbol: currency)} / ${CurrencyFormatter.formatClean(goal.targetAmount, symbol: currency)}',
              style: AppTextStyles.sectionTitle,
            ),
            if (goal.deadline != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${t('goals_deadline')}: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddFundsSheet(context, goal, t, currency),
                icon: const Icon(Icons.add_rounded),
                label: Text(t('goals_add_funds')),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (goal.contributions.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(t('goals_history'),
                    style: AppTextStyles.sectionTitle),
              ),
              const SizedBox(height: 8),
              ...goal.contributions.reversed.map((c) => ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add_rounded, color: color, size: 18),
                    ),
                    title: Text(
                      '+${CurrencyFormatter.formatClean(c.amount, symbol: currency)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700, color: color),
                    ),
                    subtitle: c.note.isNotEmpty ? Text(c.note) : null,
                    trailing: Text(
                      '${c.date.day}/${c.date.month}/${c.date.year}',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.grey),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddFundsSheet(BuildContext ctx, SavingGoalModel goal,
      String Function(String) t, String currency) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(t('goals_add_funds'),
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                  labelText: t('amount'),
                  prefixText: '$currency '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration:
                  InputDecoration(labelText: t('note'), hintText: t('optional')),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(
                      amountCtrl.text.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) return;
                  Navigator.pop(ctx);
                  final result = await ref
                      .read(goalsProvider.notifier)
                      .addFunds(
                        goalId: goal.id,
                        amount: amount,
                        note: noteCtrl.text.trim(),
                      );
                  if (result != null && mounted) {
                    showXPToast(context, result);
                  }
                },
                child: Text(t('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, SavingGoalModel goal,
      String Function(String) t) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(t('delete')),
        content: Text(t('goals_delete_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(t('cancel'))),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: AppColors.expenseRed),
            onPressed: () => Navigator.pop(c, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
      if (mounted) context.pop();
    }
  }
}

// ═══════════════════════════════════════════════════════════
// SAVINGS TAB (Savings Pots from monthly settlements)
// ═══════════════════════════════════════════════════════════

class _SavingsTab extends ConsumerWidget {
  const _SavingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = ref.watch(savingsProvider);
    final total = ref.watch(totalSavingsProvider);
    final t = ref.watch(tProvider);
    final currency = ref.watch(localizedCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Hero total card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.incomeGreen,
                AppColors.incomeGreen.withAlpha(179),
              ],
            ),
          ),
          child: Column(
            children: [
              Text(
                t('savings_total'),
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.formatClean(total, symbol: currency),
                style: AppTextStyles.balanceHeroLight,
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: savings.isEmpty
              ? EmptyState(
                  icon: Icons.savings_outlined,
                  message: t('savings_empty'),
                  subtitle: t('savings_empty_sub'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: savings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final saving = savings[i];
                    double running = 0;
                    for (int j = savings.length - 1; j >= i; j--) {
                      running += savings[j].amount;
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.incomeGreen.withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.savings,
                              color: AppColors.incomeGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppDateUtils.formatFull(saving.date),
                                  style: AppTextStyles.bodyMedium,
                                ),
                                if (saving.note != null && saving.note!.isNotEmpty)
                                  Text(
                                    saving.note!,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  '${t('savings_cumulative')}: ${CurrencyFormatter.formatClean(running, symbol: currency)}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${CurrencyFormatter.formatClean(saving.amount, symbol: currency)}',
                            style: AppTextStyles.amountIncome,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

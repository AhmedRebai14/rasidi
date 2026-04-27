/// Static badge definition (not stored in Hive — looked up by id).
class BadgeDefinition {
  final String id;
  final String icon;
  final String titleKey;
  final String descKey;
  final bool isSecret;

  const BadgeDefinition({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.descKey,
    this.isSecret = false,
  });
}

const List<BadgeDefinition> allBadges = [
  BadgeDefinition(
    id: 'first_transaction',
    icon: '💳',
    titleKey: 'badge_first_tx',
    descKey: 'badge_first_tx_desc',
  ),
  BadgeDefinition(
    id: 'first_settlement',
    icon: '📅',
    titleKey: 'badge_first_settle',
    descKey: 'badge_first_settle_desc',
  ),
  BadgeDefinition(
    id: 'saver',
    icon: '🐷',
    titleKey: 'badge_saver',
    descKey: 'badge_saver_desc',
  ),
  BadgeDefinition(
    id: 'no_spender',
    icon: '🧘',
    titleKey: 'badge_no_spender',
    descKey: 'badge_no_spender_desc',
  ),
  BadgeDefinition(
    id: 'week_warrior',
    icon: '⚔️',
    titleKey: 'badge_week_warrior',
    descKey: 'badge_week_warrior_desc',
  ),
  BadgeDefinition(
    id: 'month_master',
    icon: '👑',
    titleKey: 'badge_month_master',
    descKey: 'badge_month_master_desc',
  ),
  BadgeDefinition(
    id: 'goal_crusher',
    icon: '🎯',
    titleKey: 'badge_goal_crusher',
    descKey: 'badge_goal_crusher_desc',
  ),
  BadgeDefinition(
    id: 'streak_king',
    icon: '🔥',
    titleKey: 'badge_streak_king',
    descKey: 'badge_streak_king_desc',
  ),
  BadgeDefinition(
    id: 'receipt_keeper',
    icon: '📷',
    titleKey: 'badge_receipt_keeper',
    descKey: 'badge_receipt_keeper_desc',
  ),
  BadgeDefinition(
    id: 'high_roller',
    icon: '�',
    titleKey: 'badge_high_roller',
    descKey: 'badge_high_roller_desc',
  ),
  BadgeDefinition(
    id: 'three_months',
    icon: '🏆',
    titleKey: 'badge_three_months',
    descKey: 'badge_three_months_desc',
  ),
  BadgeDefinition(
    id: 'rasidi_pro',
    icon: '⭐',
    titleKey: 'badge_rasidi_pro',
    descKey: 'badge_rasidi_pro_desc',
    isSecret: true,
  ),
];

BadgeDefinition? getBadge(String id) =>
    allBadges.where((b) => b.id == id).firstOrNull;

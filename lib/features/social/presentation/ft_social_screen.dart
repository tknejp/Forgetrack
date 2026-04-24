import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../features/progression/domain/progression_achievement_catalog.dart';
import '../../../features/progression/domain/progression_models.dart';
import '../../../features/progression/presentation/widgets/ft_progression_domain_theme.dart';
import '../../../features/progression/presentation/widgets/ft_progression_primitives.dart';
import '../../../features/progression/presentation/progression_l10n.dart';
import '../../../features/progression/presentation/progression_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/ft_design_tokens.dart';
import '../../../widgets/ft/ft_drag_reveal_pager.dart';
import '../application/social_provider.dart';
import '../domain/social_models.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

String _levelTitle(int level) {
  if (level >= 100) return 'Living Legend';
  if (level >= 90) return 'Realm Sovereign';
  if (level >= 80) return 'Eternal Paragon';
  if (level >= 70) return 'Astral Champion';
  if (level >= 60) return 'Titan Forger';
  if (level >= 50) return 'Mythic Ranger';
  if (level >= 40) return 'Rift Walker';
  if (level >= 30) return 'Dawn Sentinel';
  if (level >= 25) return 'Storm Herald';
  if (level >= 20) return 'Iron Warden';
  if (level >= 15) return 'Forge Knight';
  if (level >= 10) return 'Trail Vanguard';
  if (level >= 5) return 'Pathfinder';
  return 'Novice Adventurer';
}

FtDomain _domainFor(String? domain) {
  switch (domain) {
    case 'steps':
      return FtTokens.steps;
    case 'nutrition':
      return FtTokens.calories;
    case 'sleep':
      return FtTokens.sleep;
    case 'activity':
      return FtTokens.active;
    case 'body':
      return FtTokens.weight;
    default:
      return FtTokens.active;
  }
}

IconData _iconFor(String? domain) {
  switch (domain) {
    case 'steps':
      return Icons.directions_walk_rounded;
    case 'nutrition':
      return Icons.restaurant_rounded;
    case 'sleep':
      return Icons.nightlight_round;
    case 'activity':
      return Icons.bolt_rounded;
    case 'body':
      return Icons.monitor_weight_outlined;
    default:
      return Icons.workspace_premium_rounded;
  }
}

String _relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'právě teď';
  if (d.inMinutes < 60) return 'před ${d.inMinutes} min';
  if (d.inHours < 24) return 'před ${d.inHours} hod';
  if (d.inDays == 1) return 'včera';
  if (d.inDays < 7) return 'před ${d.inDays} dny';
  return DateFormat('d. M.').format(t);
}

String _fmtXp(int xp) {
  if (xp >= 100000) return '${(xp / 1000).round()}k';
  if (xp >= 10000) return '${(xp / 1000).toStringAsFixed(1)}k';
  return NumberFormat('#,##0').format(xp);
}

final Map<String, ProgressionAchievementDefinition>
    _progressionAchievementDefinitionsById = {
  for (final definition in const ProgressionAchievementCatalog().build())
    definition.id: definition,
};

// ── Leaderboard entry ─────────────────────────────────────────────────────────

class _LbEntry {
  const _LbEntry({
    required this.name,
    required this.level,
    required this.totalXp,
    required this.isMe,
    this.photoUrl,
  });
  final String name;
  final int level;
  final int totalXp;
  final bool isMe;
  final String? photoUrl;
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.size,
    this.photoUrl,
    this.color,
    this.radius,
  });

  final String name;
  final double size;
  final String? photoUrl;
  final Color? color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = color ?? FtTokens.accent;
    final r = radius ?? size * 0.28;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        color: c.withValues(alpha: 0.18),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _Initials(initials: initials, color: c, size: size),
            )
          : _Initials(initials: initials, color: c, size: size),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(
      {required this.initials, required this.color, required this.size});
  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// ── Level badge ───────────────────────────────────────────────────────────────

class _LvBadge extends StatelessWidget {
  const _LvBadge({required this.level, this.size = 36});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FtTokens.accent, FtTokens.accent.withValues(alpha: 0.55)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
            color: FtTokens.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(color: FtTokens.accentGlow, blurRadius: 12)
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 36, color: FtTokens.onSurfaceFaint),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FtTokens.onSurfaceMuted),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style:
                const TextStyle(fontSize: 12, color: FtTokens.onSurfaceFaint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class FtSocialScreen extends StatefulWidget {
  const FtSocialScreen({
    super.key,
    required this.outerController,
    this.topContentInset = 0,
  });
  final PageController outerController;
  final double topContentInset;

  @override
  State<FtSocialScreen> createState() => _FtSocialScreenState();
}

class _FtSocialScreenState extends State<FtSocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tab.index == 3 && !_tab.indexIsChanging) {
      context.read<SocialProvider>().markNotificationsRead();
    }
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();
    final pendingCount = social.incomingRequests.length;
    final unreadNotifCount = social.unreadNotificationCount;

    final showBanner = !social.backendReady ||
        !social.isReady ||
        !auth.isSignedIn ||
        social.error != null;

    return Scaffold(
      backgroundColor: FtTokens.bg,
      body: Padding(
        padding: EdgeInsets.only(top: widget.topContentInset),
        child: Column(
          children: [
            if (showBanner)
              _StatusBanner(
                backendReady: social.backendReady,
                sessionReady: social.isReady,
                signedIn: auth.isSignedIn,
                isSigningIn: auth.isBusy,
                error: social.error ?? social.backendMessage,
                onSignIn: auth.isBusy
                    ? null
                    : () => context.read<AuthProvider>().signIn(),
              ),
            _TabBar(
              controller: _tab,
              pendingCount: pendingCount,
              unreadNotifCount: unreadNotifCount,
            ),
            Expanded(
              child: FtEdgePageHandoff(
                controller: widget.outerController,
                currentPage: 3,
                targetPage: 2,
                isEnabled: () => _tab.index == 0 && !_tab.indexIsChanging,
                child: TabBarView(
                  controller: _tab,
                  children: const [
                    _FeedTab(),
                    _ActivityTab(),
                    _LeaderboardTab(),
                    _FriendsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.backendReady,
    required this.sessionReady,
    required this.signedIn,
    required this.isSigningIn,
    required this.error,
    this.onSignIn,
  });

  final bool backendReady;
  final bool sessionReady;
  final bool signedIn;
  final bool isSigningIn;
  final String error;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final String message;
    final Color color;

    if (!signedIn) {
      message = 'Přihlášení přes Google je vyžadováno pro sociální funkce.';
      color = const Color(0xFFF59E0B);
    } else if (!backendReady) {
      message = 'Firebase backend nedostupný: $error';
      color = const Color(0xFFEF4444);
    } else if (!sessionReady) {
      message = 'Připojování k sociálnímu backendu…';
      color = const Color(0xFF6B7280);
    } else {
      message = 'Chyba: $error';
      color = const Color(0xFFEF4444);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
          if (!signedIn)
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isSigningIn
                    ? context.l10n.authSigningIn
                    : context.l10n.profileContinueWithGoogle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.controller,
    required this.pendingCount,
    required this.unreadNotifCount,
  });
  final TabController controller;
  final int pendingCount;
  final int unreadNotifCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FtTokens.cardBorder)),
      ),
      child: TabBar(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        indicatorColor: FtTokens.accent,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: FtTokens.accent,
        unselectedLabelColor: FtTokens.onSurfaceMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: [
          const Tab(text: 'Feed'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Aktivita'),
                if (unreadNotifCount > 0) ...[
                  const SizedBox(width: 5),
                  _TabBadge(count: unreadNotifCount),
                ],
              ],
            ),
          ),
          const Tab(text: 'Žebříček'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Přátelé'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 5),
                  _TabBadge(count: pendingCount),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: count > 9 ? 20.0 : 14.0,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1),
      ),
    );
  }
}

// ── Feed tab ──────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final shares = social.recentShares;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'AKTIVITA PŘÁTEL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FtTokens.onSurfaceFaint,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (shares.isEmpty)
          const _Empty(
            icon: Icons.forum_outlined,
            title: 'Feed je prázdný',
            subtitle: 'Sdílené achievementy přátel se zobrazí zde.',
          )
        else
          ...shares.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FeedCard(share: s),
            ),
          ),
      ],
    );
  }
}

// ── Feed helpers ──────────────────────────────────────────────────────────────

String _emojiForAchievementId(String id) {
  switch (id) {
    case 'pathfinder_level_5':
    case 'trail_vanguard_level_10':
      return '🧭';
    case 'forge_knight_level_15':
      return '⚒️';
    case 'iron_warden_level_20':
      return '🛡️';
    case 'storm_herald_level_25':
      return '🌩️';
    case 'dawn_sentinel_level_30':
      return '🌅';
    case 'rift_walker_level_40':
      return '🌀';
    case 'mythic_ranger_level_50':
    case 'titan_forger_level_60':
    case 'astral_champion_level_70':
    case 'eternal_paragon_level_80':
    case 'realm_sovereign_level_90':
    case 'living_legend_level_100':
      return '👑';
    case 'first_reward':
      return '🏆';
    case 'reward_hunter_25':
    case 'reward_hunter_100':
      return '⚔️';
    case 'xp_100000':
    case 'xp_1000000':
      return '🔥';
    case 'steps_total_100k':
    case 'steps_total_500k':
    case 'steps_total_1000000':
    case 'steps_total_5000000':
    case 'steps_total_10000000':
      return '👟';
    case 'steps_streak_3':
      return '🔥';
    case 'steps_streak_7':
      return '⚡';
    case 'steps_streak_30':
    case 'steps_streak_100':
      return '🌟';
    case 'nutrition_streak_3':
    case 'nutrition_streak_30':
    case 'nutrition_streak_100':
    case 'nutrition_rewards_25':
      return '🥗';
    case 'sleep_total_250h':
    case 'sleep_total_1000h':
    case 'sleep_month_225h':
    case 'sleep_month_240h':
      return '🌙';
    case 'weekly_activity_mastery':
    case 'weekly_activity_4':
    case 'weekly_activity_12':
    case 'weekly_activity_24':
    case 'weekly_activity_52':
      return '💪';
    default:
      return '🏅';
  }
}

Color _colorForDifficultyString(String diff) {
  switch (diff) {
    case 'easy':
      return FtProgressionDomainTheme.achievementEasy;
    case 'medium':
      return FtProgressionDomainTheme.achievementMedium;
    case 'hard':
      return FtProgressionDomainTheme.achievementHard;
    case 'extraHard':
      return FtProgressionDomainTheme.achievementExtraHard;
    default:
      return FtTokens.accent;
  }
}

// ── Feed card ─────────────────────────────────────────────────────────────────

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.share});
  final SocialAchievementShare share;

  void _react(BuildContext context, String emoji, String? myCurrentEmoji) {
    final social = context.read<SocialProvider>();
    if (myCurrentEmoji == emoji) {
      social.removeReaction(share.id);
    } else {
      social.addReaction(share.id, emoji);
    }
  }

  void _showReactors(BuildContext context, String emoji) {
    final reactors = share.reactions.entries
        .where((e) => e.value == emoji)
        .map((e) => (
              uid: e.key,
              emoji: e.value,
              snapshot: share.reactorSnapshots[e.key],
            ))
        .toList();
    if (reactors.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactorsSheet(
        emoji: emoji,
        reactors: reactors,
        onOpenProfile: (uid, snapshot) {
          Navigator.of(context).pop();
          _openReactorProfile(context, uid, snapshot);
        },
      ),
    );
  }

  void _openReactorProfile(
    BuildContext context,
    String uid,
    SocialReactionSnapshot? snapshot,
  ) {
    final social = context.read<SocialProvider>();
    final isFriend = social.friendships
        .any((f) => f.memberUids.contains(uid) && f.memberUids.contains(social.currentUid));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => isFriend
          ? _ProfileSheet(
              initialFriend: SocialUserProfile(
                uid: uid,
                displayName: snapshot?.displayName ?? '',
                handle: '',
                email: '',
                socialEnabled: true,
                stats: const SocialUserStats(
                  level: 0,
                  totalXp: 0,
                  unlockedAchievementCount: 0,
                  claimedRewardCount: 0,
                  pendingRewardCount: 0,
                  bestStepsStreak: 0,
                  bestNutritionStreak: 0,
                ),
                photoUrl: snapshot?.photoUrl,
              ),
              watchProfile: social.watchProfileById,
              watchAchievements: social.watchFriendAchievements,
              onRemove: () async {
                await social.removeFriend(uid);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            )
          : _StrangerProfileSheet(
              uid: uid,
              displayName: snapshot?.displayName ?? '',
              photoUrl: snapshot?.photoUrl,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final myUid = social.currentUid;
    final myCurrentEmoji = share.reactions[myUid];

    final color = _colorForDifficultyString(share.achievementSnapshot.difficulty);
    final emoji = _emojiForAchievementId(share.achievementId);
    final diffLabel = switch (share.achievementSnapshot.difficulty) {
      'easy' => 'Snadný',
      'medium' => 'Střední',
      'hard' => 'Těžký',
      'extraHard' => 'Extra těžký',
      _ => '',
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [color.withValues(alpha: 0.10), FtTokens.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name + time ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(
                  name: share.actorSnapshot.displayName,
                  photoUrl: share.actorSnapshot.photoUrl,
                  size: 34,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.actorSnapshot.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.2,
                        ),
                      ),
                      const Text(
                        'odemkl(a) achievement',
                        style: TextStyle(
                          fontSize: 11,
                          color: FtTokens.onSurfaceMuted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _relativeTime(share.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: FtTokens.onSurfaceFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Achievement block ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: color.withValues(alpha: 0.28)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          share.achievementSnapshot.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          share.achievementSnapshot.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: FtTokens.onSurfaceMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (share.message?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '"${share.message!}"',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: FtTokens.onSurface,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // ── Footer: difficulty + reactions ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                if (diffLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                      border:
                          Border.all(color: color.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      diffLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                const Spacer(),
                for (final e in ['👏', '🔥', '💪']) ...[
                  _ReactionButton(
                    emoji: e,
                    count: share.reactions.values.where((v) => v == e).length,
                    active: myCurrentEmoji == e,
                    color: color,
                    onTap: () => _react(context, e, myCurrentEmoji),
                    onLongPress: () => _showReactors(context, e),
                  ),
                  if (e != '💪') const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  final String emoji;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Reactors sheet ────────────────────────────────────────────────────────────

class _ReactorsSheet extends StatelessWidget {
  const _ReactorsSheet({
    required this.emoji,
    required this.reactors,
    required this.onOpenProfile,
  });

  final String emoji;
  final List<({String uid, String emoji, SocialReactionSnapshot? snapshot})>
      reactors;
  final void Function(String uid, SocialReactionSnapshot? snapshot)
      onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: FtTokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: FtTokens.cardBorder),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FtTokens.cardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Reagovali (${reactors.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: FtTokens.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reactors.map((r) {
            final name = r.snapshot?.displayName ?? r.uid;
            return GestureDetector(
              onTap: () => onOpenProfile(r.uid, r.snapshot),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    _Avatar(
                      name: name,
                      photoUrl: r.snapshot?.photoUrl,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FtTokens.onSurface,
                        ),
                      ),
                    ),
                    Text(r.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: FtTokens.onSurfaceFaint),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Stranger profile sheet ────────────────────────────────────────────────────

class _StrangerProfileSheet extends StatefulWidget {
  const _StrangerProfileSheet({
    required this.uid,
    required this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;

  @override
  State<_StrangerProfileSheet> createState() => _StrangerProfileSheetState();
}

class _StrangerProfileSheetState extends State<_StrangerProfileSheet> {
  bool _sending = false;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: FtTokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: FtTokens.cardBorder),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FtTokens.cardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),
          _Avatar(
            name: widget.displayName,
            photoUrl: widget.photoUrl,
            size: 64,
            radius: 18,
          ),
          const SizedBox(height: 12),
          Text(
            widget.displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FtTokens.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_sending || _sent)
                  ? null
                  : () async {
                      setState(() => _sending = true);
                      await context
                          .read<SocialProvider>()
                          .sendFriendRequest(widget.uid);
                      if (mounted) {
                        setState(() {
                          _sending = false;
                          _sent = true;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: FtTokens.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_sent
                      ? Icons.check_rounded
                      : Icons.person_add_rounded),
              label: Text(
                _sent ? 'Žádost odeslána' : 'Přidat přítele',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity tab ──────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final notifications = social.notifications;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'NEDÁVNÁ AKTIVITA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FtTokens.onSurfaceFaint,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (notifications.isEmpty)
          const _Empty(
            icon: Icons.notifications_none_rounded,
            title: 'Žádné upozornění',
            subtitle: 'Zde uvidíš reakce přátel na tvoje sdílené achievementy.',
          )
        else
          ...notifications.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NotificationCard(notification: n),
              )),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});
  final SocialNotification notification;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: unread
            ? FtTokens.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unread
              ? FtTokens.accent.withValues(alpha: 0.22)
              : FtTokens.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            name: notification.actorName,
            photoUrl: notification.actorPhoto,
            size: 36,
            color: unread ? FtTokens.accent : FtTokens.onSurfaceMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 12,
                        color: FtTokens.onSurfaceMuted,
                        height: 1.4),
                    children: [
                      TextSpan(
                        text: notification.actorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: FtTokens.onSurface),
                      ),
                      const TextSpan(text: ' reagoval(a) '),
                      TextSpan(
                        text: notification.emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const TextSpan(text: ' na tvůj achievement '),
                      TextSpan(
                        text: notification.achievementTitle,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: FtTokens.accent.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      _relativeTime(notification.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: FtTokens.onSurfaceFaint),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: FtTokens.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Friends tab ───────────────────────────────────────────────────────────────

class _FriendsTab extends StatefulWidget {
  const _FriendsTab();

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  bool _reqExpanded = true;
  final Map<String, Future<SocialUserProfile?>> _reqProfiles = {};
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<SocialUserProfile?> _reqProfile(String uid) {
    return _reqProfiles.putIfAbsent(
      uid,
      () => context.read<SocialProvider>().fetchProfileById(uid),
    );
  }

  void _openProfile(SocialUserProfile friend) {
    final social = context.read<SocialProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(
        initialFriend: friend,
        watchProfile: social.watchProfileById,
        watchAchievements: social.watchFriendAchievements,
        onRemove: () async {
          await social.removeFriend(friend.uid);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        // Incoming requests
        if (social.incomingRequests.isNotEmpty) ...[
          _RequestsSection(
            requests: social.incomingRequests,
            expanded: _reqExpanded,
            onToggle: () => setState(() => _reqExpanded = !_reqExpanded),
            getProfile: _reqProfile,
            onAccept: (id) async {
              final messenger = ScaffoldMessenger.of(context);
              final social = context.read<SocialProvider>();
              await social.acceptFriendRequest(id);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    social.error == null
                        ? 'Žádost přijata.'
                        : 'Chyba: ${social.error}',
                  ),
                ),
              );
            },
            onDecline: (id) async {
              final messenger = ScaffoldMessenger.of(context);
              final social = context.read<SocialProvider>();
              await social.declineFriendRequest(id);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    social.error == null
                        ? 'Žádost odmítnuta.'
                        : 'Chyba: ${social.error}',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],

        if (social.outgoingRequests.isNotEmpty) ...[
          _OutgoingRequestsSection(
            requests: social.outgoingRequests,
            getProfile: _reqProfile,
          ),
          const SizedBox(height: 10),
        ],

        // Search
        _SearchBar(
          controller: _search,
          isSearching: social.isSearching,
          results: social.searchResults,
          onSearch: () =>
              context.read<SocialProvider>().searchUsers(_search.text),
          onAdd: (uid) async {
            final messenger = ScaffoldMessenger.of(context);
            final social = context.read<SocialProvider>();
            await social.sendFriendRequest(uid);
            if (!mounted) return;
            _search.clear();
            social.clearSearchResults();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  social.error == null
                      ? 'Žádost o přátelství odeslána.'
                      : 'Chyba: ${social.error}',
                ),
              ),
            );
          },
          onOpenProfile: _openProfile,
        ),
        const SizedBox(height: 14),

        // Friends list
        if (social.friends.isEmpty)
          const _Empty(
            icon: Icons.group_outlined,
            title: 'Žádní přátelé',
            subtitle: 'Přidej přátele vyhledáním jejich přezdívky.',
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: FtTokens.accent),
                const SizedBox(width: 8),
                Text(
                  'PŘÁTELÉ  •  ${social.friends.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: FtTokens.accent,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          ...social.friends.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _FriendCard(friend: f, onTap: () => _openProfile(f)),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Requests section ──────────────────────────────────────────────────────────

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({
    required this.requests,
    required this.expanded,
    required this.onToggle,
    required this.getProfile,
    required this.onAccept,
    required this.onDecline,
  });

  final List<SocialFriendRequest> requests;
  final bool expanded;
  final VoidCallback onToggle;
  final Future<SocialUserProfile?> Function(String uid) getProfile;
  final Future<void> Function(String id) onAccept;
  final Future<void> Function(String id) onDecline;

  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [Color(0x1AEF4444), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
              child: Row(
                children: [
                  const Icon(Icons.person_add_rounded, size: 14, color: _red),
                  const SizedBox(width: 8),
                  const Text(
                    'Žádosti o přátelství',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _red),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Center(
                      child: Text(
                        '${requests.length}',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0.5 : 0,
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: FtTokens.onSurfaceMuted),
                  ),
                ],
              ),
            ),
          ),
          // Items
          if (expanded)
            ...requests.map(
              (req) => Column(
                children: [
                  Container(height: 1, color: _red.withValues(alpha: 0.18)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                    child: FutureBuilder<SocialUserProfile?>(
                      future: getProfile(req.fromUid),
                      builder: (context, snap) {
                        final p = snap.data;
                        final name = p?.displayName.isNotEmpty == true
                            ? p!.displayName
                            : (p?.handle.isNotEmpty == true
                                ? '@${p!.handle}'
                                : req.fromUid);
                        return Row(
                          children: [
                            _Avatar(
                                name: name,
                                size: 40,
                                photoUrl: p?.photoUrl,
                                color: const Color(0xFFF97316)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: FtTokens.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    p?.handle.isNotEmpty == true
                                        ? '@${p!.handle}'
                                        : 'Chce se stát tvým přítelem',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: FtTokens.onSurfaceFaint),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                                label: 'Přijmout',
                                color: const Color(0xFF10B981),
                                onTap: () => onAccept(req.id)),
                            const SizedBox(width: 6),
                            _Chip(
                                label: 'Odmítnout',
                                color: _red,
                                onTap: () => onDecline(req.id)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OutgoingRequestsSection extends StatelessWidget {
  const _OutgoingRequestsSection({
    required this.requests,
    required this.getProfile,
  });

  final List<SocialFriendRequest> requests;
  final Future<SocialUserProfile?> Function(String uid) getProfile;

  static const _accent = FtTokens.accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FtTokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
            child: Row(
              children: [
                const Icon(Icons.send_rounded, size: 14, color: _accent),
                const SizedBox(width: 8),
                Text(
                  'Odeslané žádosti • ${requests.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < requests.length; i++) ...[
            if (i > 0) Container(height: 1, color: FtTokens.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
              child: FutureBuilder<SocialUserProfile?>(
                future: getProfile(requests[i].toUid),
                builder: (context, snap) {
                  final profile = snap.data;
                  final name = profile?.displayName.isNotEmpty == true
                      ? profile!.displayName
                      : (profile?.handle.isNotEmpty == true
                          ? '@${profile!.handle}'
                          : requests[i].toUid);
                  return Row(
                    children: [
                      _Avatar(
                        name: name,
                        size: 40,
                        photoUrl: profile?.photoUrl,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FtTokens.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              profile?.handle.isNotEmpty == true
                                  ? '@${profile!.handle}'
                                  : 'Čeká na potvrzení',
                              style: const TextStyle(
                                fontSize: 11,
                                color: FtTokens.onSurfaceFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.onSearch,
    required this.onAdd,
    required this.onOpenProfile,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<SocialUserProfile> results;
  final VoidCallback onSearch;
  final Future<void> Function(String uid) onAdd;
  final void Function(SocialUserProfile) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FtTokens.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  size: 15, color: FtTokens.onSurfaceFaint),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  style:
                      const TextStyle(fontSize: 13, color: FtTokens.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'Hledat podle přezdívky…',
                    hintStyle:
                        TextStyle(fontSize: 13, color: FtTokens.onSurfaceFaint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isSearching ? null : onSearch,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSearching
                        ? FtTokens.accent.withValues(alpha: 0.4)
                        : FtTokens.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSearching ? '…' : 'Najít',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FtTokens.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < results.length; i++) ...[
                  if (i > 0) Container(height: 1, color: FtTokens.divider),
                  _SearchResult(
                    profile: results[i],
                    onAdd: () => onAdd(results[i].uid),
                    onOpen: () => onOpenProfile(results[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult(
      {required this.profile, required this.onAdd, required this.onOpen});
  final SocialUserProfile profile;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
        child: Row(
          children: [
            _Avatar(name: profile.displayName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${profile.handle} · Level ${profile.stats.level}',
                    style: const TextStyle(
                        fontSize: 11, color: FtTokens.onSurfaceFaint),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FtTokens.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: FtTokens.accent.withValues(alpha: 0.28)),
                ),
                child: const Text(
                  'Přidat',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FtTokens.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend card ───────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.onTap});
  final SocialUserProfile friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = _levelTitle(friend.stats.level);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1, -1),
            end: const Alignment(1, 1),
            colors: [FtTokens.accent.withValues(alpha: 0.1), FtTokens.surface],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FtTokens.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            _Avatar(
                name: friend.displayName, size: 42, photoUrl: friend.photoUrl),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _LvBadge(level: friend.stats.level, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFBBF24),
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtXp(friend.stats.totalXp),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FtTokens.onSurface),
                ),
                const Text('XP',
                    style: TextStyle(
                        fontSize: 9,
                        color: FtTokens.onSurfaceFaint,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: FtTokens.onSurfaceFaint),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard tab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab();

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  bool _weekly = false;

  static const _rankColors = [
    Color(0xFFFBBF24),
    Color(0xFFCBD5E1),
    Color(0xFFCD7F32)
  ];

  List<_LbEntry> _buildList(AuthProvider auth, ProgressionProvider prog,
      List<SocialUserProfile> friends) {
    final list = <_LbEntry>[];
    if (auth.isSignedIn && auth.user != null) {
      final u = auth.user!;
      final name = u.displayName?.trim().isNotEmpty == true
          ? u.displayName!.trim()
          : u.email.split('@').first;
      list.add(_LbEntry(
          name: name,
          level: prog.profile.level,
          totalXp: prog.profile.totalXp,
          isMe: true,
          photoUrl: u.photoUrl));
    }
    for (final f in friends) {
      list.add(_LbEntry(
          name: f.displayName,
          level: f.stats.level,
          totalXp: f.stats.totalXp,
          isMe: false,
          photoUrl: f.photoUrl));
    }
    list.sort((a, b) => b.totalXp.compareTo(a.totalXp));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();
    final prog = context.watch<ProgressionProvider>();
    final entries = _buildList(auth, prog, social.friends);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        // Toggle
        Row(
          children: [
            Expanded(
                child: _ToggleBtn(
                    label: 'Tento týden',
                    active: _weekly,
                    onTap: () => setState(() => _weekly = true))),
            const SizedBox(width: 6),
            Expanded(
                child: _ToggleBtn(
                    label: 'Celkem',
                    active: !_weekly,
                    onTap: () => setState(() => _weekly = false))),
          ],
        ),
        const SizedBox(height: 10),

        if (_weekly) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FtTokens.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 32, color: FtTokens.onSurfaceFaint),
                SizedBox(height: 12),
                Text('Brzy dostupné',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.onSurfaceMuted)),
                SizedBox(height: 4),
                Text(
                  'Týdenní žebříček bude brzy dostupný.',
                  style:
                      TextStyle(fontSize: 12, color: FtTokens.onSurfaceFaint),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else if (entries.isEmpty) ...[
          const _Empty(
            icon: Icons.leaderboard_outlined,
            title: 'Žebříček je prázdný',
            subtitle: 'Přidej přátele a porovnej své výsledky.',
          ),
        ] else ...[
          if (entries.length >= 2) ...[
            _Podium(entries: entries.take(3).toList(), rankColors: _rankColors),
            const SizedBox(height: 10),
          ],
          ...entries.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _LbRow(
                      rank: e.key + 1, entry: e.value, rankColors: _rankColors),
                ),
              ),
        ],
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color:
              active ? FtTokens.accent : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: active ? FtTokens.accent : FtTokens.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : FtTokens.onSurfaceMuted),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.rankColors});
  final List<_LbEntry> entries;
  final List<Color> rankColors;

  static const _emoji = ['🥇', '🥈', '🥉'];
  static const _sizes = [50.0, 40.0, 36.0];

  @override
  Widget build(BuildContext context) {
    // 2nd | 1st | 3rd
    final order = entries.length >= 3 ? [1, 0, 2] : [1, 0];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [
            const Color(0xFFFBBF24).withValues(alpha: 0.12),
            Colors.transparent
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          const Text(
            'TOP HRÁČI',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFBBF24),
                letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: order.map((idx) {
              if (idx >= entries.length) {
                return const Expanded(child: SizedBox.shrink());
              }
              final e = entries[idx];
              final c = rankColors[idx];
              final isFirst = idx == 0;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_emoji[idx],
                        style: TextStyle(fontSize: isFirst ? 24 : 18)),
                    const SizedBox(height: 6),
                    _Avatar(
                        name: e.name,
                        size: _sizes[idx],
                        photoUrl: e.photoUrl,
                        color: c),
                    const SizedBox(height: 6),
                    Text(
                      e.name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isFirst ? 11 : 10,
                        fontWeight: isFirst ? FontWeight.w800 : FontWeight.w700,
                        color: isFirst
                            ? FtTokens.onSurface
                            : FtTokens.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_fmtXp(e.totalXp),
                        style: TextStyle(
                            fontSize: isFirst ? 13 : 11,
                            fontWeight: FontWeight.w800,
                            color: c)),
                    const Text('XP',
                        style: TextStyle(
                            fontSize: 9, color: FtTokens.onSurfaceFaint)),
                    if (e.isMe)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFBBF24).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: const Color(0xFFFBBF24)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: const Text('Ty!',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFBBF24))),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LbRow extends StatelessWidget {
  const _LbRow(
      {required this.rank, required this.entry, required this.rankColors});
  final int rank;
  final _LbEntry entry;
  final List<Color> rankColors;

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    final rankColor = isTop ? rankColors[rank - 1] : FtTokens.onSurfaceMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: entry.isMe
            ? FtTokens.accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: entry.isMe
                ? FtTokens.accent.withValues(alpha: 0.3)
                : FtTokens.cardBorder),
        boxShadow: entry.isMe
            ? [const BoxShadow(color: FtTokens.accentGlow, blurRadius: 10)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isTop
                  ? rankColor.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isTop
                      ? rankColor.withValues(alpha: 0.4)
                      : FtTokens.cardBorder),
            ),
            child: Center(
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: rankColor)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isMe ? '${entry.name} (ty)' : entry.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: entry.isMe
                        ? FtTokens.onSurface
                        : FtTokens.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Level ${entry.level}',
                    style: const TextStyle(
                        fontSize: 10, color: FtTokens.onSurfaceFaint)),
              ],
            ),
          ),
          Text(
            '${_fmtXp(entry.totalXp)} XP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: entry.isMe ? FtTokens.accent : FtTokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Friend profile sheet ──────────────────────────────────────────────────────

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({
    required this.initialFriend,
    required this.watchProfile,
    required this.watchAchievements,
    required this.onRemove,
  });
  final SocialUserProfile initialFriend;
  final Stream<SocialUserProfile?> Function(String uid) watchProfile;
  final Stream<List<SocialUnlockedAchievement>> Function(String uid)
      watchAchievements;
  final Future<void> Function() onRemove;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final Stream<SocialUserProfile?> _profileStream;
  late final Stream<List<SocialUnlockedAchievement>> _achievementsStream;

  @override
  void initState() {
    super.initState();
    _profileStream = widget.watchProfile(widget.initialFriend.uid);
    _achievementsStream = widget.watchAchievements(widget.initialFriend.uid);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: FtTokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: FtTokens.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: FtTokens.cardBorder,
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
          Expanded(
            child: StreamBuilder<SocialUserProfile?>(
              stream: _profileStream,
              initialData: widget.initialFriend,
              builder: (context, profileSnap) {
                final f = profileSnap.data ?? widget.initialFriend;
                final title = _levelTitle(f.stats.level);
                final bestStreak = [
                  f.stats.bestStepsStreak,
                  f.stats.bestNutritionStreak,
                ].reduce((a, b) => a > b ? a : b);
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-1, -1),
                            end: const Alignment(1, 1),
                            colors: [
                              FtTokens.accent.withValues(alpha: 0.16),
                              FtTokens.accent.withValues(alpha: 0.04)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: FtTokens.accent.withValues(alpha: 0.26)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Avatar(
                                name: f.displayName,
                                size: 64,
                                photoUrl: f.photoUrl,
                                radius: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.displayName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: FtTokens.onSurface,
                                        letterSpacing: -0.3),
                                  ),
                                  Text('@${f.handle}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: FtTokens.onSurfaceFaint)),
                                  const SizedBox(height: 6),
                                  Text(
                                    title.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFFBBF24),
                                        letterSpacing: 1.0),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _LvBadge(level: f.stats.level, size: 40),
                                const SizedBox(height: 6),
                                Text(
                                  _fmtXp(f.stats.totalXp),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: FtTokens.onSurface,
                                      letterSpacing: -0.5),
                                ),
                                const Text('XP',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: FtTokens.onSurfaceFaint)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _StatCell(
                              icon: Icons.shield_moon_rounded,
                              value: '${f.stats.unlockedAchievementCount}',
                              label: 'ÚSPĚCHY',
                              color: FtTokens.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCell(
                              icon: Icons.local_fire_department_rounded,
                              value: '$bestStreak d',
                              label: 'NEJL. SÉRIE',
                              color: FtTokens.active.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCell(
                              icon: Icons.directions_walk_rounded,
                              value: '${f.stats.bestStepsStreak} d',
                              label: 'KROKY SÉRIE',
                              color: FtTokens.steps.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Achievements header
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 14, color: FtTokens.accent),
                          SizedBox(width: 8),
                          Text(
                            'ÚSPĚCHY',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: FtTokens.accent,
                                letterSpacing: 1.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Achievements list
                      StreamBuilder<List<SocialUnlockedAchievement>>(
                        stream: _achievementsStream,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting &&
                              !snap.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: FtTokens.accent),
                              ),
                            );
                          }
                          final ach = snap.data ?? const [];
                          final mappedAchievements =
                              _mapSocialAchievementsToProgression(ach);
                          if (ach.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('Žádné úspěchy zatím.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: FtTokens.onSurfaceFaint)),
                            );
                          }
                          return _FriendAchievementsGrid(
                            achievements: mappedAchievements,
                            l10n: l10n,
                            progL10n: progL10n,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _RemoveFriendButton(
                          name: f.displayName, onConfirm: widget.onRemove),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveFriendButton extends StatefulWidget {
  const _RemoveFriendButton({required this.name, required this.onConfirm});
  final String name;
  final Future<void> Function() onConfirm;

  @override
  State<_RemoveFriendButton> createState() => _RemoveFriendButtonState();
}

class _RemoveFriendButtonState extends State<_RemoveFriendButton> {
  bool _loading = false;

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FtTokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Odebrat přítele',
            style: TextStyle(
                color: FtTokens.onSurface, fontWeight: FontWeight.w800)),
        content: Text(
          'Opravdu chceš odebrat ${widget.name} ze seznamu přátel?',
          style: const TextStyle(color: FtTokens.onSurfaceMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Zrušit',
                style: TextStyle(color: FtTokens.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Odebrat',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : _confirm,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFEF4444)))
            : const Text('Odebrat přítele',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: FtTokens.onSurfaceFaint,
                letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AchRow extends StatelessWidget {
  const _AchRow({required this.achievement});
  final SocialUnlockedAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final dom = _domainFor(achievement.domain);

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [dom.dim, Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dom.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: dom.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: dom.color.withValues(alpha: 0.3)),
            ),
            child:
                Icon(_iconFor(achievement.domain), size: 17, color: dom.color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: FtTokens.onSurface)),
                const SizedBox(height: 2),
                Text(achievement.description,
                    style: const TextStyle(
                        fontSize: 11, color: FtTokens.onSurfaceMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: dom.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: dom.color.withValues(alpha: 0.28)),
            ),
            child: Text('✓',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: dom.color)),
          ),
        ],
      ),
    );
  }
}

class _FriendAchievementsGrid extends StatelessWidget {
  const _FriendAchievementsGrid({
    required this.achievements,
    required this.l10n,
    required this.progL10n,
  });

  final List<ProgressionAchievement> achievements;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 620 ? 4 : 3;
        final aspectRatio = width >= 620 ? 0.98 : 0.9;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _FriendAchievementTile(
              achievement: achievements[index],
              l10n: l10n,
              progL10n: progL10n,
            );
          },
        );
      },
    );
  }
}

class _FriendAchievementTile extends StatelessWidget {
  const _FriendAchievementTile({
    required this.achievement,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final badge = _friendAchievementBadgeSpec(achievement);
    final color = badge.color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showFriendAchievementDetailsSheet(
        context,
        achievement: achievement,
        l10n: l10n,
        progL10n: progL10n,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.13),
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.27)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.emoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _friendAchievementDisplayLabel(achievement, context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FtTokens.fontSizeTiny,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendAchievementEmojiBadge extends StatelessWidget {
  const _FriendAchievementEmojiBadge({
    required this.emoji,
    required this.color,
  });

  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: color.withValues(alpha: 0.32),
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class _FriendAchievementDetailsSheet extends StatelessWidget {
  const _FriendAchievementDetailsSheet({
    required this.achievement,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final badge = _friendAchievementBadgeSpec(achievement);
    final color = badge.color;
    final locale = Localizations.localeOf(context).toString();
    final summary = _friendAchievementCompactSummary(
      achievement,
      l10n,
      progL10n,
      locale,
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: FtTokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FriendAchievementEmojiBadge(
                  emoji: badge.emoji,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progL10n.achievementTitle(achievement),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FtProgTinyPill(
                  label: l10n.progAchievementStatusUnlocked,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              progL10n.achievementDescription(achievement),
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: FtTokens.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FtProgTinyPill(
                  label: _friendAchievementDifficultyLabel(achievement, l10n),
                  color: color,
                ),
                if (achievement.ruleId != null)
                  FtProgTinyPill(
                    label: progL10n.ruleTitle(achievement.ruleId!),
                    color: color.withValues(alpha: 0.88),
                  )
                else if (achievement.domain != null)
                  FtProgTinyPill(
                    label: progL10n.domainLabel(achievement.domain!),
                    color: color.withValues(alpha: 0.88),
                  ),
              ],
            ),
            if (achievement.unlockedAt != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(
                  l10n.progQuestCompletedOn(
                    _formatAchievementDateTime(achievement.unlockedAt!, locale),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showFriendAchievementDetailsSheet(
  BuildContext context, {
  required ProgressionAchievement achievement,
  required AppLocalizations l10n,
  required ProgressionL10n progL10n,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _FriendAchievementDetailsSheet(
      achievement: achievement,
      l10n: l10n,
      progL10n: progL10n,
    ),
  );
}

@immutable
class _FriendAchievementBadgeSpec {
  const _FriendAchievementBadgeSpec({
    required this.emoji,
    required this.color,
  });

  final String emoji;
  final Color color;
}

List<ProgressionAchievement> _mapSocialAchievementsToProgression(
  List<SocialUnlockedAchievement> achievements,
) {
  final mapped = achievements.map((achievement) {
    final definition =
        _progressionAchievementDefinitionsById[achievement.achievementId];
    if (definition != null) {
      return ProgressionAchievement(
        id: definition.id,
        type: definition.type,
        difficulty: definition.difficulty,
        criterionType: definition.criterionType,
        title: definition.title,
        description: definition.description,
        targetValue: definition.targetValue,
        currentValue: definition.targetValue,
        progress: 1,
        unlocked: true,
        unlockedAt: achievement.unlockedAt,
        ruleId: definition.ruleId ?? achievement.ruleId,
        domain:
            definition.domain ?? _progressionDomainFromName(achievement.domain),
        relatedRuleIds: definition.relatedRuleIds,
      );
    }

    final fallbackDifficulty =
        _progressionAchievementDifficultyFromName(achievement.difficulty);

    return ProgressionAchievement(
      id: achievement.achievementId,
      type: _progressionAchievementTypeFromName(achievement.type),
      difficulty: fallbackDifficulty,
      criterionType: ProgressionAchievementCriterionType.rewardCountAtLeast,
      title: achievement.title,
      description: achievement.description,
      targetValue: 1,
      currentValue: 1,
      progress: 1,
      unlocked: true,
      unlockedAt: achievement.unlockedAt,
      ruleId: achievement.ruleId,
      domain: _progressionDomainFromName(achievement.domain),
    );
  }).toList(growable: false);

  mapped.sort((a, b) {
    final unlockedCompare =
        (b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (unlockedCompare != 0) return unlockedCompare;
    return a.id.compareTo(b.id);
  });
  return mapped;
}

ProgressionDomain? _progressionDomainFromName(String? value) {
  switch (value) {
    case 'steps':
      return ProgressionDomain.steps;
    case 'nutrition':
      return ProgressionDomain.nutrition;
    case 'sleep':
      return ProgressionDomain.sleep;
    case 'activity':
      return ProgressionDomain.activity;
    case 'body':
      return ProgressionDomain.body;
    default:
      return null;
  }
}

ProgressionAchievementDifficulty _progressionAchievementDifficultyFromName(
  String? value,
) {
  switch (value) {
    case 'easy':
      return ProgressionAchievementDifficulty.easy;
    case 'medium':
      return ProgressionAchievementDifficulty.medium;
    case 'hard':
      return ProgressionAchievementDifficulty.hard;
    case 'extraHard':
      return ProgressionAchievementDifficulty.extraHard;
    default:
      return ProgressionAchievementDifficulty.easy;
  }
}

ProgressionAchievementType _progressionAchievementTypeFromName(String? value) {
  switch (value) {
    case 'streak':
      return ProgressionAchievementType.streak;
    case 'mastery':
      return ProgressionAchievementType.mastery;
    case 'milestone':
    default:
      return ProgressionAchievementType.milestone;
  }
}

_FriendAchievementBadgeSpec _friendAchievementBadgeSpec(
  ProgressionAchievement achievement,
) {
  final color = FtProgressionDomainTheme.colorForAchievementDifficulty(
    achievement.difficulty,
  );
  final levelTarget = _friendAchievementLevelTarget(achievement);
  if (levelTarget != null) {
    switch (levelTarget) {
      case 5:
      case 10:
        return _FriendAchievementBadgeSpec(emoji: '🧭', color: color);
      case 15:
        return _FriendAchievementBadgeSpec(emoji: '⚒️', color: color);
      case 20:
        return _FriendAchievementBadgeSpec(emoji: '🛡️', color: color);
      case 25:
        return _FriendAchievementBadgeSpec(emoji: '🌩️', color: color);
      case 30:
        return _FriendAchievementBadgeSpec(emoji: '🌅', color: color);
      case 40:
        return _FriendAchievementBadgeSpec(emoji: '🌀', color: color);
      default:
        return _FriendAchievementBadgeSpec(emoji: '👑', color: color);
    }
  }
  switch (achievement.id) {
    case 'first_reward':
      return _FriendAchievementBadgeSpec(emoji: '🏆', color: color);
    case 'reward_hunter_25':
    case 'reward_hunter_100':
      return _FriendAchievementBadgeSpec(emoji: '⚔️', color: color);
    case 'xp_100000':
    case 'xp_1000000':
      return _FriendAchievementBadgeSpec(emoji: '✨', color: color);
    case 'steps_total_100k':
    case 'steps_total_500k':
    case 'steps_total_1000000':
    case 'steps_total_5000000':
    case 'steps_total_10000000':
      return _FriendAchievementBadgeSpec(emoji: '👟', color: color);
    case 'steps_month_300k':
    case 'steps_month_600k':
      return _FriendAchievementBadgeSpec(emoji: '🗺️', color: color);
    case 'steps_streak_3':
    case 'steps_streak_7':
    case 'steps_streak_30':
    case 'steps_streak_100':
      return _FriendAchievementBadgeSpec(emoji: '🔥', color: color);
    case 'nutrition_streak_3':
    case 'nutrition_streak_30':
    case 'nutrition_streak_100':
    case 'nutrition_rewards_25':
      return _FriendAchievementBadgeSpec(emoji: '🥗', color: color);
    case 'weekly_activity_mastery':
    case 'weekly_activity_4':
    case 'weekly_activity_12':
    case 'weekly_activity_24':
    case 'weekly_activity_52':
      return _FriendAchievementBadgeSpec(emoji: '🏃', color: color);
    case 'sleep_total_250h':
    case 'sleep_total_1000h':
    case 'sleep_month_225h':
    case 'sleep_month_240h':
      return _FriendAchievementBadgeSpec(emoji: '🌙', color: color);
    default:
      return _FriendAchievementBadgeSpec(emoji: '🏅', color: color);
  }
}

String _friendAchievementDisplayLabel(
  ProgressionAchievement achievement,
  BuildContext context,
) {
  final levelTarget = _friendAchievementLevelTarget(achievement);
  if (levelTarget != null) {
    return 'LEVEL $levelTarget';
  }
  switch (achievement.id) {
    case 'first_reward':
      return 'FIRST REWARD';
    case 'reward_hunter_25':
      return '25 REWARDS';
    case 'reward_hunter_100':
      return '100 REWARDS';
    case 'xp_100000':
      return '100K XP';
    case 'xp_1000000':
      return '1M XP';
    case 'steps_total_100k':
      return '100K STEPS';
    case 'steps_total_500k':
      return '500K STEPS';
    case 'steps_total_1000000':
      return '1M STEPS';
    case 'steps_total_5000000':
      return '5M STEPS';
    case 'steps_total_10000000':
      return '10M STEPS';
    case 'steps_month_300k':
      return '30D 300K';
    case 'steps_month_600k':
      return '30D 600K';
    case 'steps_streak_3':
      return '3 DAY STREAK';
    case 'steps_streak_7':
      return '7 DAY STREAK';
    case 'steps_streak_30':
      return '30 DAY STREAK';
    case 'steps_streak_100':
      return '100 DAY STREAK';
    case 'nutrition_streak_3':
      return '3 DAY RHYTHM';
    case 'nutrition_streak_30':
      return '30 DAY RHYTHM';
    case 'nutrition_streak_100':
      return '100 DAY RHYTHM';
    case 'nutrition_rewards_25':
      return '25 NUTRITION';
    case 'weekly_activity_mastery':
      return 'WEEKLY WIN';
    case 'weekly_activity_4':
      return '4 ACTIVITY';
    case 'weekly_activity_12':
      return '12 ACTIVITY';
    case 'weekly_activity_24':
      return '24 ACTIVITY';
    case 'weekly_activity_52':
      return '52 ACTIVITY';
    case 'sleep_total_250h':
      return '250H SLEEP';
    case 'sleep_total_1000h':
      return '1000H SLEEP';
    case 'sleep_month_225h':
      return '30D 225H';
    case 'sleep_month_240h':
      return '30D 240H';
    default:
      return ProgressionL10n(context.l10n)
          .achievementTitle(achievement)
          .toUpperCase();
  }
}

String _friendAchievementDifficultyLabel(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
) {
  switch (achievement.difficulty) {
    case ProgressionAchievementDifficulty.easy:
      return l10n.progAchievementDifficultyEasy;
    case ProgressionAchievementDifficulty.medium:
      return l10n.progAchievementDifficultyMedium;
    case ProgressionAchievementDifficulty.hard:
      return l10n.progAchievementDifficultyHard;
    case ProgressionAchievementDifficulty.extraHard:
      return l10n.progAchievementDifficultyExtraHard;
  }
}

int? _friendAchievementLevelTarget(ProgressionAchievement achievement) {
  final match = RegExp(r'_level_(\d+)$').firstMatch(achievement.id);
  return match == null ? null : int.tryParse(match.group(1)!);
}

String _friendAchievementCompactSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  ProgressionL10n progL10n,
  String locale,
) {
  switch (achievement.criterionType) {
    case ProgressionAchievementCriterionType.totalXpAtLeast:
      final levelTarget = _friendAchievementLevelTarget(achievement);
      if (levelTarget != null) return 'Level $levelTarget';
      return '${_formatCompactInt(achievement.targetValue, locale)} XP';
    case ProgressionAchievementCriterionType.rewardCountAtLeast:
      if (achievement.ruleId != null) {
        return '${achievement.targetValue}x ${progL10n.ruleTitle(achievement.ruleId!)}';
      }
      if (achievement.domain != null) {
        return '${achievement.targetValue}x ${progL10n.domainLabel(achievement.domain!)}';
      }
      return '${achievement.targetValue} ${l10n.progRewardsSectionLabel}';
    case ProgressionAchievementCriterionType.bestStreakAtLeast:
      return '${achievement.targetValue} ${l10n.progStreakDaysSuffix}';
    case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
    case ProgressionAchievementCriterionType.bestRollingWindowRuleValueAtLeast:
      return _friendAchievementTargetSummary(achievement, l10n, locale);
  }
}

String _friendAchievementTargetSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  String locale,
) {
  if (achievement.ruleId == 'daily_sleep') {
    final hours = (achievement.targetValue / 60).round();
    return '$hours h';
  }
  final unit = _friendAchievementUnitForRule(achievement.ruleId, l10n);
  return '${_formatCompactInt(achievement.targetValue, locale)} $unit';
}

String _friendAchievementUnitForRule(String? ruleId, AppLocalizations l10n) {
  switch (ruleId) {
    case 'daily_steps':
      return l10n.goalUnitSteps;
    case 'daily_calories':
      return l10n.goalUnitKcal;
    case 'daily_protein':
      return l10n.goalUnitG;
    case 'daily_sleep':
      return l10n.goalUnitHours;
    case 'weekly_activity':
      return l10n.goalUnitMins;
    default:
      return '';
  }
}

String _formatCompactInt(int value, String locale) {
  return NumberFormat.compact(locale: locale).format(value);
}

String _formatAchievementDateTime(DateTime value, String locale) {
  return DateFormat('d MMM, HH:mm', locale).format(value);
}

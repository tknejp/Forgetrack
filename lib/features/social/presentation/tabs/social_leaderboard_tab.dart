import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/auth/application/auth_provider.dart';
import '../../../../features/progression/application/progression_provider.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import '../widgets/social_cosmetic_avatar.dart';
import '../widgets/social_empty.dart';

class SocialLeaderboardTab extends StatefulWidget {
  const SocialLeaderboardTab({super.key});

  @override
  State<SocialLeaderboardTab> createState() => _SocialLeaderboardTabState();
}

class _SocialLeaderboardTabState extends State<SocialLeaderboardTab> {
  bool _weekly = false;

  static const _rankColors = [
    Color(0xFFFBBF24),
    Color(0xFFCBD5E1),
    Color(0xFFCD7F32),
  ];

  List<_LbEntry> _buildEntries(
    AuthProvider auth,
    ProgressionProvider prog,
    List<SocialUserProfile> friends,
  ) {
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
        photoUrl: u.photoUrl,
        uid: u.id,
      ));
    }
    for (final f in friends) {
      list.add(_LbEntry(
        name: f.displayName,
        level: f.stats.level,
        totalXp: f.stats.totalXp,
        isMe: false,
        photoUrl: f.photoUrl,
        uid: f.uid,
        profile: f,
      ));
    }
    list.sort((a, b) => b.totalXp.compareTo(a.totalXp));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();
    final prog = context.watch<ProgressionProvider>();
    final entries = _buildEntries(auth, prog, social.friends);
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _ToggleBtn(
                label: l10n.socialLeaderboardThisWeek,
                active: _weekly,
                onTap: () => setState(() => _weekly = true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ToggleBtn(
                label: l10n.socialLeaderboardAllTime,
                active: !_weekly,
                onTap: () => setState(() => _weekly = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_weekly) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(Tokens.radiusButton),
              border: Border.all(color: Tokens.cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 32, color: Tokens.onSurfaceFaint),
                const SizedBox(height: Tokens.spaceMd),
                Text(l10n.socialLeaderboardSoonTitle,
                    style: const TextStyle(
                        fontSize: Tokens.fontSizeBody,
                        fontWeight: FontWeight.w700,
                        color: Tokens.onSurfaceMuted)),
                const SizedBox(height: Tokens.spaceXs),
                Text(
                  l10n.socialLeaderboardSoonSubtitle,
                  style: const TextStyle(
                      fontSize: Tokens.fontSizeSmall,
                      color: Tokens.onSurfaceFaint),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else if (entries.isEmpty) ...[
          SocialEmpty(
            icon: Icons.leaderboard_outlined,
            title: l10n.socialLeaderboardEmptyTitle,
            subtitle: l10n.socialLeaderboardEmptySubtitle,
          ),
        ] else ...[
          if (entries.length >= 2) ...[
            _Podium(
              entries: entries.take(3).toList(),
              rankColors: _rankColors,
              topPlayersLabel: l10n.socialLeaderboardTopPlayers,
              youLabel: l10n.socialYouBadge,
              xpLabel: l10n.socialXpLabel,
            ),
            const SizedBox(height: 10),
          ],
          ...entries.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _LbRow(
                    rank: e.key + 1,
                    entry: e.value,
                    rankColors: _rankColors,
                    levelLabel: l10n.socialLevelLabel(e.value.level),
                    youName: l10n.socialYouSuffix(e.value.name),
                    xpLabel: l10n.socialXpLabel,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _LbEntry {
  const _LbEntry({
    required this.name,
    required this.level,
    required this.totalXp,
    required this.isMe,
    this.photoUrl,
    this.uid,
    this.profile,
  });
  final String name;
  final int level;
  final int totalXp;
  final bool isMe;
  final String? photoUrl;
  final String? uid;
  final SocialUserProfile? profile;
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({
    required this.entries,
    required this.rankColors,
    required this.topPlayersLabel,
    required this.youLabel,
    required this.xpLabel,
  });
  final List<_LbEntry> entries;
  final List<Color> rankColors;
  final String topPlayersLabel;
  final String youLabel;
  final String xpLabel;

  static const _emoji = ['🥇', '🥈', '🥉'];
  static const _sizes = [50.0, 40.0, 36.0];

  @override
  Widget build(BuildContext context) {
    final order = entries.length >= 3 ? [1, 0, 2] : [1, 0];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [
            const Color(0xFFFBBF24).withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border:
            Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            topPlayersLabel,
            style: const TextStyle(
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFBBF24),
                letterSpacing: 1.1),
          ),
          const SizedBox(height: Tokens.spaceMd),
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
                child: GestureDetector(
                  onTap: e.uid != null
                      ? () => openUserProfile(
                            context,
                            uid: e.uid!,
                            initialDisplayName: e.name,
                            initialPhotoUrl: e.photoUrl,
                          )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_emoji[idx],
                          style: TextStyle(fontSize: isFirst ? 24 : 18)),
                      const SizedBox(height: 6),
                      _LeaderboardAvatar(
                        entry: e,
                        size: _sizes[idx],
                        color: c,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e.name.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isFirst ? 11 : 10,
                          fontWeight:
                              isFirst ? FontWeight.w800 : FontWeight.w700,
                          color: isFirst
                              ? Tokens.onSurface
                              : Tokens.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(socialFmtXp(e.totalXp),
                          style: TextStyle(
                              fontSize: isFirst ? 13 : 11,
                              fontWeight: FontWeight.w800,
                              color: c)),
                      Text(xpLabel,
                          style: const TextStyle(
                              fontSize: Tokens.fontSizeTiny,
                              color: Tokens.onSurfaceFaint)),
                      if (e.isMe)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24)
                                  .withValues(alpha: 0.18),
                              borderRadius:
                                  BorderRadius.circular(Tokens.radiusProgress),
                              border: Border.all(
                                  color: const Color(0xFFFBBF24)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(youLabel,
                                style: const TextStyle(
                                    fontSize: Tokens.fontSizeTiny,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFBBF24))),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard row ───────────────────────────────────────────────────────────

class _LeaderboardAvatar extends StatelessWidget {
  const _LeaderboardAvatar({
    required this.entry,
    required this.size,
    required this.color,
  });

  final _LbEntry entry;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final uid = entry.uid;
    if (uid == null) {
      return SocialCosmeticAvatar(
        name: entry.name,
        size: size,
        photoUrl: entry.photoUrl,
        profile: entry.profile,
        color: color,
      );
    }

    final social = context.read<SocialProvider>();
    return StreamBuilder<SocialUserProfile?>(
      stream: social.watchProfileById(uid),
      initialData: entry.profile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName.trim()
            : entry.name;
        final photoUrl = profile?.photoUrl?.trim().isNotEmpty == true
            ? profile!.photoUrl
            : entry.photoUrl;
        return SocialCosmeticAvatar(
          name: name,
          size: size,
          photoUrl: photoUrl,
          profile: profile ?? entry.profile,
          color: color,
        );
      },
    );
  }
}

class _LbRow extends StatelessWidget {
  const _LbRow(
      {required this.rank,
      required this.entry,
      required this.rankColors,
      required this.levelLabel,
      required this.youName,
      required this.xpLabel});
  final int rank;
  final _LbEntry entry;
  final List<Color> rankColors;
  final String levelLabel;
  final String youName;
  final String xpLabel;

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    final rankColor = isTop ? rankColors[rank - 1] : Tokens.onSurfaceMuted;

    return GestureDetector(
      onTap: entry.uid != null
          ? () => openUserProfile(
                context,
                uid: entry.uid!,
                initialDisplayName: entry.name,
                initialPhotoUrl: entry.photoUrl,
              )
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: entry.isMe
              ? Tokens.accent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
              color: entry.isMe
                  ? Tokens.accent.withValues(alpha: 0.3)
                  : Tokens.cardBorder),
          boxShadow: entry.isMe
              ? [const BoxShadow(color: Tokens.accentGlow, blurRadius: 10)]
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
                        : Tokens.cardBorder),
              ),
              child: Center(
                child: Text('$rank',
                    style: TextStyle(
                        fontSize: Tokens.fontSizeSmall,
                        fontWeight: FontWeight.w800,
                        color: rankColor)),
              ),
            ),
            const SizedBox(width: 10),
            _LeaderboardAvatar(
              entry: entry,
              size: 34,
              color: rankColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.isMe ? youName : entry.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          entry.isMe ? Tokens.onSurface : Tokens.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(levelLabel,
                      style: const TextStyle(
                          fontSize: Tokens.fontSizeMicro,
                          color: Tokens.onSurfaceFaint)),
                ],
              ),
            ),
            Text(
              '${socialFmtXp(entry.totalXp)} $xpLabel',
              style: TextStyle(
                fontSize: Tokens.fontSizeBody,
                fontWeight: FontWeight.w800,
                color: entry.isMe ? Tokens.accent : Tokens.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle button ─────────────────────────────────────────────────────────────

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
          color: active ? Tokens.accent : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(Tokens.radiusIcon),
          border: Border.all(color: active ? Tokens.accent : Tokens.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Tokens.onSurfaceMuted),
          ),
        ),
      ),
    );
  }
}

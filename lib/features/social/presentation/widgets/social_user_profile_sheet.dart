import 'package:flutter/material.dart';
import 'package:forgetrack/features/progression/presentation/badges/progression_badge_specs.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression/domain/progression_models.dart';
import '../../../../features/progression/presentation/progression_l10n.dart';
import '../../../../features/progression/presentation/widgets/ft_progression_primitives.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/presentation/cosmetics_l10n.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_equipped_chip.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_helpers.dart';
import 'social_cosmetic_avatar.dart';
import 'social_feed_card.dart';
import 'social_lv_badge.dart';

class SocialUserProfileSheet extends StatefulWidget {
  const SocialUserProfileSheet({
    super.key,
    required this.uid,
    this.initialDisplayName,
    this.initialPhotoUrl,
  });

  final String uid;
  final String? initialDisplayName;
  final String? initialPhotoUrl;

  @override
  State<SocialUserProfileSheet> createState() => _SocialUserProfileSheetState();
}

class _SocialUserProfileSheetState extends State<SocialUserProfileSheet> {
  late final Stream<SocialUserProfile?> _profileStream;
  late final Stream<List<SocialUnlockedAchievement>> _achievementsStream;
  late final Stream<List<SocialAchievementShare>> _sharesStream;
  late final Stream<List<SocialUserProfile>> _friendsStream;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    final social = context.read<SocialProvider>();
    _profileStream = social.watchProfileById(widget.uid);
    _achievementsStream = social.watchFriendAchievements(widget.uid);
    _sharesStream = social.watchProfileShares(widget.uid);
    _friendsStream = social.watchFriendProfilesForUser(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);

    final isMe = social.currentUid == widget.uid;

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
              builder: (context, profileSnap) {
                final profile = profileSnap.data;
                final displayName =
                    profile?.displayName ?? widget.initialDisplayName ?? '';
                final photoUrl = profile?.photoUrl ?? widget.initialPhotoUrl;
                final handle = profile?.handle ?? '';
                final stats = profile?.stats;

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
                              FtTokens.accent.withValues(alpha: 0.04),
                            ],
                          ),
                          image: _profileBackgroundImage(profile),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: FtTokens.accent.withValues(alpha: 0.26)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SocialCosmeticAvatar(
                                  name: displayName,
                                  size: 64,
                                  photoUrl: photoUrl,
                                  profile: profile,
                                  radius: 18,
                                  frameOverscan: 1.16,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: FtTokens.onSurface,
                                            letterSpacing: -0.3),
                                      ),
                                      if (handle.isNotEmpty)
                                        Text('@$handle',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    FtTokens.onSurfaceFaint)),
                                      if (stats != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          ProgressionL10n(context.l10n)
                                              .levelTitle(stats.level)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFFBBF24),
                                              letterSpacing: 1.0),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (stats != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SocialLvBadge(
                                          level: stats.level, size: 40),
                                      const SizedBox(height: 6),
                                      Text(
                                        socialFmtXp(stats.totalXp),
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
                            if (!isMe && social.isFriendWith(widget.uid)) ...[
                              const SizedBox(height: 12),
                              Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                              const SizedBox(height: 10),
                              _buildActionArea(context, social, displayName),
                            ],
                          ],
                        ),
                      ),
                      if (stats != null) ...[
                        const SizedBox(height: 12),
                        _buildStats(stats),
                      ],
                      const SizedBox(height: 10),
                      _ProfileFriendsSection(stream: _friendsStream),
                      if (!isMe && !social.isFriendWith(widget.uid)) ...[
                        const SizedBox(height: 10),
                        _buildActionArea(context, social, displayName),
                      ],
                      _ProfileCosmeticsSection(profile: profile),
                      const SizedBox(height: 16),
                      const _SectionTitle(
                        icon: Icons.push_pin_rounded,
                        title: 'PRIPNUTE ACHIEVEMENTY',
                      ),
                      const SizedBox(height: 10),
                      _PinnedAchievementsSection(
                        profile: profile,
                        isMe: isMe,
                        stream: _achievementsStream,
                        l10n: l10n,
                        progL10n: progL10n,
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(
                        icon: Icons.forum_rounded,
                        title: 'SDILENE PRISPEVKY',
                      ),
                      const SizedBox(height: 10),
                      _ProfileSharesSection(
                        stream: _sharesStream,
                      ),
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

  Widget _buildStats(SocialUserStats stats) {
    final bestStreak = [
      stats.bestStepsStreak,
      stats.bestNutritionStreak,
    ].reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            icon: Icons.shield_moon_rounded,
            value: '${stats.unlockedAchievementCount}',
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
            value: '${stats.bestStepsStreak} d',
            label: 'KROKY SÉRIE',
            color: FtTokens.steps.color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    SocialProvider social,
    String displayName,
  ) {
    final isFriend = social.isFriendWith(widget.uid);
    final hasPending = social.getPendingRequestTo(widget.uid) != null;

    if (isFriend) {
      return _RemoveFriendButton(
        name: displayName,
        onConfirm: () async {
          final nav = Navigator.of(context);
          await social.removeFriend(widget.uid);
          if (mounted) nav.pop();
        },
      );
    }
    if (hasPending) {
      return const _PendingRequestChip();
    }
    return _AddFriendButton(
      busy: _actionBusy,
      onTap: () async {
        setState(() => _actionBusy = true);
        await social.sendFriendRequest(widget.uid);
        if (mounted) setState(() => _actionBusy = false);
      },
    );
  }
}

// ── Action area widgets ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FtTokens.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: FtTokens.accent,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _PinnedAchievementsSection extends StatelessWidget {
  const _PinnedAchievementsSection({
    required this.profile,
    required this.isMe,
    required this.stream,
    required this.l10n,
    required this.progL10n,
  });

  final SocialUserProfile? profile;
  final bool isMe;
  final Stream<List<SocialUnlockedAchievement>> stream;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final pinnedIds = profile?.pinnedAchievementIds ?? const [];
    if (pinnedIds.isEmpty) {
      return _ProfileEmptyLine(
        text: isMe
            ? 'Zatim nemas nic pripnuteho. Otevri detail achievementu a pripni ho na profil.'
            : 'Zadne pripnute achievementy.',
      );
    }

    return StreamBuilder<List<SocialUnlockedAchievement>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _ProfileSectionLoader();
        }

        final achievements = mapSocialAchievementsToProgression(
          snap.data ?? const [],
        );
        final byId = {
          for (final achievement in achievements) achievement.id: achievement,
        };
        final pinned = <ProgressionAchievement>[];
        for (final id in pinnedIds) {
          final achievement = byId[id];
          if (achievement != null) pinned.add(achievement);
        }

        if (pinned.isEmpty) {
          return const _ProfileEmptyLine(
            text: 'Pripnute achievementy uz nejsou dostupne.',
          );
        }

        return _FriendAchievementsGrid(
          achievements: pinned,
          l10n: l10n,
          progL10n: progL10n,
        );
      },
    );
  }
}

class _ProfileSharesSection extends StatelessWidget {
  const _ProfileSharesSection({required this.stream});

  final Stream<List<SocialAchievementShare>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SocialAchievementShare>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _ProfileSectionLoader();
        }

        final shares = snap.data ?? const [];
        if (shares.isEmpty) {
          return const _ProfileEmptyLine(
            text: 'Zadne sdilene prispevky zatim.',
          );
        }

        return Column(
          children: [
            for (final share in shares)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SocialFeedCard(share: share),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileCosmeticsSection extends StatelessWidget {
  const _ProfileCosmeticsSection({required this.profile});

  final SocialUserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final cosmetics = socialProfileExtraCosmetics(profile);
    if (cosmetics.isEmpty) return const SizedBox.shrink();

    final l10n = CosmeticsL10n(AppLocalizations.of(context));
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'KOSMETIKA',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final definition in cosmetics)
                CosmeticEquippedChip(
                  definition: definition,
                  l10n: l10n,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileFriendsSection extends StatefulWidget {
  const _ProfileFriendsSection({required this.stream});

  final Stream<List<SocialUserProfile>> stream;

  @override
  State<_ProfileFriendsSection> createState() => _ProfileFriendsSectionState();
}

class _ProfileFriendsSectionState extends State<_ProfileFriendsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SocialUserProfile>>(
      stream: widget.stream,
      builder: (context, snap) {
        final loading =
            snap.connectionState == ConnectionState.waiting && !snap.hasData;
        final friends = snap.data ?? const <SocialUserProfile>[];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: friends.isEmpty
                    ? null
                    : () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: FtTokens.active.dim,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color:
                                FtTokens.active.color.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          size: 16,
                          color: FtTokens.active.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'PRATELE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: FtTokens.onSurfaceFaint,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                      if (loading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FtTokens.accent,
                          ),
                        )
                      else
                        Text(
                          '${friends.length}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: FtTokens.active.color,
                          ),
                        ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 180),
                        turns: _expanded ? 0.5 : 0,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: FtTokens.onSurfaceFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _ProfileFriendList(friends: friends),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileFriendList extends StatelessWidget {
  const _ProfileFriendList({required this.friends});

  final List<SocialUserProfile> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Text(
          'Zadni pratele zatim.',
          style: TextStyle(
            fontSize: 12,
            color: FtTokens.onSurfaceFaint,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        children: [
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 6),
          for (final friend in friends) _ProfileFriendRow(friend: friend),
        ],
      ),
    );
  }
}

class _ProfileFriendRow extends StatelessWidget {
  const _ProfileFriendRow({required this.friend});

  final SocialUserProfile friend;

  @override
  Widget build(BuildContext context) {
    final title = ProgressionL10n(context.l10n).levelTitle(friend.stats.level);
    final subtitle = friend.handle.isEmpty
        ? 'Level ${friend.stats.level} $title'
        : '@${friend.handle} - Level ${friend.stats.level} $title';

    return InkWell(
      onTap: () => openUserProfile(
        context,
        uid: friend.uid,
        initialDisplayName: friend.displayName,
        initialPhotoUrl: friend.photoUrl,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Row(
          children: [
            SocialCosmeticAvatar(
              name: friend.displayName,
              size: 36,
              photoUrl: friend.photoUrl,
              profile: friend,
              radius: 11,
            ),
            const SizedBox(width: 10),
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
                      fontWeight: FontWeight.w800,
                      color: FtTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: FtTokens.onSurfaceFaint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: FtTokens.onSurfaceFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionLoader extends StatelessWidget {
  const _ProfileSectionLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: FtTokens.accent,
        ),
      ),
    );
  }
}

DecorationImage? _profileBackgroundImage(SocialUserProfile? profile) {
  final background =
      socialBackgroundDefinition(profile?.equippedCosmetics.backgroundId);
  if (background == null) return null;
  final assetPath = CosmeticsConfig.standard().resolveAssetPath(
    background.previewAssetKey ?? background.assetKey,
  );
  if (assetPath == null) return null;
  return DecorationImage(
    image: AssetImage(assetPath),
    fit: BoxFit.cover,
    opacity: 0.18,
  );
}

class _ProfileEmptyLine extends StatelessWidget {
  const _ProfileEmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: FtTokens.onSurfaceFaint,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AddFriendButton extends StatelessWidget {
  const _AddFriendButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: FtTokens.accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.person_add_rounded),
        label: const Text('Přidat přítele',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PendingRequestChip extends StatelessWidget {
  const _PendingRequestChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: FtTokens.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtTokens.accent.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: FtTokens.accent),
          SizedBox(width: 8),
          Text('Žádost odeslána',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FtTokens.accent)),
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
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
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
    return GestureDetector(
      onTap: _loading ? null : _confirm,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          if (_loading)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: Color(0x88EF4444)),
            )
          else
            const Icon(Icons.person_remove_rounded,
                size: 13, color: Color(0x88EF4444)),
          const SizedBox(width: 6),
          const Text(
            'Odebrat přítele',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0x88EF4444),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
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

// ── Achievement grid ──────────────────────────────────────────────────────────

class _FriendAchievementsGrid extends StatelessWidget {
  const _FriendAchievementsGrid({
    required this.achievements,
    required this.l10n,
    required this.progL10n,
  });

  final List<ProgressionAchievement> achievements;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  static const _difficultyOrder = {
    'extraHard': 0,
    'hard': 1,
    'medium': 2,
    'easy': 3,
  };

  @override
  Widget build(BuildContext context) {
    final sorted = List<ProgressionAchievement>.from(achievements)
      ..sort((a, b) {
        final aOrder =
            _difficultyOrder[a.difficulty.toString().split('.').last] ?? 99;
        final bOrder =
            _difficultyOrder[b.difficulty.toString().split('.').last] ?? 99;
        return aOrder.compareTo(bOrder);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 620 ? 4 : 3;
        final aspectRatio = width >= 620 ? 0.98 : 0.9;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _FriendAchievementTile(
              achievement: sorted[index],
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
    final badge = achievementBadgeSpec(achievement);
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
                friendAchievementDisplayLabel(achievement, context),
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
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
    final badge = achievementBadgeSpec(achievement);
    final color = badge.color;
    final locale = Localizations.localeOf(context).toString();
    final summary = friendAchievementCompactSummary(
      achievement,
      l10n,
      progL10n,
      locale,
    );
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: FtTokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 22),
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
                  label: friendAchievementDifficultyLabel(achievement, l10n),
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
                    formatAchievementDateTime(achievement.unlockedAt!, locale),
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

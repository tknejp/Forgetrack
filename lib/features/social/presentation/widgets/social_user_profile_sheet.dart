import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression/domain/progression_models.dart';
import '../../../../features/progression/presentation/progression_l10n.dart';
import '../../../../features/progression/presentation/widgets/progression_level_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/presentation/cosmetics_l10n.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_equipped_chip.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'social_cosmetic_avatar.dart';
import 'social_feed_card.dart';
import 'social_lv_badge.dart';
import 'social_profile_achievement_grid.dart';
import 'social_profile_friends_section.dart';

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
        color: Tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Tokens.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Tokens.cardBorder,
                  borderRadius: BorderRadius.circular(Tokens.radiusProgress)),
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
                              Tokens.accent.withValues(alpha: 0.16),
                              Tokens.accent.withValues(alpha: 0.04),
                            ],
                          ),
                          image: _profileBackgroundImage(profile),
                          borderRadius:
                              BorderRadius.circular(Tokens.radiusCard),
                          border: Border.all(
                              color: Tokens.accent.withValues(alpha: 0.26)),
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
                                const SizedBox(width: Tokens.spaceMd),
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
                                            color: Tokens.onSurface,
                                            letterSpacing: -0.3),
                                      ),
                                      if (handle.isNotEmpty)
                                        Text('@$handle',
                                            style: const TextStyle(
                                                fontSize:
                                                    Tokens.fontSizeCaption,
                                                color: Tokens.onSurfaceFaint)),
                                      if (stats != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          ProgressionL10n(context.l10n)
                                              .levelTitle(stats.level)
                                              .toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w800,
                                              color: progressionLevelAccent(
                                                stats.level,
                                              ),
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
                                            color: Tokens.onSurface,
                                            letterSpacing: -0.5),
                                      ),
                                      Text(l10n.socialXpLabel,
                                          style: const TextStyle(
                                              fontSize: Tokens.fontSizeTiny,
                                              color: Tokens.onSurfaceFaint)),
                                    ],
                                  ),
                              ],
                            ),
                            if (!isMe && social.isFriendWith(widget.uid)) ...[
                              const SizedBox(height: Tokens.spaceMd),
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
                        const SizedBox(height: Tokens.spaceMd),
                        _buildStats(stats),
                      ],
                      const SizedBox(height: 10),
                      ProfileFriendsSection(stream: _friendsStream),
                      if (!isMe && !social.isFriendWith(widget.uid)) ...[
                        const SizedBox(height: 10),
                        _buildActionArea(context, social, displayName),
                      ],
                      _ProfileCosmeticsSection(profile: profile),
                      const SizedBox(height: Tokens.spaceLg),
                      _SectionTitle(
                        icon: Icons.push_pin_rounded,
                        title: l10n.socialProfilePinnedAchievements,
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
                      _SectionTitle(
                        icon: Icons.forum_rounded,
                        title: l10n.socialProfileSharedPosts,
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
    final l10n = context.l10n;
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
            label: l10n.socialProfileStatsAchievements,
            color: Tokens.accent,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _StatCell(
            icon: Icons.local_fire_department_rounded,
            value: l10n.socialDaysShort(bestStreak),
            label: l10n.socialProfileStatsBestStreak,
            color: Tokens.active.color,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _StatCell(
            icon: Icons.directions_walk_rounded,
            value: l10n.socialDaysShort(stats.bestStepsStreak),
            label: l10n.socialProfileStatsStepsStreak,
            color: Tokens.steps.color,
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
        Icon(icon, size: 14, color: Tokens.accent),
        const SizedBox(width: Tokens.spaceSm),
        Text(
          title,
          style: const TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
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
        text: isMe ? l10n.socialPinnedEmptyMine : l10n.socialPinnedEmptyOther,
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
          return _ProfileEmptyLine(
            text: l10n.socialPinnedUnavailable,
          );
        }

        return FriendAchievementsGrid(
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
          return _ProfileEmptyLine(
            text: context.l10n.socialSharedPostsEmpty,
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
          _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: context.l10n.socialProfileCosmetics,
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

class _ProfileSectionLoader extends StatelessWidget {
  const _ProfileSectionLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Tokens.accent,
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
          color: Tokens.onSurfaceFaint,
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
          backgroundColor: Tokens.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Tokens.radiusInner)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.person_add_rounded),
        label: Text(context.l10n.socialAddFriend,
            style: const TextStyle(
                fontSize: Tokens.fontSizeBody, fontWeight: FontWeight.w700)),
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
        color: Tokens.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: Tokens.accent),
          const SizedBox(width: Tokens.spaceSm),
          Text(context.l10n.socialRequestSent,
              style: const TextStyle(
                  fontSize: Tokens.fontSizeBody,
                  fontWeight: FontWeight.w700,
                  color: Tokens.accent)),
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
        backgroundColor: Tokens.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusButton)),
        title: Text(context.l10n.socialRemoveFriendConfirmTitle,
            style: const TextStyle(
                color: Tokens.onSurface, fontWeight: FontWeight.w800)),
        content: Text(
          context.l10n.socialRemoveFriendConfirmBody(widget.name),
          style: const TextStyle(
              color: Tokens.onSurfaceMuted, fontSize: Tokens.fontSizeBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.socialCancel,
                style: const TextStyle(color: Tokens.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.socialRemoveFriend,
                style: const TextStyle(
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
              content: Text(context.l10n.socialErrorWithMessage('$e')),
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
          Text(
            context.l10n.socialRemoveFriend,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
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
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
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
                color: Tokens.onSurfaceFaint,
                letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

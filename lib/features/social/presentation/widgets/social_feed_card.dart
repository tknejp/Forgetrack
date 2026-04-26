import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression/presentation/widgets/ft_achievement_badge_spec.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_helpers.dart';
import 'social_avatar.dart';

class SocialFeedCard extends StatelessWidget {
  const SocialFeedCard({super.key, required this.share});
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
          openUserProfile(
            context,
            uid: uid,
            initialDisplayName: snapshot?.displayName,
            initialPhotoUrl: snapshot?.photoUrl,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final myUid = social.currentUid;
    final myCurrentEmoji = share.reactions[myUid];

    final color =
        colorForDifficultyString(share.achievementSnapshot.difficulty);
    final emoji = achievementEmojiForId(share.achievementId);
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
                GestureDetector(
                  onTap: () => openUserProfile(
                    context,
                    uid: share.actorUid,
                    initialDisplayName: share.actorSnapshot.displayName,
                    initialPhotoUrl: share.actorSnapshot.photoUrl,
                  ),
                  child: SocialAvatar(
                    name: share.actorSnapshot.displayName,
                    photoUrl: share.actorSnapshot.photoUrl,
                    size: 34,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => openUserProfile(
                          context,
                          uid: share.actorUid,
                          initialDisplayName: share.actorSnapshot.displayName,
                          initialPhotoUrl: share.actorSnapshot.photoUrl,
                        ),
                        child: Text(
                          share.actorSnapshot.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                            height: 1.2,
                          ),
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
                  socialRelativeTime(share.createdAt),
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
                      border:
                          Border.all(color: color.withValues(alpha: 0.28)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child:
                          Text(emoji, style: const TextStyle(fontSize: 24)),
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
                      border: Border.all(
                          color: color.withValues(alpha: 0.28)),
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
                  SocialReactionButton(
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

// ── Reaction button ───────────────────────────────────────────────────────────

class SocialReactionButton extends StatelessWidget {
  const SocialReactionButton({
    super.key,
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
                    SocialAvatar(
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

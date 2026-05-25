import 'package:flutter/material.dart';

/// Inline `@handle · Přátelé N` row rendered above the level + title
/// label on the profile hero card.
///
/// Both segments share the muted "metadata" typography (no pill
/// chrome) so the bar reads as a single subtitle strip — but each is
/// its own tap target with a comfortable separator gutter so the
/// player can't accidentally hit one when reaching for the other.
/// The level + title pill ([ProfileHeroLevelTitleLabel]) is
/// positioned separately by the parent so it can span the full card
/// width and avoid being ellipsized by the emblem grid sitting in
/// the top-right corner. The display name lives in the screen's top
/// app bar (see `social_user_profile_screen.dart`).
class ProfileHeroIdentityBlock extends StatelessWidget {
  const ProfileHeroIdentityBlock({
    super.key,
    required this.handle,
    required this.isMe,
    required this.onEditHandle,
    required this.friendCount,
    required this.onTapFriendChip,
    required this.friendsChipLabel,
  });

  final String handle;
  final bool isMe;
  final VoidCallback? onEditHandle;
  final int? friendCount;
  final VoidCallback? onTapFriendChip;
  final String friendsChipLabel;

  static const _metaTextStyle = TextStyle(
    color: Color.fromARGB(255, 124, 122, 136),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final hasFriends = friendCount != null && onTapFriendChip != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: _HandleSegment(
            handle: handle,
            isMe: isMe,
            onEditHandle: onEditHandle,
          ),
        ),
        if (hasFriends) ...[
          // Separator dot sits inside its own horizontal padding so
          // the two tap targets are physically separated — taps on
          // the dot itself fall through to the underlying surface
          // rather than ambiguously hitting either segment.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('·', style: _metaTextStyle),
          ),
          _FriendsSegment(
            count: friendCount!,
            onTap: onTapFriendChip!,
            label: friendsChipLabel,
          ),
        ],
      ],
    );
  }
}

/// `@handle` with an optional edit-pencil suffix when the viewing
/// user owns the profile. Wrapped in an `InkWell` so own-profile
/// players get a tap-to-edit affordance; foreign profiles render the
/// same text as a static label.
class _HandleSegment extends StatelessWidget {
  const _HandleSegment({
    required this.handle,
    required this.isMe,
    required this.onEditHandle,
  });

  final String handle;
  final bool isMe;
  final VoidCallback? onEditHandle;

  @override
  Widget build(BuildContext context) {
    final handleLabel = Text(
      '@$handle',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ProfileHeroIdentityBlock._metaTextStyle,
    );

    if (!(isMe && onEditHandle != null)) {
      return handleLabel;
    }

    return InkWell(
      onTap: onEditHandle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: handleLabel),
            const SizedBox(width: 6),
            Icon(
              Icons.edit_rounded,
              size: 12,
              color: const Color.fromARGB(255, 124, 122, 136)
                  .withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// `Přátelé N` rendered in the same muted handle style. Tappable so
/// the player can still open the friends list — but lives inline
/// with the handle instead of as a separate pill chip so the hero
/// header reads as one subtitle row.
class _FriendsSegment extends StatelessWidget {
  const _FriendsSegment({
    required this.count,
    required this.onTap,
    required this.label,
  });

  final int count;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '$label $count',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ProfileHeroIdentityBlock._metaTextStyle,
        ),
      ),
    );
  }
}

/// Single-line `LVL N · TITLE` label tinted by the level's rarity
/// accent, with a soft same-colour glow behind the text. Pure
/// typography — no pill chrome — so it sits inside the fantasy
/// aesthetic instead of looking like a modern app UI chip.
class ProfileHeroLevelTitleLabel extends StatelessWidget {
  const ProfileHeroLevelTitleLabel({
    super.key,
    required this.level,
    required this.title,
    required this.accent,
  });

  final int level;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shadows = <Shadow>[
      // Crisp single-pixel drop — engraved-letter depth.
      const Shadow(
        color: Color(0xFF000000),
        blurRadius: 0,
        offset: Offset(0, 1),
      ),
      // Bigger soft drop — separates the label from any background
      // detail right under it (companion glow, scene lanterns, …).
      const Shadow(
        color: Color(0xE6000000),
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
      // Wide ambient halo — pushes the label visually forward across
      // the whole hero card width so the eye lands on it first.
      const Shadow(
        color: Color(0x99000000),
        blurRadius: 24,
      ),
      // Accent-colored glow — ties the typography to the rarity
      // accent so the row reads as the "your tier" banner.
      Shadow(
        color: accent.withValues(alpha: 0.70),
        blurRadius: 5,
      ),
      Shadow(
        color: accent.withValues(alpha: 0.35),
        blurRadius: 12,
      ),
    ];

    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: accent,
          height: 1.0,
          shadows: shadows,
        ),
        children: [
          TextSpan(
            text: 'LVL $level',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          TextSpan(
            text: '  ⚔  ',
            style: TextStyle(
              color: accent.withValues(alpha: 0.85),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: title.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}


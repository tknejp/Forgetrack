import 'package:flutter/material.dart';

class ProfileHeroIdentityBlock extends StatelessWidget {
  const ProfileHeroIdentityBlock({
    super.key,
    required this.displayName,
    required this.handle,
    required this.level,
    required this.levelTitle,
    required this.levelAccent,
    required this.isMe,
    required this.onEditHandle,
    required this.friendCount,
    required this.onTapFriendChip,
    required this.friendsChipLabel,
  });

  final String displayName;
  final String handle;
  final int level;
  final String levelTitle;
  final Color levelAccent;
  final bool isMe;
  final VoidCallback? onEditHandle;
  final int? friendCount;
  final VoidCallback? onTapFriendChip;
  final String friendsChipLabel;

  @override
  Widget build(BuildContext context) {
    const handleText = TextStyle(
      color: Color.fromARGB(255, 124, 122, 136),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final handleLabel = Text(
      '@$handle',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: handleText,
    );

    final Widget handleWidget;
    if (isMe && onEditHandle != null) {
      handleWidget = InkWell(
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
                color: const Color.fromARGB(255, 124, 122, 136).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      );
    } else {
      handleWidget = handleLabel;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LevelTitleLabel(
          level: level,
          title: levelTitle,
          accent: levelAccent,
        ),
        const SizedBox(height: 4),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF5F3FF),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.52, // -0.02em ≈ 26 * -0.02
            height: 1.05,
            shadows: [
              Shadow(
                color: Color(0xA6000000), // rgba(0,0,0,0.65)
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        handleWidget,
        if (friendCount != null && onTapFriendChip != null) ...[
          const SizedBox(height: 8),
          _FriendsChip(
            count: friendCount!,
            onTap: onTapFriendChip!,
            label: friendsChipLabel,
          ),
        ],
      ],
    );
  }
}

/// Single-line `LVL N · TITLE` label tinted by the level's rarity
/// accent, with a soft same-colour glow behind the text. Pure
/// typography — no pill chrome — so it sits inside the fantasy
/// aesthetic instead of looking like a modern app UI chip.
class _LevelTitleLabel extends StatelessWidget {
  const _LevelTitleLabel({
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
      // Hard one-pixel drop — engraved-letter depth.
      const Shadow(
        color: Color(0xFF000000),
        blurRadius: 0,
        offset: Offset(0, 1),
      ),
      const Shadow(
        color: Color(0xCC000000),
        blurRadius: 6,
        offset: Offset(0, 3),
      ),
      const Shadow(
        color: Color(0x66000000),
        blurRadius: 18,
      ),
      Shadow(
        color: accent.withValues(alpha: 0.55),
        blurRadius: 3,
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
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          TextSpan(
            text: '  ⚔  ',
            style: TextStyle(
              color: accent.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _FriendsChip extends StatelessWidget {
  const _FriendsChip({
    required this.count,
    required this.onTap,
    required this.label,
  });

  final int count;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 12,
                  color: Color(0xCCFFFFFF),
                ),
                const SizedBox(width: 5),
                Text(
                  '$label · $count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xCCFFFFFF),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Muted "metadata" typography shared by the @handle + friends row
/// pieces. Top-level so the segments can use it without depending on
/// a particular parent widget.
const TextStyle _metaTextStyle = TextStyle(
  color: Color.fromARGB(255, 124, 122, 136),
  fontSize: 12,
  fontWeight: FontWeight.w500,
);

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
      style: _metaTextStyle,
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

/// Inline `@handle · Přátelé N` row rendered as the app bar's
/// subtitle (underneath the player's display name). Both segments
/// share the muted "metadata" typography and sit side-by-side so the
/// strip reads as one subtitle line. Separator dot lives inside its
/// own horizontal padding so taps on the dot fall through rather
/// than ambiguously hitting either segment.
///
/// Was a right-aligned vertical stack pinned to the app bar's
/// trailing slot before 2026-05-27.
class ProfileAppBarIdentityStack extends StatelessWidget {
  const ProfileAppBarIdentityStack({
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('·', style: _metaTextStyle), // lint-ignore: l10n-literal — interpunct separator symbol, language-neutral
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
          style: _metaTextStyle,
        ),
      ),
    );
  }
}

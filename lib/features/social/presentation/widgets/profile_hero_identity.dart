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

/// Hex-cut "forged plate" banner showing the player's level and class
/// title. Layout per the 2026-05-26 design handoff:
///
///   * Hexagonal silhouette — flat top/bottom, pointed ends L/R
///     (12 px notch from each corner).
///   * Polished-gold level pill (40×40, rounded 10) at the left edge.
///   * Uppercase title, parchment-warm color, ellipsised when long.
///   * Dark forged-iron background gradient with inner highlight.
///
/// The level's rarity accent threads through the chrome (banner border,
/// pill border, soft title underglow) so the plate visibly shifts hue
/// with the player's tier without overriding the warm metal palette.
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

  static const double _height = 60;
  static const double _notch = 12;

  @override
  Widget build(BuildContext context) {
    // Border tint = rarity accent over the designer's warm-gold base,
    // so low-rarity tiers still read as a gold plate and high-rarity
    // tiers visibly tint toward their colour.
    final borderColor = Color.alphaBlend(
      accent.withValues(alpha: 0.55),
      const Color(0x73D4AA5A), // rgba(212,170,90,0.45)
    );

    return SizedBox(
      height: _height,
      child: ClipPath(
        clipper: const _HexNameplateClipper(notch: _notch),
        child: CustomPaint(
          painter: _HexNameplateBorderPainter(
            notch: _notch,
            color: borderColor,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              // Background alphas scaled by ~0.85 from the design
              // handoff (D9 → B8, F2 → CE) so the scene behind the
              // plate shows through, while border + content stay at
              // full opacity for legibility.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB81C1208),
                  Color(0xCE0E0904),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x99000000), // 0 12 30 rgba(0,0,0,0.6)
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Row(
                children: [
                  _LevelPill(level: level, accent: accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _TitleText(title: title, accent: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: const Color(0xFFF4D9A7),
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.18 * 15, // 0.18em
        height: 1.0,
        shadows: [
          const Shadow(
            color: Color(0xB3000000), // rgba(0,0,0,0.7)
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
          // Tier underglow — same-colour halo grounds the text in the
          // rarity accent without overriding the parchment letter fill.
          Shadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level, required this.accent});

  final int level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Pill body uses the rarity accent directly — lighter at the top,
    // darker at the bottom — so the level chip reads as a tier-coloured
    // gem rather than a generic gold stud.
    final hsl = HSLColor.fromColor(accent);
    final pillTop = hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor();
    final pillBottom = hsl
        .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
        .toColor();
    final pillBorder = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.35),
      accent,
    );

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pillTop, pillBottom],
        ),
        border: Border.all(color: pillBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000), // 0 2 4 rgba(0,0,0,0.5)
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // inset -2px bottom shadow rgba(0,0,0,0.25) — fake it with a
          // thin dark band at the bottom inside the rounded clip.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x40000000),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '$level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.02 * 18,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Color(0xB3000000),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexNameplateClipper extends CustomClipper<Path> {
  const _HexNameplateClipper({required this.notch});

  final double notch;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(notch, 0)
      ..lineTo(w - notch, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - notch, h)
      ..lineTo(notch, h)
      ..lineTo(0, h / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant _HexNameplateClipper oldClipper) =>
      oldClipper.notch != notch;
}

class _HexNameplateBorderPainter extends CustomPainter {
  const _HexNameplateBorderPainter({required this.notch, required this.color});

  final double notch;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(notch, 0)
      ..lineTo(w - notch, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - notch, h)
      ..lineTo(notch, h)
      ..lineTo(0, h / 2)
      ..close();

    // Outline (1px, rarity-tinted gold).
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    canvas.drawPath(path, stroke);

    // Inset top highlight — rgba(255,220,150,0.15), 1 px under the
    // top edge, gives the plate a forged "lit from above" sheen.
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x26FFDC96);
    final highlightPath = Path()
      ..moveTo(notch, 1)
      ..lineTo(w - notch, 1);
    canvas.drawPath(highlightPath, highlight);
  }

  @override
  bool shouldRepaint(covariant _HexNameplateBorderPainter oldDelegate) =>
      oldDelegate.notch != notch || oldDelegate.color != color;
}


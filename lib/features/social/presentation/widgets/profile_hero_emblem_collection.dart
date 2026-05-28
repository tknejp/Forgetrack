import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/domain/emblem_board.dart';
import 'profile_hero_layout.dart';

class ProfileHeroEmblemCollection extends StatelessWidget {
  const ProfileHeroEmblemCollection({
    super.key,
    required this.slots,
    required this.playerLevel,
    required this.slotSize,
    required this.onTapSlot,
  });

  final List<Cosmetic?> slots;

  /// Player level — drives how many of the [EmblemBoard.slotCount]
  /// slots are unlocked. Slot `i` becomes unlockable once the player
  /// reaches `EmblemBoard.slotUnlockLevels[i]` (level-progression-
  /// driven slot unlocks landed 2026-05-25). Slots above the unlocked
  /// threshold render as locked even if `slots[i]` carries a pin from
  /// older state.
  final int playerLevel;

  final double slotSize;
  final void Function(int slotIndex)? onTapSlot;

  @override
  Widget build(BuildContext context) {
    final total = ProfileHeroLayout.emblemSlotCount;
    final unlockedCount = EmblemBoard.unlockedSlotCount(playerLevel);
    // Horizontal row across the bottom of the hero card (moved out
    // of the right-edge column on 2026-05-26). The parent
    // Positioned hands us a full-width band; `spaceBetween` lets
    // the slots anchor flush with the side gutters and distributes
    // any extra width across the inter-slot gaps, so the row
    // scales gracefully with screen width without us re-doing the
    // math per device. On narrow screens where 6 × slotSize exceeds
    // the available band width (e.g. ~360-px devices once Stack
    // gutters are subtracted), [LayoutBuilder] shrinks slot size to
    // fit instead of letting the Row overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBySpace = constraints.maxWidth / total;
        final effectiveSize = maxBySpace.isFinite && maxBySpace < slotSize
            ? maxBySpace
            : slotSize;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < total; i++)
              () {
                final unlocked = i < unlockedCount;
                final emblem = unlocked && i < slots.length ? slots[i] : null;
                final data = _SlotData(
                  index: i,
                  emblem: emblem,
                  unlocked: unlocked,
                  pinned: false,
                  endGame: i == total - 1,
                  unlockLevel: i < EmblemBoard.slotUnlockLevels.length
                      ? EmblemBoard.slotUnlockLevels[i]
                      : null,
                );
                return _EmblemSlot(
                  data: data,
                  size: effectiveSize,
                  onTap: unlocked && onTapSlot != null
                      ? () => onTapSlot!(i)
                      : null,
                );
              }(),
          ],
        );
      },
    );
  }
}

class _SlotData {
  const _SlotData({
    required this.index,
    required this.emblem,
    required this.unlocked,
    required this.pinned,
    required this.endGame,
    required this.unlockLevel,
  });

  final int index;
  final Cosmetic? emblem;
  final bool unlocked;
  final bool pinned;
  final bool endGame;

  /// Player level required to unlock this slot, or `null` if no
  /// threshold applies (legacy / out-of-range index). Rendered as a
  /// small `Lv N` chip on locked slots so the player sees exactly
  /// when each slot opens up.
  final int? unlockLevel;
}

class _EmblemSlot extends StatelessWidget {
  const _EmblemSlot({
    required this.data,
    required this.size,
    required this.onTap,
  });

  final _SlotData data;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final emblem = data.emblem;
    final Widget content;
    if (emblem != null) {
      final assetPath = CosmeticsConfig.standard().resolveAssetPath(
        emblem.previewAssetKey ?? emblem.assetKey,
      );
      // Per-slot rarity halo behind a round gradient — not a BoxShadow
      // on the square hit-target — so adjacent slots blend rather than
      // stack their tints into a chequerboard.
      final rarityColor = RarityPalette.forRarity(emblem.rarity).color;
      final haloAlpha = data.pinned ? 0.32 : 0.18;
      content = SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        rarityColor.withValues(alpha: haloAlpha),
                        rarityColor.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            if (data.pinned)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          rarityColor.withValues(alpha: 0.30),
                          rarityColor.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.45],
                      ),
                    ),
                  ),
                ),
              ),
            // Emblem artwork fills the full slot square. The ~8 %
            // top/bottom safety margin already baked into the 512²
            // source canvas plays the role the old inner Padding
            // used to — keeping a small visual gap to the rarity
            // halo edge without shrinking the on-screen emblem.
            SizedBox(
              width: size,
              height: size,
              child: assetPath == null
                  ? const Icon(
                      Icons.shield_moon_rounded,
                      color: Colors.white70,
                    )
                  : Image.asset(assetPath, fit: BoxFit.contain),
            ),
          ],
        ),
      );
    } else {
      // Dashed-frame footprint sits inside the slot's hit-target —
      // the slot reads as a hint, equipped emblems read as the
      // main object overflowing that hint (frame < slotSize). The
      // frame tracks the slot size so the margin/ratio stays
      // consistent when the row shrinks on narrow screens.
      final frame = ProfileHeroLayout.emblemFrameSize *
          (size / ProfileHeroLayout.emblemSlotSize);
      // Locked slots get a quieter rendering than empty-but-
      // unlocked ones — the player has nothing actionable to do
      // there yet, so we let the unlocked slots lead visually.
      final locked = !data.unlocked;
      final borderColor = locked
          ? const Color(0x0DFFFFFF)
          : const Color(0x17FFFFFF);
      final fillColor = locked
          ? const Color(0x03FFFFFF)
          : const Color(0x07FFFFFF);
      content = SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: frame,
            height: frame,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: borderColor,
                radius: 9,
                dashWidth: 3,
                dashGap: 3,
                strokeWidth: 1,
                fillColor: fillColor,
              ),
              child: Center(
                child: data.unlocked
                    ? (data.endGame
                        ? CustomPaint(
                            size: Size(frame * 0.45, frame * 0.45),
                            painter: _StarGlyphPainter(
                              color: const Color(0x38FFFFFF),
                            ),
                          )
                        : Icon(
                            Icons.add_rounded,
                            size: frame * 0.42,
                            color: Colors.white.withValues(alpha: 0.42),
                          ))
                    : (data.unlockLevel != null
                        ? Icon(
                            Icons.lock_rounded,
                            size: frame * 0.42,
                            color: Colors.white.withValues(alpha: 0.20),
                          )
                        : Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x1AFFFFFF),
                            ),
                          )),
              ),
            ),
          ),
        ),
      );
    }

    // Locked slots: skip GestureDetector so taps fall through instead
    // of being silently swallowed.
    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
    required this.fillColor,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          strokePaint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.strokeWidth != strokeWidth ||
      old.fillColor != fillColor;
}

class _StarGlyphPainter extends CustomPainter {
  const _StarGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // 4-point star with concave waists, matching the SVG path in the
    // reference file: M 12 3 L 13.5 10.5 L 21 12 L 13.5 13.5 L 12 21
    // L 10.5 13.5 L 3 12 L 10.5 10.5 Z (24×24 viewBox).
    final s = size.width / 24;
    final path = Path()
      ..moveTo(12 * s, 3 * s)
      ..lineTo(13.5 * s, 10.5 * s)
      ..lineTo(21 * s, 12 * s)
      ..lineTo(13.5 * s, 13.5 * s)
      ..lineTo(12 * s, 21 * s)
      ..lineTo(10.5 * s, 13.5 * s)
      ..lineTo(3 * s, 12 * s)
      ..lineTo(10.5 * s, 10.5 * s)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarGlyphPainter old) => old.color != color;
}

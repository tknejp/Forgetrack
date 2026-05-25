import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import 'profile_hero_layout.dart';

class ProfileHeroEmblemCollection extends StatelessWidget {
  const ProfileHeroEmblemCollection({
    super.key,
    required this.slots,
    required this.unlockedCount,
    required this.slotSize,
    required this.gap,
    required this.onTapSlot,
  });

  final List<Cosmetic?> slots;
  final int unlockedCount;
  final double slotSize;
  final double gap;
  final void Function(int slotIndex)? onTapSlot;

  // 3-col × 2-row layout (3+3 = 6). The slot count was capped at 6
  // on 2026-05-25 so the showcase reads as a curated set rather than
  // a complete dump — the player has to pick which emblems to wear.
  static const List<int> _rowSizes = [3, 3];

  @override
  Widget build(BuildContext context) {
    final total = ProfileHeroLayout.emblemSlotCount;
    final slotData = List<_SlotData>.generate(total, (i) {
      final emblem = (i < slots.length && i < unlockedCount) ? slots[i] : null;
      return _SlotData(
        index: i,
        emblem: emblem,
        unlocked: i < unlockedCount,
        pinned: false,
        endGame: i == total - 1,
      );
    });

    final rows = <List<_SlotData>>[];
    var cursor = 0;
    for (final rowSize in _rowSizes) {
      rows.add(slotData.sublist(cursor, cursor + rowSize));
      cursor += rowSize;
    }

    // No outer frame on the grid — empty slots stay fully
    // transparent. Each equipped slot draws its own soft round
    // shadow behind the artwork (see `_EmblemSlot`) so the
    // showcase is anchored emblem-by-emblem rather than as one
    // big floating panel.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var ri = 0; ri < rows.length; ri++) ...[
          if (ri > 0) SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var si = 0; si < rows[ri].length; si++) ...[
                if (si > 0) SizedBox(width: gap),
                _EmblemSlot(
                  data: rows[ri][si],
                  size: slotSize,
                  onTap: rows[ri][si].unlocked && onTapSlot != null
                      ? () => onTapSlot!(rows[ri][si].index)
                      : null,
                ),
              ],
            ],
          ),
        ],
      ],
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
  });

  final int index;
  final Cosmetic? emblem;
  final bool unlocked;
  final bool pinned;
  final bool endGame;
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
      const topPadding = 8.0;
      content = SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Per-equipped soft round shadow — replaces the old
            // outer grid panel. Sits behind the rarity halo so the
            // colored tint still leads visually; the dark backdrop
            // just anchors the emblem to the hero scene instead of
            // letting it float on whatever pixels happen to be
            // under it. Empty slots intentionally skip this layer
            // and stay fully transparent.
            //
            // Negative insets push the gradient past the slot
            // bounds so the halo overflows ~8 px on each side —
            // necessary because a `Positioned.fill` shadow with a
            // 0-alpha outer stop visually vanishes right at the
            // slot edge, leaving no glow on the surrounding scene.
            // The parent Stack already opts into `Clip.none` so
            // the overflow is honoured.
            Positioned(
              left: -8,
              right: -8,
              top: -6,
              bottom: -8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.only(top: topPadding),
              child: SizedBox(
                width: size,
                height: size - topPadding,
                child: assetPath == null
                    ? const Icon(
                        Icons.shield_moon_rounded,
                        color: Colors.white70,
                      )
                    : Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      );
    } else {
      content = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0x17FFFFFF),
            radius: 9,
            dashWidth: 3,
            dashGap: 3,
            strokeWidth: 1,
            fillColor: const Color(0x07FFFFFF),
          ),
          child: Center(
            child: data.endGame
                ? CustomPaint(
                    size: Size(size * 0.45, size * 0.45),
                    painter: _StarGlyphPainter(
                      color: const Color(0x38FFFFFF),
                    ),
                  )
                : data.unlocked
                    ? Icon(
                        Icons.add_rounded,
                        size: size * 0.42,
                        color: Colors.white.withValues(alpha: 0.42),
                      )
                    : Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x2EFFFFFF),
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

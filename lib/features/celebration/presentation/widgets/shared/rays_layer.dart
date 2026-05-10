import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../../../shared/domain/rarity.dart';

/// Slowly rotating sun-rays painter. The ray density and opacity are
/// modulated by the rarity's `raysMultiplier` (common ≈ 0.10, mythic ≈ 0.85),
/// so a Common celebration shows a near-imperceptible halo while a Mythic
/// scene lights up. Intended for the fullscreen variant — the topsheet does
/// not include rays.
class RaysLayer extends StatefulWidget {
  const RaysLayer({
    super.key,
    required this.rarity,
    this.intensity = 1.0,
  });

  final Rarity rarity;

  /// 0..1, multiplied with the rarity's [CelebrationRarityToken.raysMultiplier].
  final double intensity;

  @override
  State<RaysLayer> createState() => _RaysLayerState();
}

class _RaysLayerState extends State<RaysLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = CelebrationRarityToken.forIndex(widget.rarity.index);
    final mult = token.raysMultiplier * widget.intensity;
    if (mult <= 0.001) return const SizedBox.shrink();
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _RaysPainter(
              color: token.color,
              opacity: mult,
              rotation: _controller.value * 2 * math.pi,
            ),
          );
        },
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter({
    required this.color,
    required this.opacity,
    required this.rotation,
  });

  static const _spokeCount = 12;

  final Color color;
  final double opacity;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.25);
    final outer = size.longestSide * 1.1;
    final paint = Paint()
      ..strokeWidth = 0
      ..color = color.withValues(alpha: opacity * 0.55);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    for (var i = 0; i < _spokeCount; i++) {
      final a0 = (i * 2 * math.pi) / _spokeCount;
      final a1 = a0 + (math.pi / _spokeCount) * 0.55;
      final p = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a0) * outer, math.sin(a0) * outer)
        ..lineTo(math.cos(a1) * outer, math.sin(a1) * outer)
        ..close();
      canvas.drawPath(p, paint);
    }
    canvas.restore();

    // Soft radial fade so the spokes feel like light rather than wedges.
    final fade = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.transparent, Colors.black],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outer * 0.65))
      ..blendMode = BlendMode.dstIn;
    canvas.drawRect(Offset.zero & size, fade);
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.opacity != opacity ||
      oldDelegate.color != color;
}

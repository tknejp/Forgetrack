import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../../../shared/domain/rarity.dart';

/// Soft radial breathing aura — the background "halo" that signals the
/// celebration's rarity. The painter is intentionally cheap: a single radial
/// gradient, no per-frame allocations beyond the Paint object.
class AuraLayer extends StatefulWidget {
  const AuraLayer({
    super.key,
    required this.rarity,
    this.intensity = 1.0,
    this.alignment = Alignment.center,
  });

  final Rarity rarity;

  /// 0..1 — multiplied into the aura's max alpha. Topsheets pass ~0.5,
  /// fullscreen passes ~0.7.
  final double intensity;

  /// Where the aura "originates". Topsheet aligns to top center; fullscreen
  /// to ~25% from top.
  final Alignment alignment;

  @override
  State<AuraLayer> createState() => _AuraLayerState();
}

class _AuraLayerState extends State<AuraLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = CelebrationRarityToken.forIndex(widget.rarity.index);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          // 0.7..1.0 of the configured intensity, breathing.
          final breath = 0.7 + 0.3 * t;
          final scale = 1.0 + 0.06 * t;
          return CustomPaint(
            painter: _AuraPainter(
              color: token.aura,
              alpha: widget.intensity * breath,
              alignment: widget.alignment,
              scale: scale,
            ),
          );
        },
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  _AuraPainter({
    required this.color,
    required this.alpha,
    required this.alignment,
    required this.scale,
  });

  final Color color;
  final double alpha;
  final Alignment alignment;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = alignment.alongSize(size);
    final radius = size.shortestSide * 0.85 * scale;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.42 * alpha),
          color.withValues(alpha: 0.18 * alpha),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: origin, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) =>
      oldDelegate.alpha != alpha ||
      oldDelegate.scale != scale ||
      oldDelegate.color != color ||
      oldDelegate.alignment != alignment;
}

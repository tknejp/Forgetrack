import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../../../shared/domain/rarity.dart';

/// Rising-particle field — gentle dots float upward from the bottom edge,
/// fade in and out, recycle. Cheap enough to run at 60fps even on the
/// topsheet variant.
class ParticlesLayer extends StatefulWidget {
  const ParticlesLayer({
    super.key,
    required this.rarity,
    this.count = 14,
    this.intensity = 1.0,
  });

  final Rarity rarity;

  /// Active particle count. ~8 for topsheet, ~14 for fullscreen.
  final int count;

  /// 0..1 — opacity multiplier.
  final double intensity;

  @override
  State<ParticlesLayer> createState() => _ParticlesLayerState();
}

class _ParticlesLayerState extends State<ParticlesLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _rng = math.Random(0xC0FFEE);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Drives time progression — actual particle lifetimes are individual.
      duration: const Duration(seconds: 1),
    )..repeat();
    _particles = List.generate(widget.count, (i) => _spawn(initialPhase: true));
  }

  @override
  void didUpdateWidget(covariant ParticlesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      if (widget.count > _particles.length) {
        _particles.addAll(List.generate(
          widget.count - _particles.length,
          (_) => _spawn(initialPhase: true),
        ));
      } else {
        _particles.removeRange(widget.count, _particles.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _Particle _spawn({required bool initialPhase}) {
    final lifeMs = 3500 + _rng.nextInt(3500); // 3.5..7s
    return _Particle(
      seed: _rng.nextDouble(),
      x: _rng.nextDouble(),
      drift: (_rng.nextDouble() - 0.5) * 0.18,
      sizePx: 1.6 + _rng.nextDouble() * 2.6,
      lifeMs: lifeMs,
      // If true the particle starts mid-flight so the field is populated on
      // first frame (no empty wait at startup).
      birthMs: initialPhase
          ? -_rng.nextInt(lifeMs)
          : DateTime.now().millisecondsSinceEpoch,
      paletteIndex: _rng.nextInt(4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = CelebrationRarityToken.forIndex(widget.rarity.index);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          // Recycle dead particles with fresh seeds at "now".
          for (var i = 0; i < _particles.length; i++) {
            final p = _particles[i];
            if (nowMs - p.birthMs >= p.lifeMs) {
              _particles[i] = _spawn(initialPhase: false);
            }
          }
          return CustomPaint(
            painter: _ParticlesPainter(
              particles: List.unmodifiable(_particles),
              palette: token.particles,
              opacity: widget.intensity,
              nowMs: nowMs,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.seed,
    required this.x,
    required this.drift,
    required this.sizePx,
    required this.lifeMs,
    required this.birthMs,
    required this.paletteIndex,
  });

  final double seed;
  final double x;
  final double drift;
  final double sizePx;
  final int lifeMs;
  final int birthMs;
  final int paletteIndex;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({
    required this.particles,
    required this.palette,
    required this.opacity,
    required this.nowMs,
  });

  final List<_Particle> particles;
  final List<Color> palette;
  final double opacity;
  final int nowMs;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final ageMs = nowMs - p.birthMs;
      if (ageMs < 0 || ageMs > p.lifeMs) continue;
      final t = ageMs / p.lifeMs; // 0..1
      // Alpha: ramp up in first 10%, hold, ramp down in last 20%.
      double alpha;
      if (t < 0.1) {
        alpha = t / 0.1;
      } else if (t > 0.8) {
        alpha = (1 - t) / 0.2;
      } else {
        alpha = 1.0;
      }
      final dx = (p.x + p.drift * t) * size.width;
      final dy = size.height - (t * size.height * 1.05);
      final color = palette[p.paletteIndex % palette.length];
      paint.color = color.withValues(alpha: 0.85 * alpha * opacity);
      canvas.drawCircle(Offset(dx, dy), p.sizePx, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

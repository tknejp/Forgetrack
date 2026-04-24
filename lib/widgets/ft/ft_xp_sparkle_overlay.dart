import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ft_progression_xp_style.dart';

class FtXpSparkleLauncher {
  const FtXpSparkleLauncher._();

  static void launchToKey(
    BuildContext context, {
    required Offset from,
    required GlobalKey targetKey,
  }) {
    launchManyToKey(
      context,
      fromPoints: [from],
      targetKey: targetKey,
    );
  }

  static void launchManyToKey(
    BuildContext context, {
    required Iterable<Offset> fromPoints,
    required GlobalKey targetKey,
  }) {
    final targetContext = targetKey.currentContext;
    if (targetContext == null) return;

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    if (targetBox == null) return;

    final resolvedPoints = fromPoints.toList(growable: false);
    if (resolvedPoints.isEmpty) return;

    final to = targetBox.localToGlobal(Offset.zero) +
        Offset(targetBox.size.width / 2, targetBox.size.height / 2);

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => FtXpSparkleOverlay(
        fromPoints: resolvedPoints,
        to: to,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class FtXpSparkleOverlay extends StatefulWidget {
  const FtXpSparkleOverlay({
    super.key,
    required this.fromPoints,
    required this.to,
    required this.onDone,
  });

  final List<Offset> fromPoints;
  final Offset to;
  final VoidCallback onDone;

  @override
  State<FtXpSparkleOverlay> createState() => _FtXpSparkleOverlayState();
}

class _FtXpSparkleOverlayState extends State<FtXpSparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  static final _random = math.Random();

  late final List<_SparkleGroup> _groups = widget.fromPoints
      .map(
        (from) => _SparkleGroup(
          from: from,
          particles: List.generate(
            9,
            (_) => _SparkleParticle(
              delay: _random.nextDouble() * 0.3,
              scatter: Offset(
                (_random.nextDouble() - 0.5) * 60,
                (_random.nextDouble() - 0.5) * 60,
              ),
              size: 3.0 + _random.nextDouble() * 3.5,
            ),
          ),
        ),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _FtXpSparklePainter(
            groups: _groups,
            t: _controller.value,
            to: widget.to,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SparkleGroup {
  const _SparkleGroup({
    required this.from,
    required this.particles,
  });

  final Offset from;
  final List<_SparkleParticle> particles;
}

class _SparkleParticle {
  const _SparkleParticle({
    required this.delay,
    required this.scatter,
    required this.size,
  });

  final double delay;
  final Offset scatter;
  final double size;
}

class _FtXpSparklePainter extends CustomPainter {
  const _FtXpSparklePainter({
    required this.groups,
    required this.t,
    required this.to,
  });

  final List<_SparkleGroup> groups;
  final double t;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    for (final group in groups) {
      for (final particle in group.particles) {
        final progress = particle.delay >= 1
            ? 0.0
            : ((t - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
        if (progress <= 0) continue;

        final mid = group.from + particle.scatter;
        final pos = _quadBezier(group.from, mid, to, progress);
        final alpha = progress < 0.65
            ? 1.0
            : (1.0 - (progress - 0.65) / 0.35).clamp(0.0, 1.0);
        final radius = particle.size * (1.0 - progress * 0.4);

        canvas.drawCircle(
          pos,
          radius,
          Paint()..color = FtProgressionXpStyle.color.withValues(alpha: alpha),
        );
      }
    }
  }

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final mt = 1 - t;
    return p0 * (mt * mt) + p1 * (2 * mt * t) + p2 * (t * t);
  }

  @override
  bool shouldRepaint(_FtXpSparklePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.to != to ||
      oldDelegate.groups != groups;
}

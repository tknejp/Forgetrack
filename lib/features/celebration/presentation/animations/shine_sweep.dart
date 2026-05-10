import 'package:flutter/material.dart';

/// Diagonal sheen that sweeps across a child every ~2.8 seconds — used as
/// the over-paint of the gold claim button. Stops cleanly when [active] is
/// false (claim already taken).
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(99)),
    this.active = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool active;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ShineSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          widget.child,
          if (widget.active)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SheenPainter(progress: _controller.value),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Map progress 0..1 to translateX -1.4..1.4 (in widths). The sheen is
    // wider than the surface to ensure full coverage at both ends.
    final tx = (-1.4 + progress * 2.8) * size.width;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Color(0x66FFFFFF),
          Color(0x99FFFFFF),
          Color(0x66FFFFFF),
          Colors.transparent,
        ],
        stops: [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(tx, 0, size.width * 0.8, size.height));
    canvas.save();
    // -18° skew so the sheen tilts forward.
    final skew = Matrix4.identity()..setEntry(0, 1, 0.32);
    canvas.transform(skew.storage);
    canvas.drawRect(Offset.zero & size, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

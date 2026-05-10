import 'package:flutter/material.dart';

/// Wraps a child in a 2.2s breathing box-shadow ring. Used by the gold
/// claim pill while it is in the unclaimed state.
class ClaimPulse extends StatefulWidget {
  const ClaimPulse({
    super.key,
    required this.color,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(99)),
    this.active = true,
  });

  final Color color;
  final Widget child;
  final BorderRadius borderRadius;
  final bool active;

  @override
  State<ClaimPulse> createState() => _ClaimPulseState();
}

class _ClaimPulseState extends State<ClaimPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ClaimPulse oldWidget) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Two-phase: 0..0.5 ring expands and fades, 0.5..1.0 retract.
        final t = _controller.value;
        final phase = t < 0.5 ? t / 0.5 : 1 - (t - 0.5) / 0.5;
        final spread = widget.active ? phase * 6 : 0.0;
        final blur = widget.active ? 8 + phase * 12 : 0.0;
        final alpha = widget.active ? 0.45 - 0.30 * phase : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: alpha),
                blurRadius: blur,
                spreadRadius: spread,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

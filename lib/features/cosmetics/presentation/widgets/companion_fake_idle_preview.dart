import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class CompanionFakeIdlePreview extends StatefulWidget {
  const CompanionFakeIdlePreview({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.enableGlow = true,
    this.duration = const Duration(milliseconds: 2400),
    this.floatDistance = 3,
    this.minScale = 0.99,
    this.maxScale = 1.01,
    this.glowColor,
  });

  final Widget child;
  final double? width;
  final double? height;
  final bool enableGlow;
  final Duration duration;
  final double floatDistance;
  final double minScale;
  final double maxScale;
  final Color? glowColor;

  @override
  State<CompanionFakeIdlePreview> createState() =>
      _CompanionFakeIdlePreviewState();
}

class _CompanionFakeIdlePreviewState extends State<CompanionFakeIdlePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseGlowColor =
        widget.glowColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) {
          final t = _animation.value;

          final dy = lerpDouble(
            -widget.floatDistance,
            widget.floatDistance,
            t,
          )!;

          final scale = lerpDouble(
            widget.minScale,
            widget.maxScale,
            t,
          )!;

          final glowAlpha = lerpDouble(0.18, 0.34, t)!;
          final glowBlur = lerpDouble(18, 28, t)!;
          final glowSpread = lerpDouble(1, 3, t)!;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.enableGlow)
                IgnorePointer(
                  child: Container(
                    width: (widget.width ?? 94) * 0.78,
                    height: (widget.height ?? 94) * 0.78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: baseGlowColor.withValues(alpha: glowAlpha),
                          blurRadius: glowBlur,
                          spreadRadius: glowSpread,
                        ),
                      ],
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
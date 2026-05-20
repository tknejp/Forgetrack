import 'package:flutter/material.dart';

import '../../../../../shared/widgets/xp_claim_pill.dart';

/// Static "+N XP" pill the celebration overlay shows after the engine has
/// already credited the XP. Visually matches the shared
/// [XpClaimPill.claimed] style used on the home / quest screens; on mount
/// it plays a single 900 ms diagonal shimmer so the player registers that
/// this is what they just earned.
///
/// Non-tappable. The V2 engine credits XP before the celebration fires,
/// so there is nothing for the user to do here.
///
/// Note: companion buff bonus is intentionally surfaced upstream on the
/// claim pill itself (see `XpClaimPillData.companionBonus`) so the
/// player sees it the moment they look at the card — not after the
/// celebration overlay. The headline here is the total XP credited.
class CelebrationXpAwardPill extends StatefulWidget {
  const CelebrationXpAwardPill({super.key, required this.amount});

  final int amount;

  @override
  State<CelebrationXpAwardPill> createState() => _CelebrationXpAwardPillState();
}

class _CelebrationXpAwardPillState extends State<CelebrationXpAwardPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    // One-shot. Slight delay so it lands after the topsheet entry slide.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        children: [
          XpClaimPill(data: XpClaimPillData.claimed(widget.amount)),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.value == 0 || _controller.value >= 1) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: _OneShotShimmer(progress: _controller.value),
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

class _OneShotShimmer extends CustomPainter {
  _OneShotShimmer({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final tx = (-1.4 + progress * 2.8) * size.width;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Color(0x77FFE8A8),
          Color(0xAAFFD980),
          Color(0x77FFE8A8),
          Colors.transparent,
        ],
        stops: [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(tx, 0, size.width * 0.8, size.height));
    final skew = Matrix4.identity()..setEntry(0, 1, 0.32);
    canvas.save();
    canvas.transform(skew.storage);
    canvas.drawRect(Offset.zero & size, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OneShotShimmer oldDelegate) =>
      oldDelegate.progress != progress;
}

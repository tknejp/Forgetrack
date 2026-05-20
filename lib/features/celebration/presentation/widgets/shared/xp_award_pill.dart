import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../../../shared/widgets/xp_claim_pill.dart';

/// Static "+N XP" pill the celebration overlay shows after the engine has
/// already credited the XP. Visually matches the shared
/// [XpClaimPill.claimed] style used on the home / quest screens; on mount
/// it plays a single 900 ms diagonal shimmer so the player registers that
/// this is what they just earned.
///
/// When [companionBonus] is non-zero a small "+N from buff" micro-badge
/// fades in after the shimmer pass so the player sees the equipped
/// companion's contribution distinct from the base reward. The headline
/// number is still the total (base + bonus) — the headline matches what
/// the ledger banks, the micro-badge attributes the portion the
/// companion added on top.
///
/// Non-tappable. The V2 engine credits XP before the celebration fires,
/// so there is nothing for the user to do here.
class CelebrationXpAwardPill extends StatefulWidget {
  const CelebrationXpAwardPill({
    super.key,
    required this.amount,
    this.companionBonus = 0,
  });

  final int amount;
  final int companionBonus;

  @override
  State<CelebrationXpAwardPill> createState() => _CelebrationXpAwardPillState();
}

class _CelebrationXpAwardPillState extends State<CelebrationXpAwardPill>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Slower fade for the bonus micro-badge so it surfaces after the
  /// shimmer pass instead of competing with it.
  late final AnimationController _bonusFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    // One-shot. Slight delay so it lands after the topsheet entry slide.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _controller.forward();
    });
    if (widget.companionBonus > 0) {
      // Stagger the buff micro-badge so it surfaces just as the
      // shimmer is wrapping up.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _bonusFade.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bonusFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = ClipRRect(
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

    if (widget.companionBonus <= 0) return pill;

    // Wrap in a Row so the bonus micro-badge sits to the right of
    // the headline pill without bleeding the rounded-rect clip into
    // it. The pill keeps its rounded shape; the badge gets its own.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        pill,
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _bonusFade,
          builder: (context, _) {
            final t = _bonusFade.value;
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset((1 - t) * -6, 0),
                child: _CompanionBonusBadge(amount: widget.companionBonus),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Small ember-tinted "+N" chip that sits next to the main XP pill
/// when an equipped companion contributed a buff bonus to the grant.
/// Visually quieter than the headline pill so the player reads the
/// total first, then registers where the extra came from.
class _CompanionBonusBadge extends StatelessWidget {
  const _CompanionBonusBadge({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Tokens.xp.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Tokens.xp.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 11,
            color: Tokens.xp,
          ),
          const SizedBox(width: 4),
          Text(
            '+$amount',
            style: const TextStyle(
              color: Tokens.xp,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
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

import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../animations/claim_pulse.dart';
import '../../animations/shine_sweep.dart';

/// Gold "Vyzvednout +XP" pill that flips one-way to a teal "Vyzvednuto · +XP"
/// once tapped. After flipping, the pulse + shine animations stop and the
/// button is no longer tappable.
///
/// The widget owns the `claimed` boolean — that's intentional. The progression
/// claim is idempotent at the provider level, so even if the user taps
/// again on a re-rendered button (e.g. after a hot reload) nothing breaks,
/// but we still want the visual to feel one-way and immediate without
/// waiting for the upstream future.
class ClaimButton extends StatefulWidget {
  const ClaimButton({
    super.key,
    required this.xpAmount,
    required this.onClaim,
  });

  final int xpAmount;
  final Future<void> Function() onClaim;

  @override
  State<ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<ClaimButton> {
  bool _claimed = false;
  bool _claiming = false;

  static const _gold1 = Color(0xFFFFD980);
  static const _gold2 = Color(0xFFE5A833);
  static const _ink = Color(0xFF0B0F1E);
  static const _teal = Color(0xFF3FB8AF);

  Future<void> _handleTap() async {
    if (_claimed || _claiming) return;
    setState(() {
      _claimed = true;
      _claiming = true;
    });
    try {
      await widget.onClaim();
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = _claimed
        ? l10n.celebrationClaimedXp(widget.xpAmount)
        : l10n.celebrationClaimXp(widget.xpAmount);
    final fg = _claimed ? _teal : _ink;
    return Semantics(
      button: true,
      enabled: !_claimed,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: ClaimPulse(
          color: _gold2,
          active: !_claimed,
          child: ShineSweep(
            active: !_claimed,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: _claimed
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_gold1, _gold2],
                      ),
                color: _claimed ? _teal.withValues(alpha: 0.14) : null,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: _claimed
                      ? _teal.withValues(alpha: 0.40)
                      : Colors.transparent,
                ),
                boxShadow: _claimed
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFFF4C152).withValues(alpha: 0.55),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _claimed ? Icons.check_circle_rounded : Icons.bolt_rounded,
                    size: 14,
                    color: fg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

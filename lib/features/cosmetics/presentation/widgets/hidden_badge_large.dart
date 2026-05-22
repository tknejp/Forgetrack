import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// 94px placeholder shown in the details sheet header when the cosmetic
/// is in a hidden lifecycle state.
class HiddenBadgeLarge extends StatelessWidget {
  const HiddenBadgeLarge({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 36,
          color: color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

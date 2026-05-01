import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Standard back button pill used on full-screen detail views.
/// Matches the 36×36 ghost-container style used throughout the app.
/// If [onTap] is null, calls [Navigator.maybePop] automatically.
class FtBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FtBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: Tokens.cardBorder),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

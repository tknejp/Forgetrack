import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../../../shared/domain/rarity.dart';

/// Row of pill-style pagination dots — active is wider with a glow ring.
class PaginationDots extends StatelessWidget {
  const PaginationDots({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.headRarity,
    this.onTap,
  });

  final int count;
  final int activeIndex;
  final Rarity headRarity;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final token = CelebrationRarityToken.forIndex(headRarity.index);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap == null ? null : () => onTap!(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: i == activeIndex ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == activeIndex
                      ? token.color
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: i == activeIndex
                      ? [
                          BoxShadow(
                            color: token.glow.withValues(alpha: 0.55),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

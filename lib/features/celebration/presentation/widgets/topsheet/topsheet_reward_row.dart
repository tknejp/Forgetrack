import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/models/celebration_reward.dart';
import '../shared/reward_thumb.dart';

/// One reward row inside the topsheet rewards strip. Layout:
/// `[ thumb ]  Name (1 line, ellipsis)\n RARITY LABEL`
class TopsheetRewardRow extends StatelessWidget {
  const TopsheetRewardRow({super.key, required this.reward});

  final CelebrationReward reward;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final token = CelebrationRarityToken.forIndex(reward.rarity.index);
    final sub = reward.sub?.call(l10n) ?? reward.rarity.label(l10n).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: token.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          RewardThumb(reward: reward),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ft.onSurface,
                    fontSize: Tokens.fontSizeBody,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: token.color,
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

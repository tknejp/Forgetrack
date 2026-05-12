import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../domain/models/reward_definition.dart';

/// Compact horizontal strip of icon-only chips, one per non-XP
/// reward on a node. Communicates "there's also a cosmetic / item /
/// title / emblem / relic here" at a glance without taking a card
/// row.
///
/// Used on the long-term card aggregate chip strip (primary +
/// companions) and on regular quest cards once they ship non-XP
/// rewards. XP rewards are filtered upstream â€” the XP value already
/// lives on the gold pill.
class EngineRewardChipStrip extends StatelessWidget {
  const EngineRewardChipStrip({
    super.key,
    required this.rewards,
    required this.accent,
  });

  final List<RewardDefinition> rewards;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final r in rewards) EngineRewardChip(reward: r, accent: accent),
      ],
    );
  }
}

class EngineRewardChip extends StatelessWidget {
  const EngineRewardChip({
    super.key,
    required this.reward,
    required this.accent,
  });

  final RewardDefinition reward;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Icon(iconFor(reward),
          size: 12, color: accent.withValues(alpha: 0.94)),
    );
  }

  /// Pure mapper from reward type to a Material icon. Public so other
  /// surfaces (celebration overlay, reward history feed) can reuse
  /// the same glyph vocabulary.
  static IconData iconFor(RewardDefinition reward) {
    return switch (reward) {
      XpReward() => Icons.bolt_rounded,
      CosmeticReward() => Icons.card_giftcard_rounded,
      ChapterUnlockReward() => Icons.menu_book_rounded,
      CompanionAvailabilityReward() => Icons.groups_2_rounded,
      TitleReward() => Icons.workspace_premium_rounded,
      EmblemReward() => Icons.military_tech_rounded,
      RelicReward() => Icons.diamond_rounded,
    };
  }
}

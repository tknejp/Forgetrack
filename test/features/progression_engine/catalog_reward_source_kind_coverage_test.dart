import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';

/// Guard against catalog drift: every XP-bearing reward in the
/// progression catalog must declare a [RewardSourceKind] so the
/// companion buff system at grant time can match it to the equipped
/// companion's buff. A null `sourceKind` would silently bypass the
/// buff multiplier — preventable here.
void main() {
  test(
    'every XpReward + BonusXpReward in the catalog declares a sourceKind',
    () {
      final nodes = const ProgressionEntryCatalog().build();
      final missing = <String>[];
      for (final node in nodes) {
        for (final reward in node.rewards) {
          switch (reward) {
            case XpReward(:final sourceKind):
              if (sourceKind == null) {
                missing.add('${node.id} → XpReward (amount=${reward.amount})');
              }
            case BonusXpReward(:final sourceKind):
              if (sourceKind == null) {
                missing.add(
                  '${node.id} → BonusXpReward (amount=${reward.amount})',
                );
              }
            default:
              // Non-XP rewards (Cosmetic, Title, Emblem, …) don't need
              // a buff-source tag.
              break;
          }
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'Add a `sourceKind: RewardSourceKind.X` to each XP reward '
            'below in `lib/features/progression_engine/domain/catalog/'
            'content/*` so the companion buff system can match it at '
            'grant time:\n${missing.join('\n')}',
      );
    },
  );
}

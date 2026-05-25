import '../models/celebration_event.dart';
import '../../../../shared/domain/rarity.dart';
import '../models/celebration_reward.dart';

/// Picks the celebration UI variant for an event.
///
/// Auto rule (when [CelebrationEvent.variantOverride] is null):
///   * 2+ rewards → fullscreen
///   * head rarity ≥ legendary → fullscreen
///   * otherwise → topsheet
///
/// The override field exists so progression call-sites can force a fullscreen
/// for, e.g., a journey-chapter finale even if it only drops a single
/// uncommon reward.
class CelebrationRouter {
  const CelebrationRouter();

  CelebrationVariant resolve(CelebrationEvent event) {
    final override = event.variantOverride;
    if (override != null) return override;

    // Cosmetic / title rewards earn the full-screen card stack — those are
    // the moments worth a "big reveal." A pure-XP topsheet (daily quest
    // claim, achievement with no item drop) stays compact. Routing on
    // *kind* rather than "rewards.isNotEmpty" keeps the rule honest if a
    // future converter starts attaching synthetic XP chips again.
    final hasShowcaseReward = event.rewards.any(_isShowcaseReward);
    if (hasShowcaseReward) return CelebrationVariant.fullscreen;

    if (event.headRarity.index >= Rarity.legendary.index) {
      return CelebrationVariant.fullscreen;
    }
    return CelebrationVariant.topsheet;
  }

  static bool _isShowcaseReward(CelebrationReward reward) {
    switch (reward.kind) {
      case CelebrationRewardKind.frame:
      case CelebrationRewardKind.background:
      case CelebrationRewardKind.companion:
      case CelebrationRewardKind.skin:
      case CelebrationRewardKind.title:
      case CelebrationRewardKind.location:
      case CelebrationRewardKind.badge:
      case CelebrationRewardKind.gem:
        return true;
      case CelebrationRewardKind.xp:
      case CelebrationRewardKind.flame:
      case CelebrationRewardKind.flag:
      case CelebrationRewardKind.sparkle:
        return false;
    }
  }
}

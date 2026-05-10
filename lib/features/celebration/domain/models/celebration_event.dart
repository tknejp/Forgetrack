import 'package:flutter/foundation.dart';

import '../../../../shared/domain/rarity.dart';
import 'celebration_reward.dart';

/// What kind of moment fired this celebration. Drives the small header icon
/// square + kicker label only — *not* the aura, glow, or particles. Those
/// follow the head rarity.
///
/// Aliases for the existing app surfaces:
///   * [CelebrationType.level] — XP-threshold level milestones (no specific
///     title — e.g. minor rounded levels)
///   * [CelebrationType.title] — title-breakpoint level milestones (level
///     reached *and* unlocks a new title)
///   * [CelebrationType.cosmetic] — orphan cosmetic unlocks (granted outside
///     a level / achievement event)
enum CelebrationType {
  achievement,
  quest,
  level,
  title,
  streak,
  location,
  cosmetic,
}

/// Which celebration UI to show. The router defaults to [topsheet] for small
/// wins and [fullscreen] for multi-reward / legendary moments. Callers may
/// force one variant with [CelebrationEvent.variantOverride].
enum CelebrationVariant { topsheet, fullscreen }

/// Optional XP-claim affordance attached to a celebration. When non-null the
/// topsheet renders a gold "Vyzvednout +XP" pill; on tap the controller calls
/// [onClaim] (idempotent) and flips the button to the "Vyzvednuto" state.
@immutable
class CelebrationClaim {
  const CelebrationClaim({
    required this.rewardKey,
    required this.xpAmount,
    required this.onClaim,
  });

  /// Matches `ProgressionQuestRewardGrant.rewardKey`. The host pipes this
  /// straight into `progressionProvider.claimQuestReward`.
  final String rewardKey;

  /// XP shown on the button (`Vyzvednout +205 XP` / `Vyzvednuto · +205 XP`).
  /// Note this is the *displayed* value at the time the celebration was
  /// queued; the engine recomputes the final XP at claim time using current
  /// level / multiplier, but for the visual we keep the queued value to
  /// match the user's expectations.
  final int xpAmount;

  /// Idempotent claim callback. The implementation must tolerate being
  /// called twice (e.g. once from this celebration, once from a quest card)
  /// without double-awarding XP.
  final Future<void> Function(String rewardKey) onClaim;
}

/// Self-contained celebration payload. The progression layer produces these;
/// the celebration overlay host consumes them. All player-facing strings use
/// closures so the queue survives a language change.
@immutable
class CelebrationEvent {
  const CelebrationEvent({
    required this.id,
    required this.type,
    required this.eyebrow,
    required this.title,
    required this.rewards,
    required this.headRarity,
    this.description,
    this.claim,
    this.variantOverride,
  });

  /// Stable id used as a Flutter widget key and as a dedupe token in the
  /// queue. Pattern: `<source>|<entity-id>|<microsSinceEpoch>`.
  final String id;

  final CelebrationType type;

  /// Tiny uppercase kicker above the title. Examples: "ÚSPĚCH ODEMČEN",
  /// "QUEST DOKONČEN".
  final CelebrationText eyebrow;

  /// One- or two-line title. Examples: "Level 80 · Horský vyzyvatel",
  /// "Dnešní kalorický cíl".
  final CelebrationText title;

  /// Optional supporting line under the title (topsheet only).
  final CelebrationText? description;

  /// Rewards bundled with this celebration. May be empty (e.g. a pure
  /// "achievement unlocked" with no item drop), in which case the head
  /// rarity must still be set explicitly.
  final List<CelebrationReward> rewards;

  /// Drives every visual (aura color, glow, particles, dot pagination,
  /// ray intensity). Convenience: pass [maxRarityFrom] to compute it.
  final Rarity headRarity;

  /// When non-null the topsheet renders a claim button.
  final CelebrationClaim? claim;

  /// When set, [CelebrationRouter.resolve] returns this variant unchanged.
  /// Use sparingly — the auto rule fits 95% of cases.
  final CelebrationVariant? variantOverride;

  /// Compute the head rarity as the max of a list. Returns
  /// [Rarity.common] for an empty list (caller may prefer to
  /// pass the explicit rarity instead in that case).
  static Rarity maxRarityFrom(List<CelebrationReward> rewards) {
    if (rewards.isEmpty) return Rarity.common;
    return rewards
        .map((r) => r.rarity)
        .reduce(Rarity.max);
  }
}

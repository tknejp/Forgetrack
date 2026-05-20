import 'package:meta/meta.dart';

import '../../../../l10n/app_localizations.dart';
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
  cosmetic;

  /// Short, uppercase-friendly localized label (e.g. "ÚSPĚCH", "QUEST").
  /// Used by the topsheet header eyebrow context.
  String label(AppLocalizations l10n) {
    switch (this) {
      case CelebrationType.achievement:
        return l10n.celebrationTypeAchievement;
      case CelebrationType.quest:
        return l10n.celebrationTypeQuest;
      case CelebrationType.level:
        return l10n.celebrationTypeLevel;
      case CelebrationType.title:
        return l10n.celebrationTypeTitle;
      case CelebrationType.streak:
        return l10n.celebrationTypeStreak;
      case CelebrationType.location:
        return l10n.celebrationTypeLocation;
      case CelebrationType.cosmetic:
        return l10n.celebrationTypeCosmetic;
    }
  }
}

/// Which celebration UI to show. The router defaults to [topsheet] for small
/// wins and [fullscreen] for multi-reward / legendary moments. Callers may
/// force one variant with [CelebrationEvent.variantOverride].
enum CelebrationVariant { topsheet, fullscreen }

/// Informational "XP credited" pill attached to a celebration. The V2 engine
/// credits XP *before* the celebration fires, so this is **not** a tappable
/// affordance — it reuses the same `XpClaimPill` widget in its `claimed`
/// state with a one-shot shimmer on entry to communicate "this is what you
/// just earned." Skipped entirely when [amount] <= 0.
@immutable
class CelebrationXpAward {
  const CelebrationXpAward(this.amount, {this.companionBonus = 0});

  /// Total XP credited (level-scaled base + companion buff bonus).
  /// The pill displays this as the headline number.
  final int amount;

  /// Portion of [amount] that came from the equipped companion's buff.
  /// Zero when no buff applied (no companion equipped, RPG mode off,
  /// kind mismatch, or daily 25 % cap clamped it to zero). Rendered
  /// by the pill as a fade-in micro-badge so the player sees the
  /// buff's contribution distinct from the base reward.
  final int companionBonus;
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
    this.xpAward,
    this.variantOverride,
  });

  /// Stable id used as a Flutter widget key and as a dedupe token in the
  /// queue. Pattern: `<source>|<entity-id>|<microsSinceEpoch>`.
  final String id; // lint-ignore: untyped-id — celebration queue dedupe token, composed at the producer (`<source>|<entity-id>|<micros>`)

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

  /// When non-null, the celebration shows a static "XP credited" pill that
  /// shimmers once on entry. Not tappable — V2 has already banked the XP.
  final CelebrationXpAward? xpAward;

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

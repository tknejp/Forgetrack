import 'package:meta/meta.dart';

import 'cosmetic_models.dart' show CosmeticUnlockSource;
import 'cosmetic_reveal_state.dart' show CosmeticRevealConditionRow;

/// Player-side lifecycle of one [Cosmetic] catalog row.
///
/// Phase 10 of the domain refactor unifies three parallel reveal /
/// availability / ownership states into a single sealed discriminator
/// per `docs/domain_model/proposal.md` §4.3:
///
///   - [CosmeticHidden] — locked + identity concealed (silhouette in
///     the grid). Replaces `CosmeticRevealState.hidden`.
///   - [CosmeticTeased] — locked, identity revealed; optional partial
///     progress (`satisfiedConditions / totalConditions`) and an
///     optional companion checklist (`conditionRows`). Replaces
///     `CosmeticRevealState.visibleLocked` (no progress, no rows) and
///     `CosmeticRevealState.partial` (with progress).
///   - [CosmeticClaimable] — the engine has surfaced a manual-claim
///     gate (e.g. `CompanionAvailability`) and the player can claim
///     the cosmetic. Identity stays hidden until claim per the
///     proposal-spec `hidesIdentity` helper below.
///   - [CosmeticOwned] — terminal state; the cosmetic is in the
///     player's [Inventory]. Carries the unlock provenance.
///
/// **Companion identity stays a derivation, not a state.** Proposal
/// §4.3 explicitly rejects a separate `CompanionHidden` subtype — the
/// "hide artwork until claim" rule is a pattern-match over `(Cosmetic,
/// PlayerCosmeticLifecycle)`. See [hidesIdentity] / [showsChecklist]
/// below; widgets call those helpers instead of duplicating the rule.
///
/// **Phase 10 vs Phase 11 split.** Phase 10 introduces this sealed +
/// the Inventory aggregate as a read projection over the existing
/// reveal evaluator + companion availability sources. The legacy
/// `CompanionState` enum and `CompanionsRegistry` view-model factory
/// are still alive — Phase 11 deletes them once every widget switches
/// from `cState == CompanionState.X` to
/// `(definition is Companion, lifecycle is CosmeticX)`. The fields on
/// [CosmeticClaimable] / [CosmeticOwned] are sized so Phase 11 can
/// remove the legacy bridge without re-shaping the lifecycle.
///
/// **Switch contract.** The 4 subtypes are exhaustive — Dart 3 sealed
/// switches force every consumer to handle each branch. A future 5th
/// state (e.g. a `CosmeticGated` premium tier) would fail every
/// consumer at compile time.
@immutable
sealed class PlayerCosmeticLifecycle {
  const PlayerCosmeticLifecycle();
}

/// Locked + identity concealed. The grid card renders a silhouette
/// with no name, no asset, no checklist. Used for prestige / compound
/// rewards the player hasn't made meaningful progress toward.
///
/// Maps from `CosmeticRevealState.hidden`.
@immutable
class CosmeticHidden extends PlayerCosmeticLifecycle {
  const CosmeticHidden();

  @override
  bool operator ==(Object other) => other is CosmeticHidden;

  @override
  int get hashCode => (CosmeticHidden).hashCode;

  @override
  String toString() => 'CosmeticHidden()';
}

/// Locked, but identity is revealed and (optionally) progress toward
/// unlock is shown. Two flavours per proposal §4.3, distinguished by
/// the numeric payload — no separate state needed:
///
///   - **No progress** (`satisfiedConditions == 0 && totalConditions == 0`):
///     the catalog row's name + assetKey + unlock hint show; no progress
///     chip. Maps from `CosmeticRevealState.visibleLocked`.
///   - **Partial progress** (`totalConditions > 0`): the card / sheet
///     shows a `satisfied/total` chip and the companion checklist when
///     [conditionRows] is non-null. Maps from `CosmeticRevealState.partial`.
///
/// [conditionRows] is non-null for companion cosmetics whose evaluator
/// rule populated a per-condition checklist (handled by
/// `CosmeticRevealEvaluator`; the lifecycle just forwards the payload).
@immutable
class CosmeticTeased extends PlayerCosmeticLifecycle {
  const CosmeticTeased({
    this.satisfiedConditions = 0,
    this.totalConditions = 0,
    this.conditionRows,
  });

  /// Number of unlock conditions already satisfied for the
  /// best-matching rule. Zero for the no-progress / visibleLocked
  /// flavour.
  final int satisfiedConditions;

  /// Total number of conditions on the best-matching rule. Zero when
  /// no progress chip should render.
  final int totalConditions;

  /// Companion checklist rows (one per condition). Non-null when the
  /// evaluator produced rows — typically companion cosmetics whose
  /// rule the reveal evaluator inspected.
  final List<CosmeticRevealConditionRow>? conditionRows;

  /// True when the lifecycle should drive a `satisfied/total`
  /// progress chip. Reserved for the partial flavour.
  bool get hasProgress => totalConditions > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CosmeticTeased &&
        other.satisfiedConditions == satisfiedConditions &&
        other.totalConditions == totalConditions &&
        _rowsEqual(other.conditionRows, conditionRows);
  }

  @override
  int get hashCode => Object.hash(
        CosmeticTeased,
        satisfiedConditions,
        totalConditions,
        conditionRows == null
            ? null
            : Object.hashAll(
                conditionRows!.map((r) => Object.hash(r.conditionId, r.met)),
              ),
      );

  @override
  String toString() => 'CosmeticTeased('
      'satisfied: $satisfiedConditions, total: $totalConditions, '
      'rows: ${conditionRows?.length ?? 0})';
}

/// All unlock conditions met and the engine has surfaced a manual-claim
/// gate. Today the only producer is `CompanionAvailability` — the
/// player taps "Vyzvedni" inside the details sheet to land on
/// [CosmeticOwned]. Identity stays hidden until claim per the
/// proposal-spec helper.
///
/// [claimVia] is the gating node id (typically the companion's
/// `CompanionAvailability` id == cosmeticId). Nullable for future
/// non-availability claim paths (e.g. premium store grants); today
/// always equals the cosmetic id.
@immutable
class CosmeticClaimable extends PlayerCosmeticLifecycle {
  const CosmeticClaimable({this.claimVia});

  /// Catalog id of the gating node that surfaced the claim. Null when
  /// the claim path is not a progression node (no current producer).
  final String? claimVia;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CosmeticClaimable && other.claimVia == claimVia;
  }

  @override
  int get hashCode => Object.hash(CosmeticClaimable, claimVia);

  @override
  String toString() => 'CosmeticClaimable(claimVia: $claimVia)';
}

/// Terminal state — the cosmetic lives in the player's [Inventory].
/// Carries provenance fields so screens can render "Splněno
/// dd.mm.yyyy" captions and Journey timeline can attribute the unlock.
///
/// [source] mirrors [CosmeticUnlockSource] (open-set string today; the
/// strict enum is documented as informational on consumers). [sourceId]
/// is the per-source identifier (e.g. node id for progression unlocks,
/// SKU for premium grants). Both nullable for legacy entries that
/// pre-date the source tracking.
@immutable
class CosmeticOwned extends PlayerCosmeticLifecycle {
  const CosmeticOwned({
    required this.unlockedAt,
    this.source,
    this.sourceId,
  });

  /// Wall-clock timestamp the unlock was recorded. Today sourced from
  /// the `UnlockedCosmetic.unlockedAt` field; when Phase 20 lands the
  /// Journal projection rebuild path this becomes the earliest
  /// `RewardGrantEvent(CosmeticReward)` for the cosmetic id.
  final DateTime unlockedAt;

  /// Open-set string describing where the unlock came from. Recommended
  /// values match [CosmeticUnlockSource]; unknown values are
  /// informational only.
  final String? source;

  /// Per-source identifier (e.g. `progression:companion_dragonling`,
  /// `manual:devtools`). Null when source-internal attribution is
  /// missing.
  final String? sourceId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CosmeticOwned &&
        other.unlockedAt == unlockedAt &&
        other.source == source &&
        other.sourceId == sourceId;
  }

  @override
  int get hashCode => Object.hash(CosmeticOwned, unlockedAt, source, sourceId);

  @override
  String toString() =>
      'CosmeticOwned(at: $unlockedAt, source: $source/$sourceId)';
}

bool _rowsEqual(
  List<CosmeticRevealConditionRow>? a,
  List<CosmeticRevealConditionRow>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].conditionId != b[i].conditionId || a[i].met != b[i].met) {
      return false;
    }
  }
  return true;
}

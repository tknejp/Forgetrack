import 'package:meta/meta.dart';

/// Bundle of runtime overrides the engine evaluator consumes during
/// one evaluation pass, sourced from `ProgressionEngineProvider`
/// state (not from the Journal).
///
/// Phase 16 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 16) keeps these distinct from `LedgerCounters` so the
/// boundary stays crisp: counters are journal-derived (deterministic
/// re-computable function of `Journal.events`); overrides are
/// provider-runtime decisions that bypass the metric switch for a
/// specific objective.
///
/// Today the only override is `objectiveActualOverrides` — chapter-
/// step objectives whose counter must start from the moment the
/// chain step unlocked instead of all-time. The bundle exists as its
/// own value object because future overrides (e.g. devtools-forced
/// objective values, A/B-tested baselines) belong here, not on
/// counters.
@immutable
class EvaluationOverrides {
  const EvaluationOverrides({
    this.objectiveActualOverrides = const {},
  });

  /// Empty sentinel — used by tests / pre-first-evaluation provider
  /// state.
  static const EvaluationOverrides empty = EvaluationOverrides();

  /// `objectiveId → measured value override` — bypasses the metric
  /// switch in `ObjectiveEvaluator` for objectives whose actual value
  /// is computed elsewhere from the ledger. Used today by
  /// `Objective.baselineFromNodeId` — chapter step objectives whose
  /// counter must start from the moment the chain step unlocked
  /// instead of all-time.
  final Map<String, double> objectiveActualOverrides;

  EvaluationOverrides copyWith({
    Map<String, double>? objectiveActualOverrides,
  }) {
    return EvaluationOverrides(
      objectiveActualOverrides:
          objectiveActualOverrides ?? this.objectiveActualOverrides,
    );
  }
}

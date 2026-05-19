/// Coarse domain tag attached to [Objective]s, [RewardDefinition]s and
/// progression entries so streak-by-domain aggregation, display
/// helpers and content filters can reason about *what kind of thing*
/// a node measures without inspecting the metric.
///
/// **Pure data only.** This enum carries no design-token, icon, or
/// localised label — those are presentation chrome and live in
/// `lib/features/progression_engine/presentation/progression_domain_chrome.dart`.
/// Keeping the enum pure lets [Objective] live in
/// `lib/domain/progression/catalog/` without dragging Flutter / Material
/// into the domain layer (see `docs/architecture.md` §Dependency rules).
///
/// **Serialisation.** Stored values use `.name` (Isar + Firestore), so
/// adding a new variant requires picking a new name; renaming an
/// existing one is a wire-format break.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.3 (Objective.domain).
///   - `docs/domain_model/follow_ups.md` R.1 (catalog migration).
enum ProgressionDomain {
  steps,
  nutrition,
  sleep,
  activity,
  body,
}

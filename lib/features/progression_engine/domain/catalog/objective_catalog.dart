import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'content/activity_content.dart';
import 'content/body_content.dart';
import 'content/chapter_content.dart';
import 'content/chapter_side_quest_content.dart';
import 'content/combo_content.dart';
import 'content/daily_challenge_content.dart';
import 'content/level_milestones.dart';
import 'content/long_term_content.dart';
import 'content/meta_content.dart';
import 'content/nutrition_content.dart';
import 'content/sleep_content.dart';
import 'content/steps_content.dart';
import 'content/welcome_content.dart';
import 'engine_catalog_context.dart';

/// Aggregator for all objective definitions in the engine.
///
/// Content lives in `content/<domain>_content.dart` files; this class
/// concatenates them and provides the static `definitionForId` lookup
/// downstream consumers (validator, display, debug) call.
///
/// Adding a new domain: create `content/<domain>_content.dart` with
/// a top-level `<domain>Objectives(EngineCatalogContext)` function
/// and add it to the spread below.
class ObjectiveCatalog {
  const ObjectiveCatalog();

  /// Class-level lookup using the default goal set. Used by display
  /// helpers and the validator that do not know per-player goals.
  /// Live evaluation goes through `build(context)` with current goals.
  static Objective? definitionForId(String id) => _byId[id];

  static final Map<String, Objective> _byId = {
    for (final def in const ObjectiveCatalog().build()) def.id: def,
  };

  // Cached default-context build — same rationale as the matching
  // cache on `ProgressionEntryCatalog`. Combo objective pre-allocation
  // added ~600 objectives; rebuilding this list on every `firstWhere`
  // inside the quest-screen hot path was the dominant cost in debug
  // mode.
  static List<Objective>? _cachedDefaultBuild;

  List<Objective> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) {
    if (identical(context, const EngineCatalogContext())) {
      return _cachedDefaultBuild ??= List.unmodifiable(_build(context));
    }
    return _build(context);
  }

  List<Objective> _build(EngineCatalogContext context) {
    return [
      ...stepsObjectives(context),
      ...nutritionObjectives(context),
      ...sleepObjectives(context),
      ...activityObjectives(context),
      ...bodyObjectives(context),
      ...metaObjectives(context),
      ...welcomeObjectives(context),
      ...levelMilestoneObjectives(context),
      ...chapterObjectives(),
      ...comboObjectives(context),
      ...dailyChallengeObjectives(context),
      ...chapterSideQuestObjectives(context),
      ...longTermObjectives(),
    ];
  }
}

import '../models/progression_node_definition.dart';
import 'content/activity_content.dart';
import 'content/body_content.dart';
import 'content/chapter_forest_trial_content.dart';
import 'content/level_milestones.dart';
import 'content/meta_content.dart';
import 'content/nutrition_content.dart';
import 'content/rpg_placeholders.dart';
import 'content/sleep_content.dart';
import 'content/steps_content.dart';
import 'content/welcome_content.dart';
import 'engine_catalog_context.dart';

/// Aggregator for all progression nodes in the engine.
///
/// Content lives in `content/<domain>_content.dart` files; this class
/// concatenates them and provides the static `definitionForId` lookup.
///
/// Adding a new domain: create `content/<domain>_content.dart` with
/// a top-level `<domain>Nodes()` function and add it to the spread
/// below.
class ProgressionNodeCatalog {
  const ProgressionNodeCatalog();

  static ProgressionNode? definitionForId(String id) => _byId[id];

  static final Map<String, ProgressionNode> _byId = {
    for (final def in const ProgressionNodeCatalog().build()) def.id: def,
  };

  List<ProgressionNode> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) {
    return [
      ...stepsNodes(),
      ...nutritionNodes(),
      ...sleepNodes(),
      ...activityNodes(),
      ...bodyNodes(),
      ...metaNodes(),
      ...welcomeNodes(),
      ...levelMilestoneNodes(),
      ...rpgNodes(),
      ...forestTrialNodes(),
    ];
  }
}

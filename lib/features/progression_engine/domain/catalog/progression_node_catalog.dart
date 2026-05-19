import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'content/activity_content.dart';
import 'content/body_content.dart';
import 'content/chapter_content.dart';
import 'content/chapter_forest_trial_content.dart';
import 'content/chapter_pilgrim_path_content.dart';
import 'content/chapter_side_quest_content.dart';
import 'content/combo_content.dart';
import 'content/companions_content.dart';
import 'content/daily_challenge_content.dart';
import 'content/level_milestones.dart';
import 'content/long_term_content.dart';
import 'content/meta_content.dart';
import 'content/nutrition_content.dart';
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
class ProgressionEntryCatalog {
  const ProgressionEntryCatalog();

  static ProgressionEntry? definitionForId(String id) => _byId[id];

  static final Map<String, ProgressionEntry> _byId = {
    for (final def in const ProgressionEntryCatalog().build()) def.id: def,
  };

  List<ProgressionEntry> build([
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
      ...levelMilestones(),
      ...pilgrimPathNodes(),
      ...forestTrialNodes(),
      ...chapterNodes(),
      ...comboNodes(),
      ...companionNodes(),
      ...dailyChallenges(),
      ...chapterSideQuests(),
      ...longTermNodes(),
    ];
  }
}

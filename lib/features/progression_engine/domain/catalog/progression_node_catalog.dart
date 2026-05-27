import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'content/activity_content.dart';
import 'content/body_content.dart';
import 'content/chapter_content.dart';
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

  // Cached default-context build. The catalog is a pure function of
  // its context, every hot caller (provider quest-screen getters,
  // devtools pickers, achievement helpers) passes the default
  // context, and combo chain pre-allocation (50 gens × ~13 nodes)
  // inflated the result list. Rebuilding it from scratch on every
  // walk dominated quest-screen debug-mode frames; cache the
  // canonical-context build and fall through for any custom context.
  static List<ProgressionEntry>? _cachedDefaultBuild;

  List<ProgressionEntry> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) {
    if (identical(context, const EngineCatalogContext())) {
      return _cachedDefaultBuild ??= List.unmodifiable(_build(context));
    }
    return _build(context);
  }

  List<ProgressionEntry> _build(EngineCatalogContext context) {
    return [
      ...stepsNodes(),
      ...nutritionNodes(),
      ...sleepNodes(),
      ...activityNodes(),
      ...bodyNodes(),
      ...metaNodes(),
      ...welcomeNodes(),
      ...levelMilestones(),
      ...chapterNodes(),
      ...comboNodes(),
      ...companionNodes(),
      ...dailyChallenges(),
      ...chapterSideQuests(),
      ...longTermNodes(),
    ];
  }
}

import 'package:forgetrack/domain/progression/player/player_quest.dart';
import 'package:forgetrack/domain/progression/player/player_quest_catalog.dart';

import 'progression_engine_provider.dart';

/// Application-layer adapter that builds a [PlayerQuestCatalog] from
/// the engine's per-evaluation [EngineQuestProgress] view-model list.
///
/// **Why an adapter.** [PlayerQuestCatalog] is pure-domain — it has
/// no idea what an [EngineQuestProgress] is. The engine produces
/// view-model snapshots with display metadata (`domain`, `levelGate`,
/// `valueUnit`, ...) on top of the underlying lifecycle; the catalog
/// only needs the lifecycle discriminator + the typed id + the
/// evaluation timestamp. This service projects from one shape to the
/// other.
///
/// **Lifecycle source.** Phase 6 introduced the
/// `EngineQuestProgress.lifecycle` bridge getter; this service reads
/// through that bridge. When Phase 8+/Phase 13+ rework the engine
/// output the bridge moves elsewhere, but the catalog API stays the
/// same.
///
/// **Stateless.** Service holds no state. The provider caches the
/// resulting catalog and invalidates on each evaluation refresh.
class PlayerQuestCatalogService {
  const PlayerQuestCatalogService();

  /// Build a [PlayerQuestCatalog] from [questProgressEntries] (the
  /// union of the engine's bucket lists — daily, weekly, chapter,
  /// long-term). [evaluatedAt] is stamped on every produced
  /// [PlayerQuest] so downstream consumers can detect staleness.
  ///
  /// Duplicate quest ids (e.g. when a quest appears in multiple
  /// buckets — typically not the case in V2, but defensive) keep
  /// the last occurrence per Dart map semantics; this matches the
  /// [PlayerQuestCatalog.fromEntries] contract.
  PlayerQuestCatalog build({
    required Iterable<EngineQuestProgress> questProgressEntries,
    required DateTime evaluatedAt,
  }) {
    final entries = <PlayerQuest>[
      for (final progress in questProgressEntries)
        PlayerQuest(
          quest: progress.node,
          lifecycle: progress.lifecycle,
          evaluatedAt: evaluatedAt,
        ),
    ];
    return PlayerQuestCatalog.fromEntries(entries);
  }
}

import 'progression_models.dart';
import 'progression_repository.dart';

/// Extended repository interface for the local (Isar) layer.
///
/// Adds Firestore-restore operations that are only meaningful for the local
/// store. [HybridProgressionRepository] uses these to hydrate Isar after a
/// pull without going through the normal evaluation pipeline.
abstract class ProgressionLocalRepository extends ProgressionRepository {
  /// Inserts a claimed rule grant that was restored from Firestore.
  /// Must be a no-op if the [rewardKey] already exists locally.
  Future<void> insertRestoredRuleGrant(ProgressionRewardGrant grant);

  /// Inserts a claimed quest grant that was restored from Firestore.
  /// Must be a no-op if the [rewardKey] already exists locally.
  Future<void> insertRestoredQuestGrant(ProgressionQuestRewardGrant grant);

  /// **Devtools only.** Removes every progression record from local storage
  /// and (for hybrid repos) clears the matching cloud documents and any
  /// migration / pull-tracking flags.
  ///
  /// Intended for the in-app devtools panel and tests. Never call from
  /// production code paths.
  Future<void> wipeAllProgressionData();
}

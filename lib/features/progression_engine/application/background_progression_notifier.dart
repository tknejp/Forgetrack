import 'dart:async';

import 'package:forgetrack/domain/player/player.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/services/notification_service.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../data/local/progression_engine_database.dart';
import '../data/provider_engine_input_source.dart';
import '../data/isar_progression_engine_repository.dart';
import '../domain/catalog/progression_node_catalog.dart';
import '../domain/models/ledger_counters.dart';
import '../domain/models/progression_resolution_reason.dart';
import '../domain/models/progression_resolution_result.dart';
import '../domain/policy/level_policy.dart';
import 'progression_engine.dart';

/// WorkManager background producer for V2 quest + achievement push
/// notifications.
///
/// Closes Trello #80. The live engine only evaluates on app
/// foreground / proxy-provider bind, so without a background producer
/// a player who doesn't open the app misses every newly-completed
/// quest until they do. This service runs `engine.evaluate()` from the
/// WorkManager isolate against the same Isar-backed ledger, then fires
/// local notifications for the result's [completedNodes].
///
/// **Counter scope.** `LedgerCounters.empty` is passed in lieu of the
/// full counter-derivation graph the live provider runs. The bulk of
/// user-visible quests (daily steps / sleep / calories / activity)
/// depend only on `HealthSnapshot` / `NutritionSnapshot` / `GoalBoard`,
/// so they fire correctly. Cross-quest milestones that consult counters
/// (e.g. "complete N quests", "best perfect-day streak ≥ X") only fire
/// on the next foreground evaluation. Same trade-off the card's "open
/// questions" section calls out.
///
/// **Cosmetic dispatch.** Cosmetic-bearing reward grants written from
/// background land in the ledger but the [CosmeticUnlockBridge] runs
/// only in the live provider — the bridge's `rebuildFromJournal` already
/// fires on cloud-pull, so a player on a cloud-synced account converges
/// on next app open. Single-device players' cosmetic-bearing rewards
/// surface on the next foreground completion (which triggers a fresh
/// dispatch). Acceptable for personal-use scope.
///
/// **Spam cap.** 3 quest + 3 achievement notifications per run, mirroring
/// the pre-Phase-22 V1 background behaviour. Index suffixes (`_idQuestBase
/// + index` / `_idAchievementBase + index` inside `NotificationService`)
/// avoid the Android system squashing them into a single id.
///
/// **Idempotency.** The engine's append path is keyed by `eventKey`, so
/// re-running the producer against an unchanged ledger emits an empty
/// `result.completedNodes` — no double notifications across WorkManager
/// retries.
class BackgroundProgressionNotifier {
  const BackgroundProgressionNotifier();

  static const _log = 'BackgroundProgressionNotifier';
  static const _questCap = 3;
  static const _achievementCap = 3;

  /// Runs one engine evaluation pass and fires up to [_questCap] +
  /// [_achievementCap] notifications. Returns the total number of
  /// notifications dispatched, useful for the WorkManager DevTools
  /// debug summary.
  ///
  /// All errors are caught + logged; the caller's WorkManager retry
  /// decision stays driven by the surrounding try/catch in
  /// `background_sync_service.dart`.
  Future<int> notifyForNewCompletions({
    required FitnessProvider fitness,
    required KalorickeTabulkyProvider nutrition,
    required GoalsProvider goals,
  }) async {
    final db = ProgressionEngineDatabase();
    try {
      await db.open();
      final repo = IsarProgressionEngineRepository(db);
      final engine = ProgressionEngine(repository: repo);

      final ledger = await repo.loadLedger();
      final allEvents = ledger.all.toList();

      // Mirrors `ProgressionEngineProvider._buildPlayer` minus the
      // `uid` plumbing — the engine reads `Player.totalXp` for reward
      // scaling but does not consult `uid`, so the background pass
      // uses the empty string. `joinedAt` falls back to the earliest
      // event so level curve math stays stable across runs; pre-first-
      // event ledgers (brand-new install) won't have completions to
      // notify on anyway.
      final joinedAt = _earliestEventTimestamp(allEvents) ?? DateTime.now();
      final player = Player.fromJournal(
        uid: '',
        rewardGrants: ledger.rewardGrants,
        levelCurve: const LevelCurve(),
        joinedAt: joinedAt,
      );

      final source = ProviderEngineInputSource(
        goals: goals,
        fitness: fitness,
        nutrition: nutrition,
      );
      final context = source.buildContext(
        player: player,
        events: allEvents,
        counters: LedgerCounters.empty,
      );

      final result = await engine.evaluate(
        player: context.player,
        healthSnapshot: context.healthSnapshot,
        nutritionSnapshot: context.nutritionSnapshot,
        goalBoard: context.goalBoard,
        journal: context.journal,
        counters: context.counters,
        overrides: context.overrides,
        evaluatedAt: context.evaluatedAt,
        catalogContext: source.currentContext(),
        reason: ProgressionResolutionReason.backgroundSync,
      );

      if (result.completedNodes.isEmpty) {
        AppLog.app.debug(
          '$_log: evaluation produced no newly-completed nodes',
        );
        return 0;
      }

      return _dispatchNotifications(result);
    } catch (e, st) {
      AppLog.app.error(
        '$_log: background evaluation failed',
        err: e,
        stackTrace: st,
      );
      return 0;
    } finally {
      try {
        await db.close();
      } catch (_) {
        // Background isolate dies right after this returns — best-effort.
      }
    }
  }

  Future<int> _dispatchNotifications(
    ProgressionResolutionResult result,
  ) async {
    final l10n = await NotificationService.instance.resolveLocalizations();

    // Pre-index granted XP by nodeId so the body can show the actual
    // scaled amount the engine wrote to the ledger (companion / emblem
    // buffs change the headline number per node).
    final xpByNodeId = <String, int>{};
    for (final grant in result.grantedRewards) {
      final ev = grant.event;
      if (ev.rewardKind != RewardGrantKind.xp) continue;
      final amount = ev.xpAmount ?? 0;
      if (amount == 0) continue;
      xpByNodeId.update(
        ev.nodeId,
        (current) => current + amount,
        ifAbsent: () => amount,
      );
    }

    var questCount = 0;
    var achievementCount = 0;
    var dispatched = 0;
    for (final completion in result.completedNodes) {
      final node = ProgressionEntryCatalog.definitionForId(completion.nodeId);
      if (node == null) continue;

      if (node is Quest) {
        if (questCount >= _questCap) continue;
        final xp = xpByNodeId[completion.nodeId] ?? 0;
        await NotificationService.instance.showQuestCompleted(
          node.titleKey(l10n),
          xp,
          index: questCount,
        );
        questCount++;
        dispatched++;
      } else if (node is Achievement) {
        if (achievementCount >= _achievementCap) continue;
        await NotificationService.instance.showAchievementUnlocked(
          node.titleKey(l10n),
          node.descriptionKey(l10n),
          index: achievementCount,
        );
        achievementCount++;
        dispatched++;
      }
      // Other catalog entry types (LevelMilestone, ChapterCompletion,
      // CompanionAvailability, Relic, ContentUnlock, Milestone) don't
      // map onto the existing notification surface — skip silently.
    }

    AppLog.app.info(
      '$_log: dispatched=$dispatched quests=$questCount '
      'achievements=$achievementCount '
      '(of ${result.completedNodes.length} newly-completed nodes)',
    );
    return dispatched;
  }

  DateTime? _earliestEventTimestamp(List<JournalEvent> events) {
    DateTime? earliest;
    for (final e in events) {
      if (earliest == null || e.timestamp.isBefore(earliest)) {
        earliest = e.timestamp;
      }
    }
    return earliest;
  }
}

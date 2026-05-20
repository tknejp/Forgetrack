import 'package:forgetrack/domain/progression/catalog/activation_policy.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import 'package:forgetrack/domain/progression/catalog/content_tag.dart';
import 'package:forgetrack/domain/progression/catalog/objective.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import 'engine_catalog_context.dart';
import 'objective_catalog.dart';
import 'progression_node_catalog.dart';

/// One issue surfaced by the validator. `path` is a stable dotted
/// pointer ("nodes[sample_quest_steps_today].rewards[0]") so debug
/// log lines link straight to the offending entry.
class CatalogValidationIssue {
  const CatalogValidationIssue({
    required this.severity,
    required this.path,
    required this.message,
  });

  final CatalogValidationSeverity severity;
  final String path;
  final String message;

  @override
  String toString() => '[${severity.name.toUpperCase()}] $path — $message';
}

enum CatalogValidationSeverity { error, warning }

/// Thrown by [CatalogValidator.validateOrThrow] when at least one
/// error-severity issue is found. Warnings never throw.
class CatalogValidationException implements Exception {
  CatalogValidationException(this.issues);

  final List<CatalogValidationIssue> issues;

  @override
  String toString() {
    final lines = ['CatalogValidationException — ${issues.length} issue(s):'];
    for (final issue in issues) {
      lines.add('  $issue');
    }
    return lines.join('\n');
  }
}

/// Pure validator over the new engine's catalog. Phase 1 covers the
/// foundational checks (duplicate ids, missing objective references,
/// missing reward targets when relevant, claim/policy coherence);
/// further checks land alongside the features that need them
/// (chapters in Phase 3, RPG content tag coherence in Phase 8).
///
/// The validator is pure / deterministic — give it the same catalogs,
/// get the same issue list, in the same order.
class CatalogValidator {
  const CatalogValidator({
    this.objectiveCatalog = const ObjectiveCatalog(),
    this.nodeCatalog = const ProgressionEntryCatalog(),
  });

  final ObjectiveCatalog objectiveCatalog;
  final ProgressionEntryCatalog nodeCatalog;

  /// Returns every issue found, errors and warnings mixed. Order is
  /// stable: objectives first, then nodes in catalog order, with
  /// per-entry checks in declaration order.
  ///
  /// `context` parameterises the catalog with player-specific goals;
  /// validator output is identical across contexts unless an
  /// objective references a goal in a structurally invalid way (none
  /// today). Default context is sufficient for almost every caller.
  List<CatalogValidationIssue> validate([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) {
    final issues = <CatalogValidationIssue>[];
    final objectives = objectiveCatalog.build(context);
    final nodes = nodeCatalog.build(context);

    issues.addAll(_checkObjectiveIdentity(objectives));
    final knownObjectiveIds = {for (final o in objectives) o.id};

    issues.addAll(_checkNodeIdentity(nodes));
    issues.addAll(_checkNodeReferences(nodes, knownObjectiveIds));
    issues.addAll(_checkClaimPolicyCoherence(nodes));
    issues.addAll(_checkActivationContentTagCoherence(nodes));
    issues.addAll(_checkLevelMilestoneCoherence(nodes));

    return issues;
  }

  /// Shortcut: `validate()` and throw [CatalogValidationException] if
  /// any error-severity issues are present. Warnings are returned via
  /// [CatalogValidationException.issues] alongside errors so callers
  /// can log them.
  void validateOrThrow([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) {
    final issues = validate(context);
    final hasError = issues.any((i) => i.severity == CatalogValidationSeverity.error);
    if (hasError) throw CatalogValidationException(issues);
  }

  // ── Objective checks ────────────────────────────────────────────

  Iterable<CatalogValidationIssue> _checkObjectiveIdentity(
    List<Objective> objectives,
  ) sync* {
    final seen = <String>{};
    for (final o in objectives) {
      if (!seen.add(o.id)) {
        yield CatalogValidationIssue(
          severity: CatalogValidationSeverity.error,
          path: 'objectives[${o.id}]',
          message: 'Duplicate objective id.',
        );
      }
    }
  }

  // ── Node checks ─────────────────────────────────────────────────

  Iterable<CatalogValidationIssue> _checkNodeIdentity(
    List<ProgressionEntry> nodes,
  ) sync* {
    final seen = <String>{};
    for (final n in nodes) {
      if (!seen.add(n.id)) {
        yield CatalogValidationIssue(
          severity: CatalogValidationSeverity.error,
          path: 'nodes[${n.id}]',
          message: 'Duplicate node id.',
        );
      }
    }
  }

  Iterable<CatalogValidationIssue> _checkNodeReferences(
    List<ProgressionEntry> nodes,
    Set<String> knownObjectiveIds,
  ) sync* {
    final knownNodeIds = {for (final n in nodes) n.id};
    for (final n in nodes) {
      // Objective reference, if the node carries one.
      final referencedObjectiveId = _objectiveIdOf(n);
      if (referencedObjectiveId != null &&
          !knownObjectiveIds.contains(referencedObjectiveId)) {
        yield CatalogValidationIssue(
          severity: CatalogValidationSeverity.error,
          path: 'nodes[${n.id}].objectiveId',
          message:
              'References objective "$referencedObjectiveId" which is not in the catalog.',
        );
      }

      // Unlock conditions that point at other catalog entries.
      for (final issue
          in _checkUnlockConditionReferences(n.id, n.unlockConditions, knownNodeIds)) {
        yield issue;
      }
    }
  }

  Iterable<CatalogValidationIssue> _checkUnlockConditionReferences(
    String nodeId,
    List<UnlockCondition> conditions,
    Set<String> knownNodeIds,
  ) sync* {
    for (final c in conditions) {
      switch (c) {
        case AllOf(:final conditions):
        case AnyOf(:final conditions):
          for (final issue in _checkUnlockConditionReferences(
            nodeId,
            conditions,
            knownNodeIds,
          )) {
            yield issue;
          }
        case NodeCompleted(:final nodeId):
          if (!knownNodeIds.contains(nodeId)) {
            yield CatalogValidationIssue(
              severity: CatalogValidationSeverity.error,
              path: 'nodes[$nodeId].unlockConditions',
              message:
                  'NodeCompleted references node "$nodeId" which is not in the catalog.',
            );
          }
        case NodeCompletedBeforeToday(:final nodeId):
          if (!knownNodeIds.contains(nodeId)) {
            yield CatalogValidationIssue(
              severity: CatalogValidationSeverity.error,
              path: 'nodes[$nodeId].unlockConditions',
              message:
                  'NodeCompletedBeforeToday references node "$nodeId" which is not in the catalog.',
            );
          }
        // Other condition types (LevelAtLeast, ObjectiveCompleted,
        // ChapterUnlocked, CompanionAvailable, OwnsCosmetic,
        // RpgModeEnabled) need catalog lookups (chapter catalog,
        // companion id lists, cosmetics catalog) that land in Phase 3.
        // For now these conditions pass without cross-checking.
        case LevelAtLeast():
        case ObjectiveCompleted():
        case ChapterUnlocked():
        case ChapterActive():
        case CompanionAvailable():
        case OwnsCosmetic():
        case RpgModeEnabled():
          break;
      }
    }
  }

  Iterable<CatalogValidationIssue> _checkClaimPolicyCoherence(
    List<ProgressionEntry> nodes,
  ) sync* {
    for (final n in nodes) {
      if (n.claimPolicy == ClaimPolicy.manual && n.lockedHintKey == null) {
        yield CatalogValidationIssue(
          severity: CatalogValidationSeverity.warning,
          path: 'nodes[${n.id}]',
          message:
              'Manual-claim node has no lockedHintKey — player may not know what to do.',
        );
      }
    }
  }

  Iterable<CatalogValidationIssue> _checkLevelMilestoneCoherence(
    List<ProgressionEntry> nodes,
  ) sync* {
    for (final n in nodes) {
      if (n is! LevelMilestone) continue;
      final levels = _flattenLevelAtLeast(n.unlockConditions);
      if (levels.isEmpty) {
        yield CatalogValidationIssue(
          severity: CatalogValidationSeverity.error,
          path: 'nodes[${n.id}].unlockConditions',
          message:
              'LevelMilestone level=${n.level} has no LevelAtLeast unlock condition.',
        );
        continue;
      }
      if (!levels.contains(n.level)) {
        yield CatalogValidationIssue(
          severity: CatalogValidationSeverity.error,
          path: 'nodes[${n.id}].unlockConditions',
          message:
              'LevelMilestone level=${n.level} unlock conditions reference $levels — none match.',
        );
      }
    }
  }

  /// Recursively walks AllOf/AnyOf to collect every `LevelAtLeast.level`.
  List<int> _flattenLevelAtLeast(List<UnlockCondition> conditions) {
    final out = <int>[];
    for (final c in conditions) {
      switch (c) {
        case LevelAtLeast(:final level):
          out.add(level);
        case AllOf(:final conditions):
        case AnyOf(:final conditions):
          out.addAll(_flattenLevelAtLeast(conditions));
        case ObjectiveCompleted():
        case NodeCompleted():
        case NodeCompletedBeforeToday():
        case ChapterUnlocked():
        case ChapterActive():
        case CompanionAvailable():
        case OwnsCosmetic():
        case RpgModeEnabled():
          break;
      }
    }
    return out;
  }

  Iterable<CatalogValidationIssue> _checkActivationContentTagCoherence(
    List<ProgressionEntry> nodes,
  ) sync* {
    for (final n in nodes) {
      final isRpgPolicy =
          n.activationPolicy == ActivationPolicy.onlyWhenRpgEnabled ||
              n.activationPolicy ==
                  ActivationPolicy.onlyWhenRpgEnabledNoBackfill;
      final hasRpgTag = n.contentTags.contains(ContentTag.rpg) ||
          n.contentTags.contains(ContentTag.relics) ||
          n.contentTags.contains(ContentTag.companions);
      if (isRpgPolicy && !hasRpgTag) {
        yield CatalogValidationIssue(
          severity: CatalogValidationSeverity.warning,
          path: 'nodes[${n.id}]',
          message:
              'Activation policy ${n.activationPolicy.name} but no RPG-flavored ContentTag — drift risk.',
        );
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  /// Returns the `objectiveId` field on the node when present, null
  /// for node types that are unlock-condition-only.
  String? _objectiveIdOf(ProgressionEntry node) {
    return switch (node) {
      Quest(:final objectiveId) => objectiveId,
      Achievement(:final objectiveId) => objectiveId,
      Milestone(:final objectiveId) => objectiveId,
      LevelMilestone() => null,
      ChapterCompletion() => null,
      CompanionAvailability() => null,
      Relic() => null,
      ContentUnlock() => null,
    };
  }
}

// Currently unused — keeps the analyzer happy when a future check
// needs to introspect rewards by type.
// ignore: unused_element
List<RewardDefinition> _allRewards(List<ProgressionEntry> nodes) =>
    nodes.expand((n) => n.rewards).toList(growable: false);

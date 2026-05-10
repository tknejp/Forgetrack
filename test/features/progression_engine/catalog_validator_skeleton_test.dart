import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/domain/catalog/catalog_validator.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/objective_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/models/activation_policy.dart';
import 'package:forgetrack/features/progression_engine/domain/models/claim_policy.dart';
import 'package:forgetrack/features/progression_engine/domain/models/content_tag.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_metric.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_operator.dart';
import 'package:forgetrack/features/progression_engine/domain/models/objective_scope.dart';
import 'package:forgetrack/features/progression_engine/domain/models/progression_node_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/models/quest_display_bucket.dart';
import 'package:forgetrack/features/progression_engine/domain/models/reward_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/models/unlock_condition.dart';
import 'package:forgetrack/shared/domain/rarity.dart';

class _FakeObjectiveCatalog extends ObjectiveCatalog {
  const _FakeObjectiveCatalog(this._defs);
  final List<ObjectiveDefinition> _defs;

  @override
  List<ObjectiveDefinition> build() => _defs;
}

class _FakeNodeCatalog extends ProgressionNodeCatalog {
  const _FakeNodeCatalog(this._nodes);
  final List<ProgressionNode> _nodes;

  @override
  List<ProgressionNode> build() => _nodes;
}

ObjectiveDefinition _objective(String id) => ObjectiveDefinition(
      id: id,
      metric: const StepsMetric(),
      scope: const TodayScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: 1000,
    );

QuestNode _quest({
  required String id,
  required String objectiveId,
  ClaimPolicy claimPolicy = ClaimPolicy.automatic,
  ActivationPolicy activationPolicy = ActivationPolicy.always,
  List<ContentTag> contentTags = const [],
  List<UnlockCondition> unlockConditions = const [],
}) =>
    QuestNode(
      id: id,
      objectiveId: objectiveId,
      displayBucket: QuestDisplayBucket.daily,
      titleKey: (_) => 'Title $id',
      descriptionKey: (_) => 'Desc $id',
      rewards: const [XpReward(amount: 10)],
      claimPolicy: claimPolicy,
      activationPolicy: activationPolicy,
      contentTags: contentTags,
      unlockConditions: unlockConditions,
      rarity: Rarity.common,
    );

void main() {
  group('CatalogValidator — identity', () {
    test('flags duplicate objective ids as errors', () {
      final validator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([
          _objective('dup'),
          _objective('dup'),
        ]),
        nodeCatalog: const _FakeNodeCatalog([]),
      );
      final issues = validator.validate();
      expect(
        issues.where((i) =>
            i.severity == CatalogValidationSeverity.error &&
            i.message.contains('Duplicate objective id')),
        hasLength(1),
      );
    });

    test('flags duplicate node ids as errors', () {
      final validator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([_objective('o1')]),
        nodeCatalog: _FakeNodeCatalog([
          _quest(id: 'dup', objectiveId: 'o1'),
          _quest(id: 'dup', objectiveId: 'o1'),
        ]),
      );
      final issues = validator.validate();
      expect(
        issues.where((i) =>
            i.severity == CatalogValidationSeverity.error &&
            i.message.contains('Duplicate node id')),
        hasLength(1),
      );
    });

    test('validateOrThrow throws on errors but not on warnings', () {
      final dupValidator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([
          _objective('dup'),
          _objective('dup'),
        ]),
        nodeCatalog: const _FakeNodeCatalog([]),
      );
      expect(dupValidator.validateOrThrow,
          throwsA(isA<CatalogValidationException>()));

      // Warning-only catalog should not throw.
      final warningValidator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([_objective('o1')]),
        nodeCatalog: _FakeNodeCatalog([
          _quest(
            id: 'q1',
            objectiveId: 'o1',
            // Manual without lockedHintKey → warning, not error.
            claimPolicy: ClaimPolicy.manual,
          ),
        ]),
      );
      expect(warningValidator.validateOrThrow, returnsNormally);
    });
  });

  group('CatalogValidator — references', () {
    test('flags node referencing unknown objective', () {
      final validator = CatalogValidator(
        objectiveCatalog: const _FakeObjectiveCatalog([]),
        nodeCatalog: _FakeNodeCatalog([
          _quest(id: 'q1', objectiveId: 'does_not_exist'),
        ]),
      );
      final issues = validator.validate();
      expect(
        issues.where((i) =>
            i.severity == CatalogValidationSeverity.error &&
            i.message.contains('does_not_exist')),
        hasLength(1),
      );
    });

    test('flags NodeCompleted referencing unknown node id', () {
      final validator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([_objective('o1')]),
        nodeCatalog: _FakeNodeCatalog([
          _quest(
            id: 'q1',
            objectiveId: 'o1',
            unlockConditions: const [NodeCompleted('phantom_node')],
          ),
        ]),
      );
      final issues = validator.validate();
      expect(
        issues.where((i) => i.message.contains('phantom_node')),
        hasLength(1),
      );
    });
  });

  group('CatalogValidator — coherence warnings', () {
    test('warns on manual claim node missing lockedHintKey', () {
      final validator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([_objective('o1')]),
        nodeCatalog: _FakeNodeCatalog([
          _quest(id: 'q1', objectiveId: 'o1', claimPolicy: ClaimPolicy.manual),
        ]),
      );
      final issues = validator.validate();
      expect(
        issues.where((i) =>
            i.severity == CatalogValidationSeverity.warning &&
            i.message.contains('lockedHintKey')),
        hasLength(1),
      );
    });

    test('warns on RPG activation policy without RPG content tag', () {
      final validator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([_objective('o1')]),
        nodeCatalog: _FakeNodeCatalog([
          _quest(
            id: 'q1',
            objectiveId: 'o1',
            activationPolicy: ActivationPolicy.onlyWhenRpgEnabled,
            contentTags: const [ContentTag.fitness],
          ),
        ]),
      );
      final issues = validator.validate();
      expect(
        issues.where((i) =>
            i.severity == CatalogValidationSeverity.warning &&
            i.message.contains('RPG-flavored ContentTag')),
        hasLength(1),
      );
    });

    test('does not warn when RPG activation matches RPG content tag', () {
      final validator = CatalogValidator(
        objectiveCatalog: _FakeObjectiveCatalog([_objective('o1')]),
        nodeCatalog: _FakeNodeCatalog([
          _quest(
            id: 'q1',
            objectiveId: 'o1',
            activationPolicy: ActivationPolicy.onlyWhenRpgEnabled,
            contentTags: const [ContentTag.rpg],
          ),
        ]),
      );
      final issues = validator.validate();
      expect(
        issues.where((i) => i.message.contains('RPG-flavored')),
        isEmpty,
      );
    });
  });

  group('CatalogValidator — real catalogs', () {
    test('the shipped sample catalogs validate cleanly', () {
      const validator = CatalogValidator();
      expect(validator.validateOrThrow, returnsNormally);
    });
  });
}

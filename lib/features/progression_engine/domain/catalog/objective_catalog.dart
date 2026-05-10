import '../models/objective_definition.dart';
import '../models/objective_metric.dart';
import '../models/objective_operator.dart';
import '../models/objective_scope.dart';

/// Catalog of objective definitions. Phase 1 ships an empty `build()`
/// plus a single sample to keep the validator exercised end-to-end;
/// real content lands during Phase 3 (catalog port).
class ObjectiveCatalog {
  const ObjectiveCatalog();

  static ObjectiveDefinition? definitionForId(String id) => _byId[id];

  static final Map<String, ObjectiveDefinition> _byId = {
    for (final def in const ObjectiveCatalog().build()) def.id: def,
  };

  List<ObjectiveDefinition> build() {
    return const [
      // Sample objective so the validator + tests have something to
      // chew on. Real catalog port (Phase 3) will replace these.
      ObjectiveDefinition(
        id: 'sample_steps_today',
        metric: StepsMetric(),
        scope: TodayScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: 10000,
        debugLabel: 'Steps today >= 10000',
      ),
      ObjectiveDefinition(
        id: 'sample_level_5',
        metric: LevelMetric(),
        scope: LifetimeScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: 5,
        debugLabel: 'Level >= 5',
      ),
    ];
  }
}

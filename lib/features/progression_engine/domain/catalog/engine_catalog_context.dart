import 'package:meta/meta.dart';

/// Player-configurable goal targets that the catalog reads when
/// constructing daily / weekly objectives. Same role as the legacy
/// `ProgressionGoalSet`; lives here so V2 catalogs do not import
/// legacy types.
@immutable
class EngineGoalSet {
  const EngineGoalSet({
    this.dailySteps = 10000,
    this.dailyCalories = 2000,
    this.dailyProteinGrams = 150,
    this.dailyCarbsGrams = 250,
    this.dailyFatGrams = 65,
    this.dailyFiberGrams = 30,
    this.sleepMinutes = 480,
    this.weeklyActivityMinutes = 150,
    this.dailyActivityMinutes = 30,
    this.targetWeightKg = 70.0,
  });

  final int dailySteps;
  final double dailyCalories;
  final double dailyProteinGrams;
  final double dailyCarbsGrams;
  final double dailyFatGrams;
  final double dailyFiberGrams;
  final int sleepMinutes;
  final int weeklyActivityMinutes;
  final int dailyActivityMinutes;
  final double targetWeightKg;
}

/// Context handed to catalog `build()` methods. Today only carries
/// goals; future entries will hold RPG content variants, chapter
/// overrides, debug flags, etc. Default value is fine for static
/// lookups (`ObjectiveCatalog._byId`) and for tests that don't care
/// about goals.
@immutable
class EngineCatalogContext {
  const EngineCatalogContext({this.goals = const EngineGoalSet()});

  final EngineGoalSet goals;
}

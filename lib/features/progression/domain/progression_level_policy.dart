import 'progression_models.dart';

class ProgressionLevelPolicy {
  const ProgressionLevelPolicy({
    this.baseDailyRewardXp = 230,
    this.baseWeeklyRewardXp = 120,
    this.level30RewardMultiplier = 12.5,
    this.level50RewardMultiplier = 62.5,
    this.level100RewardMultiplier = 150.0,
    this.level1DaysToAdvance = 1.15,
    this.level10DaysToAdvance = 2.45,
    this.level30DaysToAdvance = 6.2,
    this.level50DaysToAdvance = 11.8,
    this.level100DaysToAdvance = 21.0,
  })  : assert(baseDailyRewardXp > 0, 'baseDailyRewardXp must be positive'),
        assert(
          baseWeeklyRewardXp >= 0,
          'baseWeeklyRewardXp must be non-negative',
        ),
        assert(
          level30RewardMultiplier >= 1,
          'level30RewardMultiplier must be at least 1',
        ),
        assert(
          level50RewardMultiplier >= level30RewardMultiplier,
          'level50RewardMultiplier must be >= level30RewardMultiplier',
        ),
        assert(
          level100RewardMultiplier >= level50RewardMultiplier,
          'level100RewardMultiplier must be >= level50RewardMultiplier',
        );

  final int baseDailyRewardXp;
  final int baseWeeklyRewardXp;
  final double level30RewardMultiplier;
  final double level50RewardMultiplier;
  final double level100RewardMultiplier;
  final double level1DaysToAdvance;
  final double level10DaysToAdvance;
  final double level30DaysToAdvance;
  final double level50DaysToAdvance;
  final double level100DaysToAdvance;

  double rewardMultiplierForLevel(int level) {
    final safeLevel = level.clamp(1, 100);
    if (safeLevel <= 30) {
      return _lerp(
        1,
        level30RewardMultiplier,
        (safeLevel - 1) / 29,
      );
    }
    if (safeLevel <= 50) {
      return _lerp(
        level30RewardMultiplier,
        level50RewardMultiplier,
        (safeLevel - 30) / 20,
      );
    }
    return _lerp(
      level50RewardMultiplier,
      level100RewardMultiplier,
      (safeLevel - 50) / 50,
    );
  }

  int scaledRewardXp({
    required int baseXp,
    required int level,
  }) {
    final scaled = baseXp * rewardMultiplierForLevel(level);
    return _roundToNearest(scaled, 5);
  }

  double perfectDailyXpForLevel(int level) {
    final multiplier = rewardMultiplierForLevel(level);
    return (baseDailyRewardXp + (baseWeeklyRewardXp / 7)) * multiplier;
  }

  double targetDaysForLevel(int level) {
    final safeLevel = level.clamp(1, 100);
    if (safeLevel <= 10) {
      return _lerp(
        level1DaysToAdvance,
        level10DaysToAdvance,
        (safeLevel - 1) / 9,
      );
    }
    if (safeLevel <= 30) {
      return _lerp(
        level10DaysToAdvance,
        level30DaysToAdvance,
        (safeLevel - 10) / 20,
      );
    }
    if (safeLevel <= 50) {
      return _lerp(
        level30DaysToAdvance,
        level50DaysToAdvance,
        (safeLevel - 30) / 20,
      );
    }
    return _lerp(
      level50DaysToAdvance,
      level100DaysToAdvance,
      (safeLevel - 50) / 50,
    );
  }

  int levelForXp(int totalXp) {
    final safeXp = totalXp < 0 ? 0 : totalXp;
    var level = 1;

    while (xpRequiredForLevel(level + 1) <= safeXp) {
      level += 1;
    }

    return level;
  }

  int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;

    var total = 0;
    for (var currentLevel = 1; currentLevel < level; currentLevel += 1) {
      total += xpToAdvanceFromLevel(currentLevel);
    }
    return total;
  }

  int xpToAdvanceFromLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    final xpBudget =
        perfectDailyXpForLevel(safeLevel) * targetDaysForLevel(safeLevel);
    return _roundToNearest(xpBudget, 25);
  }

  ProgressionProfile resolve(int totalXp) {
    final safeXp = totalXp < 0 ? 0 : totalXp;
    final level = levelForXp(safeXp);
    final levelFloorXp = xpRequiredForLevel(level);
    final nextLevelXp = xpRequiredForLevel(level + 1);

    return ProgressionProfile(
      totalXp: safeXp,
      level: level,
      levelTitle: titleForLevel(level),
      levelFloorXp: levelFloorXp,
      nextLevelXp: nextLevelXp,
      xpIntoLevel: safeXp - levelFloorXp,
    );
  }

  String titleForLevel(int level) {
    if (level >= 100) return 'Living Legend';
    if (level >= 90) return 'Realm Sovereign';
    if (level >= 80) return 'Eternal Paragon';
    if (level >= 70) return 'Astral Champion';
    if (level >= 60) return 'Titan Forger';
    if (level >= 50) return 'Mythic Ranger';
    if (level >= 40) return 'Dragon Rider';
    if (level >= 30) return 'Castle Lord';
    if (level >= 25) return 'Storm Herald';
    if (level >= 20) return 'Iron Warden';
    if (level >= 15) return 'Forge Knight';
    if (level >= 10) return 'Pathfinder';
    if (level >= 5) return 'Wanderer';
    return 'Troll';
  }

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  int _roundToNearest(double value, int step) {
    if (step <= 1) return value.round();
    return ((value / step).round()) * step;
  }
}

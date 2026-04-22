import 'progression_models.dart';

class ProgressionLevelPolicy {
  const ProgressionLevelPolicy({
    this.xpPerLevel = 250,
    this.linearGrowthPerLevel = 50,
    this.quadraticGrowthPerLevel = 5,
  }) : assert(xpPerLevel > 0, 'xpPerLevel must be positive');

  final int xpPerLevel;
  final int linearGrowthPerLevel;
  final int quadraticGrowthPerLevel;

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
    final offset = safeLevel - 1;

    return xpPerLevel +
        (offset * linearGrowthPerLevel) +
        (offset * offset * quadraticGrowthPerLevel);
  }

  ProgressionProfile resolve(int totalXp) {
    final safeXp = totalXp < 0 ? 0 : totalXp;
    final level = levelForXp(safeXp);
    final levelFloorXp = xpRequiredForLevel(level);
    final nextLevelXp = xpRequiredForLevel(level + 1);

    return ProgressionProfile(
      totalXp: safeXp,
      level: level,
      levelTitle: _titleForLevel(level),
      levelFloorXp: levelFloorXp,
      nextLevelXp: nextLevelXp,
      xpIntoLevel: safeXp - levelFloorXp,
    );
  }

  String _titleForLevel(int level) {
    if (level >= 100) return 'Living Legend';
    if (level >= 90) return 'Realm Sovereign';
    if (level >= 80) return 'Eternal Paragon';
    if (level >= 70) return 'Astral Champion';
    if (level >= 60) return 'Titan Forger';
    if (level >= 50) return 'Mythic Ranger';
    if (level >= 40) return 'Rift Walker';
    if (level >= 30) return 'Dawn Sentinel';
    if (level >= 25) return 'Storm Herald';
    if (level >= 20) return 'Iron Warden';
    if (level >= 15) return 'Forge Knight';
    if (level >= 10) return 'Trail Vanguard';
    if (level >= 5) return 'Pathfinder';
    return 'Novice Adventurer';
  }
}

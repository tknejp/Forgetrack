import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/progression_level_config.dart';
import '../../domain/progression_models.dart';

@immutable
class ProgressionLevelBadgeStyle {
  const ProgressionLevelBadgeStyle({
    required this.color,
    required this.glow,
  });

  final Color color;
  final Color glow;

  Color get softFill => color.withValues(alpha: 0.20);
  Color get strongFill => color.withValues(alpha: 0.82);
  Color get border => color.withValues(alpha: 0.44);
}

ProgressionLevelBadgeStyle progressionLevelBadgeStyle(int level) {
  final color = progressionLevelAccent(level);
  return ProgressionLevelBadgeStyle(
    color: color,
    glow: color.withValues(alpha: 0.34),
  );
}

Color progressionLevelAccent(int level) {
  switch (tierForLevel(level).difficulty) {
    case ProgressionAchievementDifficulty.easy:
      return Tokens.difficultyEasy;
    case ProgressionAchievementDifficulty.medium:
      return Tokens.difficultyMedium;
    case ProgressionAchievementDifficulty.hard:
      return Tokens.difficultyHard;
    case ProgressionAchievementDifficulty.extraHard:
      return Tokens.difficultyExtraHard;
  }
}

class ProgressionLevelBadge extends StatelessWidget {
  const ProgressionLevelBadge({
    super.key,
    required this.level,
    this.size = 44,
  });

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = progressionLevelBadgeStyle(level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            style.strongFill,
            style.softFill,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.13),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: style.glow,
            blurRadius: size * 0.40,
            offset: Offset(0, size * 0.09),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: size * 0.39,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
      ),
    );
  }
}

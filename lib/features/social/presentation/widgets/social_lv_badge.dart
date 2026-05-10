import 'package:flutter/material.dart';

import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../progression_engine/presentation/widgets/level_badge.dart';

class SocialLvBadge extends StatelessWidget {
  const SocialLvBadge({super.key, required this.level, this.size = 36});

  final int level;
  final double size;

  static const _resolver = ProgressionDisplayResolver();

  @override
  Widget build(BuildContext context) {
    return LevelBadge(
      level: level,
      accentColor: _resolver.levelDisplay(level).accentColor,
      size: size,
    );
  }
}

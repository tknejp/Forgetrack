import 'package:flutter/material.dart';

import '../../../progression/presentation/widgets/progression_level_badge.dart';

class SocialLvBadge extends StatelessWidget {
  const SocialLvBadge({super.key, required this.level, this.size = 36});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ProgressionLevelBadge(level: level, size: size);
  }
}

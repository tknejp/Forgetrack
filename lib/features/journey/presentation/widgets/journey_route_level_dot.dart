import 'package:flutter/material.dart';

import 'journey_map_layout.dart';

class JourneyRouteLevelDot extends StatelessWidget {
  const JourneyRouteLevelDot({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    this.pulseAnimation,
  });

  final int level;
  final bool isUnlocked;
  final bool isCurrent;
  final Animation<double>? pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked
        ? JourneyMapLevelDotStyle.unlockedColor
        : Colors.white.withValues(alpha: 0.26);
    final size = isCurrent
        ? JourneyMapLayout.currentLevelDotSize
        : isUnlocked
            ? JourneyMapLayout.unlockedLevelDotSize
            : JourneyMapLayout.lockedLevelDotSize;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (pulseAnimation != null)
            AnimatedBuilder(
              animation: pulseAnimation!,
              builder: (_, __) {
                final v = pulseAnimation!.value;
                return Transform.scale(
                  scale: 1.0 + v * JourneyMapMotion.pulseScale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: (1 - v) * 0.62),
                        width: JourneyMapLevelDotStyle.pulseBorderWidth,
                      ),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCurrent
                  ? const RadialGradient(
                      colors: [Color(0xFFFFD980), Color(0xFFE5A833)],
                      radius: 0.85,
                    )
                  : null,
              color: isCurrent ? null : color,
              border: Border.all(
                color: isUnlocked
                    ? Colors.white.withValues(alpha: isCurrent ? 0.70 : 0.34)
                    : Colors.white.withValues(alpha: 0.12),
                width: isCurrent
                    ? JourneyMapLevelDotStyle.currentBorderWidth
                    : JourneyMapLevelDotStyle.defaultBorderWidth,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(
                          alpha: isCurrent
                              ? JourneyMapLevelDotStyle.currentGlowAlpha
                              : JourneyMapLevelDotStyle.defaultGlowAlpha,
                        ),
                        blurRadius: isCurrent
                            ? JourneyMapLevelDotStyle.currentGlowBlur
                            : JourneyMapLevelDotStyle.defaultGlowBlur,
                        spreadRadius: isCurrent ? 0 : -1,
                      ),
                    ]
                  : null,
            ),
            child: isCurrent
                ? Center(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        fontSize: JourneyMapLevelDotStyle.currentTextSize,
                        fontWeight: FontWeight.w900,
                        color: JourneyMapLevelDotStyle.currentTextColor,
                        letterSpacing:
                            JourneyMapLevelDotStyle.currentLetterSpacing,
                        height: 1,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

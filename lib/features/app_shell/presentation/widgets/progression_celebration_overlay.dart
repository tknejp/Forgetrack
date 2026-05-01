import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/cosmetics_l10n.dart';
import '../../../cosmetics/presentation/cosmetics_palette.dart';
import '../../../progression/application/progression_provider.dart';
import '../../../progression/domain/progression_level_config.dart';
import '../../../progression/domain/progression_models.dart';
import '../../../progression/presentation/progression_l10n.dart';

class ProgressionCelebrationOverlay extends StatefulWidget {
  const ProgressionCelebrationOverlay({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  final ProgressionCelebrationEvent event;
  final VoidCallback onDismiss;

  @override
  State<ProgressionCelebrationOverlay> createState() =>
      _ProgressionCelebrationOverlayState();
}

class _ProgressionCelebrationOverlayState
    extends State<ProgressionCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ProgressionCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onDismiss,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, Tokens.spaceSm, 10, 0),
            child: AnimatedBuilder(
              animation: _curve,
              builder: (context, child) {
                final t = _curve.value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * -18),
                    child: Transform.scale(
                      scale: 0.94 + (0.06 * t),
                      child: child,
                    ),
                  ),
                );
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: _CelebrationCard(
                  event: widget.event,
                  animation: _curve,
                  onDismiss: widget.onDismiss,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({
    required this.event,
    required this.animation,
    required this.onDismiss,
  });

  final ProgressionCelebrationEvent event;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final progressionL10n = ProgressionL10n(l10n);
    final cosmetics = context.watch<CosmeticsProvider>();
    final cosmeticL10n = CosmeticsL10n(l10n);
    final cosmeticDefinitions = event.cosmeticIds
        .map(cosmetics.service.catalog.byId)
        .whereType<CosmeticDefinition>()
        .toList(growable: false);
    final data = _CelebrationData.from(
      event,
      progressionL10n: progressionL10n,
      cosmeticsL10n: cosmeticL10n,
      cosmeticDefinitions: cosmeticDefinitions,
      l10n: l10n,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) => CustomPaint(
                painter: _CelebrationSparkPainter(
                  color: data.color,
                  t: animation.value,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(Tokens.spaceLg),
            decoration: BoxDecoration(
              color: ft.surface.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(Tokens.radiusCard),
              border: Border.all(color: data.color.withValues(alpha: 0.38)),
              boxShadow: [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CelebrationIcon(color: data.color, icon: data.icon),
                    const SizedBox(width: Tokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.eyebrow.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: data.color,
                              fontSize: Tokens.fontSizeMicro,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: Tokens.spaceXs),
                          Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ft.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          if (data.subtitle != null) ...[
                            const SizedBox(height: Tokens.spaceSm),
                            Text(
                              data.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ft.onSurfaceMuted,
                                fontSize: Tokens.fontSizeSmall,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: Tokens.spaceSm),
                    _CloseButton(onTap: onDismiss),
                  ],
                ),
                if (cosmeticDefinitions.isNotEmpty) ...[
                  const SizedBox(height: Tokens.spaceLg),
                  Text(
                    l10n.progQuestDetailRewards.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: data.color,
                      fontSize: Tokens.fontSizeTiny,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  _CosmeticUnlockStrip(
                    definitions: cosmeticDefinitions,
                    cosmetics: cosmetics,
                    l10n: cosmeticL10n,
                    appL10n: l10n,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationData {
  const _CelebrationData({
    required this.eyebrow,
    required this.title,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Color color;
  final IconData icon;

  factory _CelebrationData.from(
    ProgressionCelebrationEvent event, {
    required ProgressionL10n progressionL10n,
    required CosmeticsL10n cosmeticsL10n,
    required List<CosmeticDefinition> cosmeticDefinitions,
    required dynamic l10n,
  }) {
    switch (event.kind) {
      case ProgressionCelebrationKind.levelMilestone:
        final level = event.level ?? 1;
        final title = progressionL10n.levelTitle(level);
        return _CelebrationData(
          eyebrow: l10n.journeyEventTitleUnlocked,
          title: l10n.journeyLevelWithTitle(level, title),
          subtitle: l10n.progLevelAchievementDesc(level),
          color: _difficultyColor(tierForLevel(level).difficulty),
          icon: Icons.military_tech_rounded,
        );
      case ProgressionCelebrationKind.achievementUnlocked:
        final achievement = event.achievement;
        final color = achievement == null
            ? Tokens.xp
            : _difficultyColor(achievement.difficulty);
        return _CelebrationData(
          eyebrow: l10n.journeyEventAchievementUnlocked,
          title: achievement == null
              ? l10n.journeyEventAchievementUnlocked
              : progressionL10n.achievementTitle(achievement),
          subtitle: achievement == null
              ? null
              : progressionL10n.achievementDescription(achievement),
          color: color,
          icon: Icons.workspace_premium_rounded,
        );
      case ProgressionCelebrationKind.cosmeticUnlocked:
        final definition =
            cosmeticDefinitions.isEmpty ? null : cosmeticDefinitions.first;
        final palette = definition == null
            ? FtRarity.rare
            : CosmeticsPalette.forRarity(definition.rarity);
        return _CelebrationData(
          eyebrow: l10n.celebrationCosmeticUnlockedEyebrow,
          title: definition == null
              ? l10n.cosmeticUnknown
              : cosmeticsL10n.name(definition),
          subtitle: definition == null
              ? null
              : _rarityLabel(definition.rarity, l10n),
          color: palette.color,
          icon: Icons.auto_awesome_rounded,
        );
    }
  }
}

class _CelebrationIcon extends StatelessWidget {
  const _CelebrationIcon({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(Tokens.radiusIcon),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Icon(
          Icons.close_rounded,
          color: ft.onSurfaceMuted,
          size: 18,
        ),
      ),
    );
  }
}

class _CosmeticUnlockStrip extends StatelessWidget {
  const _CosmeticUnlockStrip({
    required this.definitions,
    required this.cosmetics,
    required this.l10n,
    required this.appL10n,
  });

  final List<CosmeticDefinition> definitions;
  final CosmeticsProvider cosmetics;
  final CosmeticsL10n l10n;
  final dynamic appL10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Tokens.spaceSm,
      runSpacing: Tokens.spaceSm,
      children: [
        for (final definition in definitions)
          _CosmeticUnlockChip(
            definition: definition,
            assetPath: cosmetics.service.config.resolveAssetPath(
              definition.previewAssetKey ?? definition.assetKey,
            ),
            name: l10n.name(definition),
            appL10n: appL10n,
          ),
      ],
    );
  }
}

class _CosmeticUnlockChip extends StatelessWidget {
  const _CosmeticUnlockChip({
    required this.definition,
    required this.assetPath,
    required this.name,
    required this.appL10n,
  });

  final CosmeticDefinition definition;
  final String? assetPath;
  final String name;
  final dynamic appL10n;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final palette = CosmeticsPalette.forRarity(definition.rarity);
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.all(Tokens.spaceSm),
      decoration: BoxDecoration(
        color: palette.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: palette.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CosmeticPreview(
            definition: definition,
            assetPath: assetPath,
            color: palette.color,
          ),
          const SizedBox(width: Tokens.spaceSm),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ft.onSurface,
                    fontSize: Tokens.fontSizeSmall,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _rarityLabel(definition.rarity, appL10n).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.color,
                    fontSize: Tokens.fontSizeTiny,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CosmeticPreview extends StatelessWidget {
  const _CosmeticPreview({
    required this.definition,
    required this.assetPath,
    required this.color,
  });

  final CosmeticDefinition definition;
  final String? assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Tokens.radiusIcon),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      clipBehavior: Clip.antiAlias,
      child: assetPath == null
          ? _CosmeticFallback(type: definition.type, color: color)
          : Image.asset(
              assetPath!,
              fit: definition.type == CosmeticType.frame
                  ? BoxFit.contain
                  : BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _CosmeticFallback(type: definition.type, color: color),
            ),
    );
  }
}

class _CosmeticFallback extends StatelessWidget {
  const _CosmeticFallback({
    required this.type,
    required this.color,
  });

  final CosmeticType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(_iconForType(type), color: color, size: 20);
  }
}

class _CelebrationSparkPainter extends CustomPainter {
  const _CelebrationSparkPainter({
    required this.color,
    required this.t,
  });

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final alpha = ((1 - t).clamp(0.0, 1.0) * 0.65).toDouble();
    final paint = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: alpha);
    for (var i = 0; i < 18; i++) {
      final angle = (math.pi * 2 / 18) * i;
      final startRadius = 26 + (t * 18);
      final endRadius = 54 + (t * 44);
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * startRadius;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * endRadius;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_CelebrationSparkPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

Color _difficultyColor(ProgressionAchievementDifficulty difficulty) {
  switch (difficulty) {
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

String _rarityLabel(CosmeticRarity rarity, dynamic l10n) {
  switch (rarity) {
    case CosmeticRarity.common:
      return l10n.cosmeticRarityCommon;
    case CosmeticRarity.rare:
      return l10n.cosmeticRarityRare;
    case CosmeticRarity.epic:
      return l10n.cosmeticRarityEpic;
    case CosmeticRarity.legendary:
      return l10n.cosmeticRarityLegendary;
  }
}

IconData _iconForType(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return Icons.crop_square_rounded;
    case CosmeticType.relic:
      return Icons.auto_awesome_rounded;
    case CosmeticType.background:
      return Icons.landscape_rounded;
    case CosmeticType.emblem:
      return Icons.shield_rounded;
    case CosmeticType.companion:
      return Icons.pets_rounded;
    case CosmeticType.titleFlair:
      return Icons.title_rounded;
    case CosmeticType.mapEffect:
      return Icons.map_rounded;
  }
}

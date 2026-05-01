import 'package:flutter/material.dart';

import '../../../shared/theme/design_tokens.dart';
import '../domain/cosmetic_models.dart';

// ── Shared badge widget ───────────────────────────────────────────────────────

class CosmeticBadge extends StatelessWidget {
  const CosmeticBadge({
    super.key,
    required this.definition,
    required this.assetPath,
    required this.color,
    this.size = 42,
  });

  final CosmeticDefinition definition;
  final String? assetPath;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isFrame = definition.type == CosmeticType.frame;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isFrame ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: color.withValues(alpha: isFrame ? 0.52 : 0.32),
          width: isFrame ? 1.8 : 1,
        ),
      ),
      clipBehavior: isFrame ? Clip.none : Clip.antiAlias,
      child: assetPath == null
          ? CosmeticBadgeFallback(type: definition.type, color: color, size: size)
          : Image.asset(
              assetPath!,
              fit: isFrame ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (_, __, ___) => CosmeticBadgeFallback(
                type: definition.type,
                color: color,
                size: size,
              ),
            ),
    );
  }
}

class CosmeticBadgeFallback extends StatelessWidget {
  const CosmeticBadgeFallback({
    super.key,
    required this.type,
    required this.color,
    required this.size,
  });

  final CosmeticType type;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          cosmeticIconForType(type),
          color: Colors.white.withValues(alpha: 0.9),
          size: size * 0.52,
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

IconData cosmeticIconForType(CosmeticType type) {
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

String cosmeticTypeLabel(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return 'Rámeček';
    case CosmeticType.relic:
      return 'Relikvie';
    case CosmeticType.background:
      return 'Pozadí';
    case CosmeticType.emblem:
      return 'Znak';
    case CosmeticType.companion:
      return 'Společník';
    case CosmeticType.titleFlair:
      return 'Titul';
    case CosmeticType.mapEffect:
      return 'Efekt mapy';
  }
}

String cosmeticRarityLabel(CosmeticRarity rarity) {
  switch (rarity) {
    case CosmeticRarity.common:
      return 'Běžné';
    case CosmeticRarity.rare:
      return 'Vzácné';
    case CosmeticRarity.epic:
      return 'Epické';
    case CosmeticRarity.legendary:
      return 'Legendární';
  }
}

Color cosmeticRarityColor(CosmeticRarity rarity) {
  switch (rarity) {
    case CosmeticRarity.common:
      return Tokens.difficultyEasy;
    case CosmeticRarity.rare:
      return Tokens.difficultyMedium;
    case CosmeticRarity.epic:
      return Tokens.difficultyHard;
    case CosmeticRarity.legendary:
      return Tokens.difficultyExtraHard;
  }
}

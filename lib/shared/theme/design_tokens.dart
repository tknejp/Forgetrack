import 'package:flutter/material.dart';

@immutable
class ThemeTokens extends ThemeExtension<ThemeTokens> {
  final Color bg;
  final Color surface;
  final Color surfaceSubtle;
  final Color cardBorder;
  final Color divider;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceFaint;
  final Color accent;
  final Color accentGlow;
  final Color secondary;
  final Color tertiary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color xp;
  final Color xpGlow;
  final Domain steps;
  final Domain calories;
  final Domain weight;
  final Domain sleep;
  final Domain active;
  final Domain protein;
  final Domain fat;
  final Domain carbs;

  const ThemeTokens({
    required this.bg,
    required this.surface,
    required this.surfaceSubtle,
    required this.cardBorder,
    required this.divider,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceFaint,
    required this.accent,
    required this.accentGlow,
    required this.secondary,
    required this.tertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.xp,
    required this.xpGlow,
    required this.steps,
    required this.calories,
    required this.weight,
    required this.sleep,
    required this.active,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  static const dark = ThemeTokens(
    bg: Color(0xFF0D0F1C),
    surface: Color(0xFF111422),
    surfaceSubtle: Color(0x08FFFFFF),
    cardBorder: Color(0x14FFFFFF),
    divider: Color(0x0FFFFFFF),
    onSurface: Color(0xF2FFFFFF),
    onSurfaceMuted: Color(0x66FFFFFF),
    onSurfaceFaint: Color(0x3DFFFFFF),
    accent: Color(0xFF7C6FFF),
    accentGlow: Color(0x597C6FFF),
    secondary: Color(0xFF5A86F0),
    tertiary: Color(0xFFF2A35A),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    xp: Color(0xFFFFBD2E),
    xpGlow: Color(0x55FFBD2E),
    steps: Tokens.steps,
    calories: Tokens.calories,
    weight: Tokens.weight,
    sleep: Tokens.sleep,
    active: Tokens.active,
    protein: Tokens.protein,
    fat: Tokens.fat,
    carbs: Tokens.carbs,
  );

  @override
  ThemeTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSubtle,
    Color? cardBorder,
    Color? divider,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? onSurfaceFaint,
    Color? accent,
    Color? accentGlow,
    Color? secondary,
    Color? tertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? xp,
    Color? xpGlow,
    Domain? steps,
    Domain? calories,
    Domain? weight,
    Domain? sleep,
    Domain? active,
    Domain? protein,
    Domain? fat,
    Domain? carbs,
  }) {
    return ThemeTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      onSurfaceFaint: onSurfaceFaint ?? this.onSurfaceFaint,
      accent: accent ?? this.accent,
      accentGlow: accentGlow ?? this.accentGlow,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      xp: xp ?? this.xp,
      xpGlow: xpGlow ?? this.xpGlow,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      weight: weight ?? this.weight,
      sleep: sleep ?? this.sleep,
      active: active ?? this.active,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
    );
  }

  @override
  ThemeTokens lerp(ThemeExtension<ThemeTokens>? other, double t) {
    if (other is! ThemeTokens) return this;
    return ThemeTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      onSurfaceFaint: Color.lerp(onSurfaceFaint, other.onSurfaceFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      xp: Color.lerp(xp, other.xp, t)!,
      xpGlow: Color.lerp(xpGlow, other.xpGlow, t)!,
      steps: steps.lerp(other.steps, t),
      calories: calories.lerp(other.calories, t),
      weight: weight.lerp(other.weight, t),
      sleep: sleep.lerp(other.sleep, t),
      active: active.lerp(other.active, t),
      protein: protein.lerp(other.protein, t),
      fat: fat.lerp(other.fat, t),
      carbs: carbs.lerp(other.carbs, t),
    );
  }
}

extension FtThemeContextX on BuildContext {
  ThemeTokens get ft =>
      Theme.of(this).extension<ThemeTokens>() ?? ThemeTokens.dark;
}

/// RPG dark-fantasy design tokens — single source of truth for the Forgetrack UI.
/// All values derived from the Forgetrack Handoff v1 design bundle.
abstract final class Tokens {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0D0F1C);
  static const Color surface = Color(0xFF111422);
  static const Color cardBorder = Color(0x14FFFFFF); // 8% white
  static const Color divider = Color(0x0FFFFFFF); // 6% white

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xF2FFFFFF); // 95%
  static const Color onSurfaceMuted = Color(0x66FFFFFF); // 40%
  static const Color onSurfaceFaint = Color(0x3DFFFFFF); // 24%

  // ── App accent (violet) ───────────────────────────────────────────────────
  static const Color accent = Color(0xFF7C6FFF);
  static const Color accentGlow = Color(0x597C6FFF); // 35%

  // ── Semantic state ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  // ── XP / progression ──────────────────────────────────────────────────────
  static const Color xp = Color(0xFFFFBD2E);
  static const Color xpGlow = Color(0x55FFBD2E);

  // ── Achievement difficulty ────────────────────────────────────────────────
  static const Color difficultyEasy = Color(0xFF34D399);
  static const Color difficultyMedium = Color(0xFF60A5FA);
  static const Color difficultyHard = Color(0xFFA78BFA);
  static const Color difficultyExtraHard = Color(0xFFFBBF24);
  static const Color difficultyMythic = Color(0xFF7A0010);

  // ── Domain tokens ─────────────────────────────────────────────────────────
  static const Domain steps = Domain(
    color: Color(0xFF34D399),
    dim: Color(0x2E34D399),
    glow: Color(0x4034D399),
    gradStart: Color(0x3834D399),
    gradEnd: Color(0x1410B981),
  );
  static const Domain calories = Domain(
    color: Color(0xFFFF8A1F),
    dim: Color(0x2EFF8A1F),
    glow: Color(0x40FF8A1F),
    gradStart: Color(0x38FF8A1F),
    gradEnd: Color(0x0FEA580C),
  );
  static const Domain weight = Domain(
    color: Color(0xFF60A5FA),
    dim: Color(0x2E60A5FA),
    glow: Color(0x4060A5FA),
    gradStart: Color(0x3860A5FA),
    gradEnd: Color(0x0F3B82F6),
  );
  static const Domain sleep = Domain(
    color: Color(0xFFA89BFF),
    dim: Color(0x2EA89BFF),
    glow: Color(0x40A89BFF),
    gradStart: Color(0x38A89BFF),
    gradEnd: Color(0x0F7C6FFF),
  );
  static const Domain active = Domain(
    color: Color(0xFF2DD4BF),
    dim: Color(0x2E2DD4BF),
    glow: Color(0x402DD4BF),
    gradStart: Color(0x382DD4BF),
    gradEnd: Color(0x0F14B8A6),
  );
  static const Domain protein = Domain(
    color: Color(0xFF60A5FA),
    dim: Color(0x2E60A5FA),
    glow: Color(0x4060A5FA),
    gradStart: Color(0x2E60A5FA),
    gradEnd: Color(0x0D3B82F6),
  );
  static const Domain fat = Domain(
    color: Color(0xFFFBBF24),
    dim: Color(0x2EFBBF24),
    glow: Color(0x40FBBF24),
    gradStart: Color(0x2EFBBF24),
    gradEnd: Color(0x0DF59B0B),
  );
  static const Domain carbs = Domain(
    color: Color(0xFFF472B6),
    dim: Color(0x2EF472B6),
    glow: Color(0x40F472B6),
    gradStart: Color(0x2EF472B6),
    gradEnd: Color(0x0DEC4899),
  );

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double space2xl = 24.0;
  static const double space3xl = 32.0;

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double radiusCard = 18.0;
  static const double radiusInner = 12.0;
  static const double radiusTile = 14.0;
  static const double radiusButton = 16.0;
  static const double radiusIcon = 10.0;
  static const double radiusProgress = 99.0;

  // ── Font sizes ─────────────────────────────────────────────────────────────
  static const double fontSizeTitle = 20.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeCaption = 11.0;
  static const double fontSizeMicro = 10.0;
  static const double fontSizeTiny = 9.0;

  // ── Glow blur radii ───────────────────────────────────────────────────────
  static const double glowSm = 8.0; // progress fills, tight accents
  static const double glowMd = 12.0; // tab pills, small containers
  static const double glowLg = 16.0; // cards, section headers
  static const double glowXl = 22.0; // hero / prominent elements

  // Quest cards
  static const double questCardRadius = radiusTile;
  static const double questCardPadding = 12.0;
  static const double questCardGap = spaceSm;
  static const double questAssetCollapsed = 64.0;
  static const double questAssetExpanded = 76.0;
  static const double questAssetCompleted = 46.0;
  static const double questChainNodeHeight = 22.0;
  static const double questChainNodeMinWidth = 24.0;
  static const double questChainConnectorWidth = 10.0;
  static const double questProgressHeight = 8.0;
  static const double questXpPillHorizontal = 8.0;
  static const double questXpPillVertical = 4.0;
}

@immutable
class Domain {
  final Color color;
  final Color dim;
  final Color glow;
  final Color gradStart;
  final Color gradEnd;

  const Domain({
    required this.color,
    required this.dim,
    required this.glow,
    required this.gradStart,
    required this.gradEnd,
  });

  Domain copyWith({
    Color? color,
    Color? dim,
    Color? glow,
    Color? gradStart,
    Color? gradEnd,
  }) {
    return Domain(
      color: color ?? this.color,
      dim: dim ?? this.dim,
      glow: glow ?? this.glow,
      gradStart: gradStart ?? this.gradStart,
      gradEnd: gradEnd ?? this.gradEnd,
    );
  }

  Domain lerp(Domain other, double t) {
    return Domain(
      color: Color.lerp(color, other.color, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      gradStart: Color.lerp(gradStart, other.gradStart, t)!,
      gradEnd: Color.lerp(gradEnd, other.gradEnd, t)!,
    );
  }

  LinearGradient get gradient => LinearGradient(
        begin: const Alignment(-1, -1),
        end: const Alignment(1, 1),
        colors: [gradStart, gradEnd],
      );

  BoxDecoration cardDecoration({double radius = Tokens.radiusCard}) =>
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: dim),
      );
}

/// Visual palette for a cosmetic rarity tier — color (bright end of gradient)
/// and gradStart (darker start). Defined here so widgets outside the cosmetics
/// feature can reference rarity colors without importing cosmetics internals.
@immutable
class Rarity {
  final Color color;
  final Color gradStart;

  const Rarity({required this.color, required this.gradStart});

  static const common = Rarity(
    color: Color(0xFF9E9E9E),
    gradStart: Color(0xFF6E6E6E),
  );
  static const uncommon = Rarity(
    color: Color(0xFF34D399),
    gradStart: Color(0xFF10B981),
  );
  static const rare = Rarity(
    color: Color(0xFF58A6FF),
    gradStart: Color(0xFF1F6FEB),
  );
  static const epic = Rarity(
    color: Color(0xFFB388FF),
    gradStart: Color(0xFF7B3FE4),
  );
  static const legendary = Rarity(
    color: Color(0xFFFFD54F),
    gradStart: Color(0xFFE0A800),
  );
  static const mythic = Rarity(
    color: Color(0xFFFF4B3A),
    gradStart: Color(0xFF7A0010),
  );
}

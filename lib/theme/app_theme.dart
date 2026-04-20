import 'dart:ui';

import 'package:flutter/material.dart';

import 'palettes.dart';
import 'time_theme.dart';

@immutable
class SectionColors {
  final Color accent;
  final Color muted;

  const SectionColors({
    required this.accent,
    required this.muted,
  });
}

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final SectionColors steps;
  final SectionColors nutrition;
  final SectionColors sleep;
  final SectionColors body;
  final double cardRadius;
  final double tileRadius;
  final Color cardBorder;
  final Color subtleShadow;

  const AppThemeTokens({
    required this.steps,
    required this.nutrition,
    required this.sleep,
    required this.body,
    required this.cardRadius,
    required this.tileRadius,
    required this.cardBorder,
    required this.subtleShadow,
  });

  @override
  AppThemeTokens copyWith({
    SectionColors? steps,
    SectionColors? nutrition,
    SectionColors? sleep,
    SectionColors? body,
    double? cardRadius,
    double? tileRadius,
    Color? cardBorder,
    Color? subtleShadow,
  }) {
    return AppThemeTokens(
      steps: steps ?? this.steps,
      nutrition: nutrition ?? this.nutrition,
      sleep: sleep ?? this.sleep,
      body: body ?? this.body,
      cardRadius: cardRadius ?? this.cardRadius,
      tileRadius: tileRadius ?? this.tileRadius,
      cardBorder: cardBorder ?? this.cardBorder,
      subtleShadow: subtleShadow ?? this.subtleShadow,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      steps: SectionColors(
        accent: Color.lerp(steps.accent, other.steps.accent, t)!,
        muted: Color.lerp(steps.muted, other.steps.muted, t)!,
      ),
      nutrition: SectionColors(
        accent: Color.lerp(nutrition.accent, other.nutrition.accent, t)!,
        muted: Color.lerp(nutrition.muted, other.nutrition.muted, t)!,
      ),
      sleep: SectionColors(
        accent: Color.lerp(sleep.accent, other.sleep.accent, t)!,
        muted: Color.lerp(sleep.muted, other.sleep.muted, t)!,
      ),
      body: SectionColors(
        accent: Color.lerp(body.accent, other.body.accent, t)!,
        muted: Color.lerp(body.muted, other.body.muted, t)!,
      ),
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      tileRadius: lerpDouble(tileRadius, other.tileRadius, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtleShadow: Color.lerp(subtleShadow, other.subtleShadow, t)!,
    );
  }
}

extension AppThemeContextX on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

class AppTheme {
  AppTheme._();

  static const AppPalette _palette = AppPalette.calmFit;

  // Static neutral surface bases — used to derive the per-segment tint delta.
  static const _kLightSurface = Color(0xFFF7F9FB); // R247 G249 B251
  static const _kDarkSurface  = Color(0xFF151A21); // R21  G26  B33

  /// Returns the light [ThemeData].
  ///
  /// Pass a [TimePalette] from [TimeThemeProvider] to apply subtle time-of-day
  /// accent and surface tints.  Omit (or pass null) for the static default.
  static ThemeData light([TimePalette? timePalette]) =>
      _buildTheme(Brightness.light, timePalette);

  /// Returns the dark [ThemeData].  Same [timePalette] semantics as [light].
  static ThemeData dark([TimePalette? timePalette]) =>
      _buildTheme(Brightness.dark, timePalette);

  static NavigationBarThemeData _navBarTheme(Color indicator, Color accent) {
    return NavigationBarThemeData(
      indicatorColor: indicator,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontWeight: FontWeight.w700, fontSize: 12);
        }
        return const TextStyle(fontWeight: FontWeight.w500, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: accent, size: 24);
        }
        return const IconThemeData(size: 24);
      }),
    );
  }

  static ThemeData _buildTheme(Brightness brightness, [TimePalette? timePalette]) {
    final isDark = brightness == Brightness.dark;

    // ── Effective accent ────────────────────────────────────────────────────
    final accent = timePalette?.accent ?? _palette.accent;

    // ── Surface tinting ─────────────────────────────────────────────────────
    // Compute the ΔR/ΔG/ΔB offset of the time palette surface from the neutral
    // base, then apply that same delta to every hardcoded surface-family colour
    // so all container tiers shift together while preserving their hierarchy.
    final Color timeSurface = isDark
        ? (timePalette?.darkSurface  ?? _kDarkSurface)
        : (timePalette?.lightSurface ?? _kLightSurface);
    final Color staticBase = isDark ? _kDarkSurface : _kLightSurface;

    int toByte(Color c, double channel) => (channel * 255.0).round();
    final int dr = toByte(timeSurface, timeSurface.r) - toByte(staticBase, staticBase.r);
    final int dg = toByte(timeSurface, timeSurface.g) - toByte(staticBase, staticBase.g);
    final int db = toByte(timeSurface, timeSurface.b) - toByte(staticBase, staticBase.b);

    // Apply the tint delta, clamping to valid byte range.
    Color tint(Color c) => Color.fromARGB(
      255,
      (toByte(c, c.r) + dr).clamp(0, 255),
      (toByte(c, c.g) + dg).clamp(0, 255),
      (toByte(c, c.b) + db).clamp(0, 255),
    );

    // ── ColorScheme ─────────────────────────────────────────────────────────
    // Keep seedColor stable so secondary/tertiary hues don't drift; only
    // override primary and surface-family colours with the time palette values.
    final cs = ColorScheme.fromSeed(
      seedColor: _palette.accent,
      secondary: _palette.secondary,
      tertiary: _palette.tertiary,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      secondary: _palette.secondary,
      tertiary: _palette.tertiary,
      // Surface family — tinted from the segment's surface base.
      surface: tint(isDark ? _kDarkSurface  : _kLightSurface),
      surfaceContainerLowest: tint(
        isDark ? const Color(0xFF10151C) : const Color(0xFFFFFFFF),
      ),
      surfaceContainerLow: tint(
        isDark ? const Color(0xFF171E27) : const Color(0xFFF3F6F8),
      ),
      surfaceContainer: tint(
        isDark ? const Color(0xFF1C2430) : const Color(0xFFEEF3F6),
      ),
      surfaceContainerHigh: tint(
        isDark ? const Color(0xFF222C39) : const Color(0xFFE6EDF2),
      ),
      surfaceContainerHighest: tint(
        isDark ? const Color(0xFF2A3645) : const Color(0xFFDCE6ED),
      ),
      outline: tint(
        isDark ? const Color(0xFF334252) : const Color(0xFFD6E0E7),
      ),
      outlineVariant: tint(
        isDark ? const Color(0xFF283341) : const Color(0xFFE5EDF2),
      ),
      // Nav indicator inherits the active accent.
      secondaryContainer: accent.withValues(alpha: isDark ? 0.20 : 0.10),
      onSecondaryContainer: accent,
    );

    final textTheme = (isDark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .copyWith(
          titleLarge: (isDark
                  ? Typography.material2021().white.titleLarge
                  : Typography.material2021().black.titleLarge)
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: (isDark
                  ? Typography.material2021().white.titleMedium
                  : Typography.material2021().black.titleMedium)
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1),
          bodyMedium: (isDark
                  ? Typography.material2021().white.bodyMedium
                  : Typography.material2021().black.bodyMedium)
              ?.copyWith(height: 1.25),
          bodySmall: (isDark
                  ? Typography.material2021().white.bodySmall
                  : Typography.material2021().black.bodySmall)
              ?.copyWith(height: 1.2),
          labelLarge: (isDark
                  ? Typography.material2021().white.labelLarge
                  : Typography.material2021().black.labelLarge)
              ?.copyWith(fontWeight: FontWeight.w700),
        )
        .apply(
          bodyColor: cs.onSurface,
          displayColor: cs.onSurface,
        );

    // Section colours (steps/nutrition/sleep/body) are intentionally NOT
    // time-shifted — they carry semantic meaning and must stay recognisable.
    final tokens = AppThemeTokens(
      steps: SectionColors(
        accent: _palette.steps.accent,
        muted: _palette.steps.accentMuted,
      ),
      nutrition: SectionColors(
        accent: _palette.nutrition.accent,
        muted: _palette.nutrition.accentMuted,
      ),
      sleep: SectionColors(
        accent: _palette.sleep.accent,
        muted: _palette.sleep.accentMuted,
      ),
      body: SectionColors(
        accent: _palette.body.accent,
        muted: _palette.body.accentMuted,
      ),
      cardRadius: 20,
      tileRadius: 14,
      cardBorder: cs.outlineVariant,
      subtleShadow: isDark ? Colors.black : const Color(0xFF506070),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: textTheme,
      scaffoldBackgroundColor: cs.surfaceContainerLowest,
      extensions: [tokens],
      navigationBarTheme: _navBarTheme(
        cs.secondaryContainer,
        accent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: cs.surfaceContainerLowest,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: cs.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 44)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return cs.surfaceContainerHigh.withValues(alpha: isDark ? 0.38 : 0.55);
            }
            if (states.contains(WidgetState.selected)) {
              return accent.withValues(alpha: isDark ? 0.24 : 0.14);
            }
            return cs.surfaceContainerHigh.withValues(alpha: isDark ? 0.9 : 0.96);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return cs.onSurface.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.selected)) {
              return accent;
            }
            return cs.onSurface;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accent.withValues(alpha: isDark ? 0.18 : 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return accent.withValues(alpha: isDark ? 0.12 : 0.08);
            }
            return null;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(
                color: accent.withValues(alpha: isDark ? 0.5 : 0.3),
              );
            }
            return BorderSide(color: cs.outlineVariant);
          }),
          textStyle: WidgetStateProperty.resolveWith((states) {
            final base = textTheme.labelLarge;
            if (states.contains(WidgetState.selected)) {
              return base?.copyWith(fontWeight: FontWeight.w800);
            }
            return base;
          }),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'palettes.dart';

/// Forgetrack — barevný systém
///
/// ════════════════════════════════════════════════════════
/// PALETA
/// ════════════════════════════════════════════════════════
///
/// _palette.accent  — jediný brand akcent (viz AppPalette)
///   • VŠECHNY interaktivní/aktivní prvky: tlačítka, FABs,
///     progress bary, aktivní nav ikona + label, indikátor
///   • Data s energetickým významem: kalorie, spalování,
///     kroky (aktivní den v grafu)
///   • Highlight texty hodnot
///
/// cs.tertiary  — komplementární barva (generovaná ze seed)
///   • Vzdálenost (km), sekundární metriky
///   • Doplněk k akcentu bez kolize
///
/// cs.onSurfaceVariant  — tlumená/neaktivní barva
///   • Neaktivní nav ikony + labely
///   • Placeholder texty, empty-state texty
///
/// cs.error  — výhradně pro CHYBOVÉ STAVY
///   • Selhání syncu, chyba oprávnění
///   • Přesažení kalorického cíle (varování)
///   • Ikona chyby v _SyncResultBanner
///
/// Povrchy: fromSeed(accent) generuje tónované povrchy
///   • scaffoldBackgroundColor = surfaceContainerLowest (nejsvětlejší)
///   • Card default        = surfaceContainerLow (o stupeň teplejší)
///   → přirozený kontrast karta vs. pozadí bez ruční hardcoded barvy
///
/// AppBar: surfaceTintColor transparent → plochý, čistý AppBar
/// ════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Aktivní paleta ───────────────────────────────────────
  // Změň zde pro přepnutí celého barevného schématu aplikace.
  static const AppPalette _palette = AppPalette.orangeEnergy; // ← change here

  // ── NavigationBar theme factory ─────────────────────────
  /// Explicitní state-aware ikony a labely pro NavigationBar.
  /// Aktivní  → [_palette.accent].
  /// Neaktivní → null (M3 aplikuje onSurfaceVariant z colorScheme).
  static NavigationBarThemeData _navBarTheme(Color indicator) =>
      NavigationBarThemeData(
        indicatorColor: indicator,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          if (states.contains(WidgetState.selected)) {
            // const není možné: Dart neumožňuje property access na instance
            // v const výrazu (const_eval_property_access).
            return IconThemeData(color: _palette.accent, size: 24);
          }
          return null; // → M3 default = onSurfaceVariant
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: _palette.accent,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return null; // → M3 default = onSurfaceVariant
        }),
      );

  // ── Light theme ──────────────────────────────────────────
  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: _palette.accent, // celé tónové schéma odvozeno z akcentu
      brightness: Brightness.light,
    ).copyWith(
      primary: _palette.accent,   // buttons, FABs, progress, aktivní elementy
      onPrimary: Colors.white,    // bílý text/ikona na akcentovém povrchu

      secondary: _palette.accent, // konzistence: secondary = primary
      onSecondary: Colors.white,

      // NavigationBar: indicator pill, selected icon color
      secondaryContainer: _palette.navIndicatorLight,
      onSecondaryContainer: _palette.accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,

      // Bez globálního iconTheme: ikony bez explicitní barvy použijí
      // onSurface (tmavá) — to je správné výchozí chování.
      // Akcent se nastaví explicitně přes color: cs.primary v widgetech.

      navigationBarTheme: _navBarTheme(_palette.navIndicatorLight),

      // Povrchová hierarchie pro kontrast karta vs. pozadí:
      //   surfaceContainerLowest ≈ světlá bílá  → scaffold
      //   surfaceContainerLow    ≈ o stupeň teplejší → card (M3 default)
      scaffoldBackgroundColor: cs.surfaceContainerLowest,

      cardTheme: const CardThemeData(
        elevation: 2, // stín vizuálně oddělí karty od pozadí
        margin: EdgeInsets.zero,
        // color: null → M3 Card použije surfaceContainerLow automaticky
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: cs.surfaceContainerLowest,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent, // plochý AppBar, bez barevného tintu
      ),
    );
  }

  // ── Dark theme ───────────────────────────────────────────
  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: _palette.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _palette.accent,
      onPrimary: Colors.white,

      secondary: _palette.accent,
      onSecondary: Colors.white,

      secondaryContainer: _palette.navIndicatorDark,
      onSecondaryContainer: _palette.accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,

      navigationBarTheme: _navBarTheme(_palette.navIndicatorDark),
      scaffoldBackgroundColor: cs.surfaceContainerLowest,

      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: cs.surfaceContainerLowest,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

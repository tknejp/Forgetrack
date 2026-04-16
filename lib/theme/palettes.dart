import 'package:flutter/material.dart';

/// Sada předdefinovaných palet pro Forgetrack.
///
/// Každá paleta definuje:
///   • [accent]             — primární brand barva (buttons, FABs, aktivní stav)
///   • [navIndicatorLight]  — NavBar indikátor v light modu
///   • [navIndicatorDark]   — NavBar indikátor v dark modu
///   • [name]               — Lidsky čitelný název (pro debug / výběr palety v UI)
///
/// Aktivní paleta se nastavuje jedním řádkem v [AppTheme]:
///   ```dart
///   static const AppPalette _palette = AppPalette.tealHealth; // ← change here
///   ```
class AppPalette {
  final Color accent;
  final Color navIndicatorLight;
  final Color navIndicatorDark;
  final String name;

  const AppPalette({
    required this.accent,
    required this.navIndicatorLight,
    required this.navIndicatorDark,
    required this.name,
  });

  // ── Dostupné palety ─────────────────────────────────────────

  /// Medicínská teal — klid, zdraví, příroda.
  static const tealHealth = AppPalette(
    name: 'Teal Health',
    accent: Color(0xFF00796B),
    navIndicatorLight: Color(0x2800796B), // 16% accent — jemný pill
    navIndicatorDark: Color(0x4000796B),  // 25% accent — tmavý mod potřebuje více
  );

  /// Datová modrá — analýza, přesnost, technika.
  static const dataBlue = AppPalette(
    name: 'Data Blue',
    accent: Color(0xFF1565C0),
    navIndicatorLight: Color(0x281565C0),
    navIndicatorDark: Color(0x401565C0),
  );

  /// Energetická oranžová — pohyb, kalorie, spalování.
  static const orangeEnergy = AppPalette(
    name: 'Orange Energy',
    accent: Color(0xFFFF6D00),
    navIndicatorLight: Color(0x28FF6D00),
    navIndicatorDark: Color(0x40FF6D00),
  );

  /// Vitální zelená — příroda, rovnováha, regenerace.
  static const vitalGreen = AppPalette(
    name: 'Vital Green',
    accent: Color(0xFF2E7D32),
    navIndicatorLight: Color(0x282E7D32),
    navIndicatorDark: Color(0x402E7D32),
  );

  /// Indigo focus — soustředění, meditace, mentální výkon.
  static const indigoFocus = AppPalette(
    name: 'Indigo Focus',
    accent: Color(0xFF283593),
    navIndicatorLight: Color(0x28283593),
    navIndicatorDark: Color(0x40283593),
  );

  /// Slate Pro — neutrální, profesionální, minimalistické.
  static const slatePro = AppPalette(
    name: 'Slate Pro',
    accent: Color(0xFF37474F),
    navIndicatorLight: Color(0x2837474F),
    navIndicatorDark: Color(0x4037474F),
  );
}
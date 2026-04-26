import 'package:flutter/material.dart';

@immutable
class AppSectionPalette {
  final Color accent;
  final Color accentMuted;

  const AppSectionPalette({
    required this.accent,
    required this.accentMuted,
  });
}

class AppPalette {
  final String name;
  final Color accent;
  final Color secondary;
  final Color tertiary;
  final Color navIndicatorLight;
  final Color navIndicatorDark;
  final AppSectionPalette steps;
  final AppSectionPalette nutrition;
  final AppSectionPalette sleep;
  final AppSectionPalette body;

  const AppPalette({
    required this.name,
    required this.accent,
    required this.secondary,
    required this.tertiary,
    required this.navIndicatorLight,
    required this.navIndicatorDark,
    required this.steps,
    required this.nutrition,
    required this.sleep,
    required this.body,
  });

  static const calmFit = AppPalette(
    name: 'Calm Fit',
    // Global accent (recommended premium blue)
    accent: Color(0xFF4A90E2),
    // Secondary accent
    secondary: Color(0xFF5A86F0),
    // Warm tertiary / highlights
    tertiary: Color(0xFFF2A35A),
    // Navbar selected indicator
    navIndicatorLight: Color(0x1A4A90E2),
    navIndicatorDark: Color(0x334A90E2),

    steps: AppSectionPalette(
      accent: Color(0xFF3E9B61),
      accentMuted: Color(0xFFB8E0C3),
    ),

    nutrition: AppSectionPalette(
      accent: Color(0xFFE88B3D),
      accentMuted: Color(0xFFF3D2B3),
    ),

    sleep: AppSectionPalette(
      accent: Color(0xFF7C72D8),
      accentMuted: Color(0xFFD7D2F5),
    ),

    body: AppSectionPalette(
      accent: Color(0xFF5A8AD8),
      accentMuted: Color(0xFFCFE0FA),
    ),
  );
}

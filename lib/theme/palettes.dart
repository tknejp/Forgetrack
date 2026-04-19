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
    accent: Color(0xFF2E8B7F),
    secondary: Color(0xFF5C8FD6),
    tertiary: Color(0xFFF29A4A),
    navIndicatorLight: Color(0x1A2E8B7F),
    navIndicatorDark: Color(0x332E8B7F),
    steps: AppSectionPalette(
      accent: Color(0xFF3E9B61),
      accentMuted: Color(0xFFB8E0C3),
    ),
    nutrition: AppSectionPalette(
      accent: Color(0xFFE78A3C),
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

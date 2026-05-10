import 'package:flutter/material.dart';

/// Design tokens lifted verbatim from the welcome onboarding handoff
/// (`design/design_handoff_welcome_onboarding_v1`). Centralised so each
/// step widget can reference them without re-deriving the palette.
abstract final class OnboardingTheme {
  // ── Background ────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0B0F1E);

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F3FF);
  static Color textSecondary = const Color(0xFFF5F3FF).withValues(alpha: 0.55);
  static Color textMuted = const Color(0xFFF5F3FF).withValues(alpha: 0.40);
  static Color textCaption = const Color(0xFFF5F3FF).withValues(alpha: 0.45);

  // ── Purple palette ────────────────────────────────────────────────
  static const Color purplePrimary = Color(0xFF8B5CF6);
  static const Color purpleDeep = Color(0xFF7C3AED);
  static const Color purpleAccent = Color(0xFFA78BFA);
  static const Color purpleLight = Color(0xFFC4B5FD);

  // ── Accents ───────────────────────────────────────────────────────
  static const Color gold = Color(0xFFF4C152);
  static const Color teal = Color(0xFF3FB8AF);
  static const Color green = Color(0xFF34D399);

  // KT brand greens
  static const Color ktGreen = Color(0xFF8FBE3D);
  static const Color ktGreenDeep = Color(0xFF6E9527);
  static const Color ktTint = Color(0xFF7BA42B);

  // ── Surfaces ──────────────────────────────────────────────────────
  static Color surfaceCard = const Color.fromRGBO(28, 30, 56, 0.45);
  static Color borderSoft = const Color.fromRGBO(148, 130, 220, 0.18);
  static Color borderMid = const Color.fromRGBO(167, 139, 250, 0.22);

  // ── Step1 hero card gradient stops ────────────────────────────────
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(40, 38, 76, 0.55),
      Color.fromRGBO(22, 22, 46, 0.85),
    ],
  );

  // ── Quests preview card gradient ──────────────────────────────────
  static const LinearGradient questsCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(244, 193, 82, 0.12),
      Color.fromRGBO(167, 139, 250, 0.10),
    ],
  );

  // ── Primary CTA gradient ──────────────────────────────────────────
  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [purplePrimary, purpleDeep],
  );

  // ── KT CTA gradient ───────────────────────────────────────────────
  static const LinearGradient ktCtaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ktGreen, ktGreenDeep],
  );

  // ── HC CTA gradient ───────────────────────────────────────────────
  static const LinearGradient hcCtaGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromRGBO(63, 184, 175, 0.30),
      Color.fromRGBO(63, 184, 175, 0.45),
    ],
  );

  // ── Level badge gradient (step 1 hero card) ───────────────────────
  static const LinearGradient levelBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purplePrimary, purpleDeep],
  );

  // ── Sheet surface gradient ────────────────────────────────────────
  static const LinearGradient sheetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1838), Color(0xFF0F1226)],
  );

  // ── Shadows ───────────────────────────────────────────────────────
  static const List<BoxShadow> primaryCtaShadow = [
    BoxShadow(
      color: Color.fromRGBO(139, 92, 246, 0.65),
      blurRadius: 24,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> hcCtaShadow = [
    BoxShadow(
      color: Color.fromRGBO(63, 184, 175, 0.45),
      blurRadius: 22,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> ktCtaShadow = [
    BoxShadow(
      color: Color.fromRGBO(123, 164, 43, 0.55),
      blurRadius: 24,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> levelBadgeShadow = [
    BoxShadow(
      color: Color.fromRGBO(139, 92, 246, 0.55),
      blurRadius: 14,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> googleButtonShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.25),
      blurRadius: 18,
      offset: Offset(0, 4),
    ),
  ];

  // ── Step-tile background gradient (step 1 sigil halo replacement) ─
  static const RadialGradient sigilHaloGradient = RadialGradient(
    radius: 0.5,
    colors: [Color.fromRGBO(139, 92, 246, 0.5), Colors.transparent],
    stops: [0.0, 1.0],
  );

  // ── Background gradients (page) ───────────────────────────────────
  static const RadialGradient pageGradientTop = RadialGradient(
    center: Alignment(0, -1),
    radius: 0.8,
    colors: [Color.fromRGBO(139, 92, 246, 0.20), Colors.transparent],
    stops: [0.0, 0.6],
  );

  static const RadialGradient pageGradientBottom = RadialGradient(
    center: Alignment(0, 1),
    radius: 0.6,
    colors: [Color.fromRGBO(63, 184, 175, 0.10), Colors.transparent],
    stops: [0.0, 0.6],
  );

  // ── Type ──────────────────────────────────────────────────────────
  static const TextStyle displayTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.84, // -0.03em
    height: 1.15,
    color: textPrimary,
  );

  static const TextStyle stepHeading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.48, // -0.02em
    height: 1.2,
    color: textPrimary,
  );

  static const TextStyle stepSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4, // 0.14em
    height: 1.0,
  );

  static const TextStyle pillLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6, // 0.06em
  );

  static const TextStyle ctaLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle toggleTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.14, // -0.01em
    color: textPrimary,
  );

  static const TextStyle toggleSubtitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
}

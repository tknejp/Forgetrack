import 'package:flutter/material.dart';

/// RPG dark-fantasy design tokens — single source of truth for the Forgetrack UI.
/// All values derived from the Forgetrack Handoff v1 design bundle.
abstract final class FtTokens {
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

  // ── Domain tokens ─────────────────────────────────────────────────────────
  static const FtDomain steps = FtDomain(
    color: Color(0xFF34D399),
    dim: Color(0x2E34D399),
    glow: Color(0x4034D399),
    gradStart: Color(0x3834D399),
    gradEnd: Color(0x1410B981),
  );
  static const FtDomain calories = FtDomain(
    color: Color(0xFFFBBF24),
    dim: Color(0x2EFBBF24),
    glow: Color(0x40FBBF24),
    gradStart: Color(0x38FBBF24),
    gradEnd: Color(0x0FF59B0B),
  );
  static const FtDomain weight = FtDomain(
    color: Color(0xFF60A5FA),
    dim: Color(0x2E60A5FA),
    glow: Color(0x4060A5FA),
    gradStart: Color(0x3860A5FA),
    gradEnd: Color(0x0F3B82F6),
  );
  static const FtDomain sleep = FtDomain(
    color: Color(0xFFA89BFF),
    dim: Color(0x2EA89BFF),
    glow: Color(0x40A89BFF),
    gradStart: Color(0x38A89BFF),
    gradEnd: Color(0x0F7C6FFF),
  );
  static const FtDomain active = FtDomain(
    color: Color(0xFF2DD4BF),
    dim: Color(0x2E2DD4BF),
    glow: Color(0x402DD4BF),
    gradStart: Color(0x382DD4BF),
    gradEnd: Color(0x0F14B8A6),
  );
  static const FtDomain protein = FtDomain(
    color: Color(0xFF60A5FA),
    dim: Color(0x2E60A5FA),
    glow: Color(0x4060A5FA),
    gradStart: Color(0x2E60A5FA),
    gradEnd: Color(0x0D3B82F6),
  );
  static const FtDomain fat = FtDomain(
    color: Color(0xFFFBBF24),
    dim: Color(0x2EFBBF24),
    glow: Color(0x40FBBF24),
    gradStart: Color(0x2EFBBF24),
    gradEnd: Color(0x0DF59B0B),
  );
  static const FtDomain carbs = FtDomain(
    color: Color(0xFFF472B6),
    dim: Color(0x2EF472B6),
    glow: Color(0x40F472B6),
    gradStart: Color(0x2EF472B6),
    gradEnd: Color(0x0DEC4899),
  );

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const double radiusCard = 18.0;
  static const double radiusIcon = 10.0;
  static const double radiusProgress = 99.0;

  // ── Font sizes ─────────────────────────────────────────────────────────────
  static const double fontSizeTitle = 20.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeCaption = 11.0;
  static const double fontSizeMicro = 10.0;
  static const double fontSizeTiny = 9.0;
}

@immutable
class FtDomain {
  final Color color;
  final Color dim;
  final Color glow;
  final Color gradStart;
  final Color gradEnd;

  const FtDomain({
    required this.color,
    required this.dim,
    required this.glow,
    required this.gradStart,
    required this.gradEnd,
  });

  LinearGradient get gradient => LinearGradient(
        begin: const Alignment(-1, -1),
        end: const Alignment(1, 1),
        colors: [gradStart, gradEnd],
      );

  BoxDecoration cardDecoration({double radius = FtTokens.radiusCard}) =>
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: dim),
      );
}

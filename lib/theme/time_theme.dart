import 'package:flutter/material.dart';

// ─── Time segments ─────────────────────────────────────────────────────────────

enum TimeSegment {
  dawn,       // 05:00–08:00  soft pre-sunrise light
  morning,    // 08:00–11:00  crisp bright morning
  noon,       // 11:00–15:00  full clear daylight
  afternoon,  // 15:00–18:00  warm golden afternoon
  sunset,     // 18:00–20:30  amber / orange horizon
  evening,    // 20:30–23:00  cooling blue-purple dusk
  night,      // 23:00–05:00  deep dark
}

// ─── Palette per segment ───────────────────────────────────────────────────────

/// Subtle per-segment palette overrides applied on top of the static theme.
///
/// All values are deliberately muted — the goal is mood, not rebranding.
/// [lightSurface] and [darkSurface] are the base scaffold surface colours;
/// all surface-container tiers are derived from them in [AppTheme].
@immutable
class TimePalette {
  final Color accent;
  final Color lightSurface;
  final Color darkSurface;

  const TimePalette({
    required this.accent,
    required this.lightSurface,
    required this.darkSurface,
  });
}

// ─── Visual state ──────────────────────────────────────────────────────────────

@immutable
class TimeThemeVisuals {
  final String backgroundAsset;

  /// Scrim colour layered over the background to keep card text readable.
  final Color scrimColor;

  /// Subtle palette overrides for accent and surface tone.
  final TimePalette palette;

  const TimeThemeVisuals({
    required this.backgroundAsset,
    required this.scrimColor,
    required this.palette,
  });
}

// ─── Resolver ─────────────────────────────────────────────────────────────────

class TimeThemeResolver {
  TimeThemeResolver._();

  // Expected asset paths — wide-landscape PNGs matching the existing convention.
  // Drop them into assets/ui/ and they will be picked up automatically on the
  // next build.  The background widget falls back to the static day/night
  // asset via Image.errorBuilder while files are not yet present.
  static const _kDawn      = 'assets/ui/bg_dawn_wide.png';
  static const _kMorning   = 'assets/ui/bg_morning_wide.png';
  static const _kNoon      = 'assets/ui/bg_noon_wide.png';
  static const _kAfternoon = 'assets/ui/bg_afternoon_wide.png';
  static const _kSunset    = 'assets/ui/bg_sunset_wide.png';
  static const _kEvening   = 'assets/ui/bg_evening_wide.png';
  static const _kNight     = 'assets/ui/bg_night_wide.png';

  // ── Per-segment palettes ─────────────────────────────────────────────────
  //
  // Accent: muted, earthy — no neon, no over-saturated hues.
  // Surfaces: ±2–6 RGB units from the static neutral base.
  //   Light neutral base: 0xFFF7F9FB  (R247 G249 B251)
  //   Dark  neutral base: 0xFF151A21  (R21  G26  B33)
  //
  static const _kDawnPalette = TimePalette(
    accent:       Color(0xFF9E7060), // muted rose-amber  — soft sunrise warmth
    lightSurface: Color(0xFFFAF8F6), // +3R  –1G  –5B  — warm cream
    darkSurface:  Color(0xFF1A1916), // +5R  –1G  –11B — warm dark
  );
  static const _kMorningPalette = TimePalette(
    accent:       Color(0xFF2E8B7F), // default teal — morning is the reference
    lightSurface: Color(0xFFF7F9FB), // unchanged
    darkSurface:  Color(0xFF151A21), // unchanged
  );
  static const _kNoonPalette = TimePalette(
    accent:       Color(0xFF2E7EA8), // muted sky blue   — clear midday air
    lightSurface: Color(0xFFF6F8FC), // –1R  –1G  +1B  — slightly crisp
    darkSurface:  Color(0xFF141921), // –1R  –1G  0B   — slightly cooler
  );
  static const _kAfternoonPalette = TimePalette(
    accent:       Color(0xFF5A8A3E), // warm olive green  — golden afternoon
    lightSurface: Color(0xFFF8F9F5), // +1R   0G  –6B  — faint warm olive
    darkSurface:  Color(0xFF181A15), // +3R   0G  –12B — warm olive dark
  );
  static const _kSunsetPalette = TimePalette(
    accent:       Color(0xFFAE6040), // muted terracotta  — warm amber horizon
    lightSurface: Color(0xFFFAF7F4), // +3R  –2G  –7B  — warm amber tint
    darkSurface:  Color(0xFF1A1813), // +5R  –2G  –14B — warm amber dark
  );
  static const _kEveningPalette = TimePalette(
    accent:       Color(0xFF5C5A9E), // muted indigo      — dusk violet calm
    lightSurface: Color(0xFFF5F6FB), // –2R  –3G   0B  — faint cool violet
    darkSurface:  Color(0xFF131420), // –2R  –6G  –1B  — deep violet dark
  );
  static const _kNightPalette = TimePalette(
    accent:       Color(0xFF3A6080), // slate blue        — quiet night
    lightSurface: Color(0xFFF5F7FB), // –2R  –2G   0B  — faint cool blue
    darkSurface:  Color(0xFF121520), // –3R  –5G  –1B  — deep night dark
  );

  // ── Segment detection ────────────────────────────────────────────────────

  static TimeSegment segmentFor(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes >= 300  && minutes < 480)  return TimeSegment.dawn;
    if (minutes >= 480  && minutes < 660)  return TimeSegment.morning;
    if (minutes >= 660  && minutes < 900)  return TimeSegment.noon;
    if (minutes >= 900  && minutes < 1080) return TimeSegment.afternoon;
    if (minutes >= 1080 && minutes < 1230) return TimeSegment.sunset;
    if (minutes >= 1230 && minutes < 1380) return TimeSegment.evening;
    return TimeSegment.night;
  }

  /// Minutes from [time] until the next segment boundary crosses.
  static int minutesUntilNextSegment(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    const boundaries = <int>[300, 480, 660, 900, 1080, 1230, 1380];
    for (final b in boundaries) {
      if (minutes < b) return b - minutes;
    }
    // After 23:00 — wrap to 05:00 next day.
    return (24 * 60 - minutes) + 300;
  }

  // ── Visuals lookup ───────────────────────────────────────────────────────

  static TimeThemeVisuals visualsFor(TimeSegment segment) {
    return switch (segment) {
      TimeSegment.dawn => const TimeThemeVisuals(
        backgroundAsset: _kDawn,
        scrimColor: Color(0x65000000), // ~39%
        palette: _kDawnPalette,
      ),
      TimeSegment.morning => const TimeThemeVisuals(
        backgroundAsset: _kMorning,
        scrimColor: Color(0x55FFFFFF), // ~33% white
        palette: _kMorningPalette,
      ),
      TimeSegment.noon => const TimeThemeVisuals(
        backgroundAsset: _kNoon,
        scrimColor: Color(0x55FFFFFF), // ~33% white
        palette: _kNoonPalette,
      ),
      TimeSegment.afternoon => const TimeThemeVisuals(
        backgroundAsset: _kAfternoon,
        scrimColor: Color(0x50000000), // ~31%
        palette: _kAfternoonPalette,
      ),
      TimeSegment.sunset => const TimeThemeVisuals(
        backgroundAsset: _kSunset,
        scrimColor: Color(0x60000000), // ~38%
        palette: _kSunsetPalette,
      ),
      TimeSegment.evening => const TimeThemeVisuals(
        backgroundAsset: _kEvening,
        scrimColor: Color(0x78000000), // ~47%
        palette: _kEveningPalette,
      ),
      TimeSegment.night => const TimeThemeVisuals(
        backgroundAsset: _kNight,
        scrimColor: Color(0x85000000), // ~52%
        palette: _kNightPalette,
      ),
    };
  }
}

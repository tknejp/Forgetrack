import 'package:flutter/material.dart';

abstract final class JourneyMapAssets {
  static const route = 'assets/map/journey_map_route.json';
  static const background = 'assets/ui/journey_map_bg.png';
  static const collapsedBackground = 'assets/ui/journey_map_bg_collapsed.png';
  static const fallbackBackground = 'assets/ui/journey_map_bg.jpg';
  static const fog = 'assets/ui/journey_map_fog.png';
}

abstract final class JourneyMapLayout {
  static const imageWidth = 1408.0;
  static const imageHeight = 11712.0;
  static const imageAspectRatio = imageHeight / imageWidth;

  static const collapsedTopPadding = 58.0;
  static const collapsedBottomPadding = 58.0;
  static const collapsedSingleNodeX = 0.50;
  static const collapsedSingleNodeY = 0.50;
  static const collapsedNodeXs = [0.34, 0.66];

  static const sideEventTangentEpsilon = 0.1;
  static const sideEventDistanceFactor = 0.12;
  static const sideEventMinDistance = 38.0;
  static const sideEventMaxDistance = 68.0;
  static const sideEventPreferredMin = 0.65;
  static const sideEventPreferredMax = 1.35;
  static const sideEventDistanceSteps = [0.0, 0.42, 0.84];
  static const sideEventAlongShifts = [0.0, -18.0, 18.0, -34.0, 34.0];
  static const collisionGap = 4.0;

  static const routePointStart = 0;
  static const routePointMinLevel = 1;
  static const routePointMaxLevel = 100;
  /// How many levels ahead of the player still render as small route-level
  /// dots. Beyond this window locked content is fully hidden — the fog mass
  /// covers it and there's nothing to peek through the receding wisp.
  static const routeLevelLookahead = 3;
  static const currentLevelDotSize = 14.0;
  static const unlockedLevelDotSize = 8.0;
  static const lockedLevelDotSize = 7.0;

  static const mapRadius = 20.0;
  static const focusScrollAnchor = 0.62;
}

abstract final class JourneyMapMotion {
  static const pulseDuration = Duration(milliseconds: 2200);
  static const overlaySwitchDuration = Duration(milliseconds: 180);
  static const overlayScaleBegin = 0.94;
  static const pulseScale = 0.75;
}

abstract final class JourneyMapNodeSizes {
  static const finalLevel = 38.0;
  static const start = 34.0;
  static const current = 36.0;
  static const next = 34.0;
  static const titleMilestone = 32.0;
  static const achievement = 22.0;
  static const level = 22.0;
  static const quest = 20.0;
  static const fallback = 22.0;

  static const nodeTapPadding = 28.0;
  static const specialHaloPadding = 12.0;
}

abstract final class JourneyMapCollisionRadii {
  static const specialAnchor = 34.0;
  static const highlightedAnchor = 32.0;
  static const pathAnchor = 30.0;
  static const achievement = 24.0;
  static const fallback = 22.0;
}

abstract final class JourneyMapLevelDotStyle {
  static const unlockedColor = Color(0xFFD4AF37);
  static const currentTextColor = Color(0xFF20160A);
  static const currentTextSize = 7.0;
  static const currentLetterSpacing = -0.7;
  static const currentBorderWidth = 1.6;
  static const defaultBorderWidth = 0.8;
  static const currentGlowBlur = 9.0;
  static const defaultGlowBlur = 6.0;
  static const currentGlowAlpha = 0.42;
  static const defaultGlowAlpha = 0.32;
  static const pulseBorderWidth = 2.0;
}

abstract final class JourneyMapShellStyle {
  static const gradientStart = Color(0xFF1A1838);
  static const gradientEnd = Color(0xFF0F1226);
  static const borderAlpha = 0.08;
  static const accentShadowAlpha = 0.10;
  static const accentShadowBlur = 20.0;
  static const accentShadowSpread = -4.0;
  static const shadowOffset = Offset(0, 4);

  static const panHintInset = 10.0;
  static const panHintHorizontalPadding = 8.0;
  static const panHintVerticalPadding = 4.0;
  static const panHintRadius = 8.0;
  static const panHintBgAlpha = 0.40;
  static const panHintBorderAlpha = 0.10;
  static const panHintIconSize = 11.0;
  static const panHintGap = 4.0;
  static const panHintFontSize = 9.0;
  static const panHintTextAlpha = 0.78;
  static const panHintLetterSpacing = 0.4;
}

abstract final class JourneyMapTooltipStyle {
  static const maxWidth = 240.0;
  static const approxHeight = 130.0;
  static const nodeRadius = 18.0;
  static const gap = 10.0;
  static const edgePadding = 8.0;
  static const flipAtCanvasFraction = 0.55;

  static const cardColor = Color(0xEE0F1226);
  static const cardRadius = 13.0;
  static const padding = EdgeInsets.fromLTRB(11, 9, 6, 11);
  static const iconBoxSize = 34.0;
  static const iconSize = 18.0;
}

abstract final class JourneyMapBackgroundStyle {
  static const topGlowSize = 280.0;
  static const topGlowAlpha = 0.22;
  static const topGlowOffset = Offset(-60, -80);

  static const middleGlowSize = 240.0;
  static const middleGlowAlpha = 0.14;
  static const middleGlowTopFactor = 0.4;
  static const middleGlowRight = -80.0;

  static const bottomGlowSize = 220.0;
  static const bottomGlowAlpha = 0.12;
  static const bottomGlowLeft = -50.0;
  static const bottomGlowBottom = -60.0;

  static const overlayTopAlpha = 0.20;
  static const overlayBottomAlpha = 0.45;
}

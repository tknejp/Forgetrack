/// Shared geometry constants for the [ProfileDetailHeroCard] scene.
///
/// Hero + companion + background + shadows all hang off a single
/// vertical anchor (the "ground line"). Lifted to top-level constants
/// so the per-element widgets in sibling files can compute their own
/// sizing without each one needing a back-reference to the parent.
class ProfileHeroLayout {
  ProfileHeroLayout._();

  // Card height bumped 480 → 530 on 2026-05-26 so the emblem row +
  // companion buff chip have their own dark "shelf" below the
  // painted scene. The 50-px delta is fully absorbed by
  // [groundLineFromBottom] — the ground line, scene background,
  // companion sprite, hero avatar, and their shadows therefore
  // keep their original absolute positions, and the new space
  // appears as additional dark UI band at the bottom.
  static const double height = 500;
  static const double edge = 16;

  static const double groundLineFromBottom = 116;
  static const double groundLineY = height - groundLineFromBottom;

  // Hero + companion sprite format: 512² with painted feet 48 px above
  // the asset's bottom edge.
  static const double assetFeetFraction = 48 / 512;

  // Tap-target inset against the 512² asset frame: the painted figure
  // sits inside ~50 px of empty pixels top/bottom and ~160 px left/right.
  // Used by avatar + companion tap overlays so taps in the empty
  // surrounding area fall through to whatever sits behind the sprite
  // (currently nothing actionable, but it stops the sheet from opening
  // when the user clearly tapped outside the silhouette).
  static const double assetTapInsetVerticalFraction = 50 / 512;
  static const double assetTapInsetHorizontalFraction = 160 / 512;

  // Background scenes: 9:16 portrait, standing area at 0.77 down.
  static const double backgroundAspect = 16 / 9;
  static const double backgroundStandingFraction = 0.77;

  static const double heroAvatarSize = 268;
  static const double heroAvatarBottom = groundLineFromBottom - heroAvatarSize * assetFeetFraction;
  static const double heroAvatarOverhang = 32;
  static const double heroAvatarLeft = edge - heroAvatarOverhang;

  static const double avatarShadowWidth = 180;
  static const double avatarShadowHeight = 32;
  static const double avatarShadowNudgeX = 0;
  static const double avatarShadowNudgeY = 5;
  static const double avatarShadowLeft = heroAvatarLeft + (heroAvatarSize - avatarShadowWidth) / 2 + avatarShadowNudgeX;
  static const double avatarShadowBottom = groundLineFromBottom - avatarShadowHeight / 2 + avatarShadowNudgeY;

  static const double companionSize = 220;
  static const double companionInset = 0;
  static const double companionRight = edge + companionInset;
  static const double companionBottom =
      groundLineFromBottom - companionSize * assetFeetFraction;
  static const double companionStandeeNudgeX = 8;
  static const double companionCenterFromRight =
      companionRight - companionStandeeNudgeX + companionSize / 2;

  static const double companionShadowWidth = 100;
  static const double companionShadowNudgeY = 0;
  static const double companionShadowHeight = 24;
  static const double companionShadowBottom = avatarShadowBottom - companionShadowNudgeY;
  static const double companionShadowRight = companionCenterFromRight - companionShadowWidth / 2;

  static const double companionGroundGlowWidth = 120;
  static const double companionGroundGlowRight =
      companionCenterFromRight - companionGroundGlowWidth / 2;
  // Ground glow sits 52 px below the conceptual ground line —
  // tracks the ground line so it stays at its old absolute y after
  // the card-height bump.
  static const double companionGroundGlowBottom = groundLineFromBottom - 52;

  // Buff chip sits just below the companion's painted feet (= the
  // ground line), well above the emblem row at the bottom. Anchored
  // to [groundLineY] so the chip tracks the companion asset
  // automatically — when the card height or ground line moves, the
  // chip moves with the companion instead of drifting on a static
  // px offset from the top.
  //
  // Top-anchored (not bottom-anchored) so when the buff label wraps
  // to a second line the new line drops BELOW the first instead of
  // shoving the first line upward — first-line position stays put
  // regardless of label length.
  static const double companionBuffChipBelowGround = 12;
  static const double companionBuffChipTop =
      groundLineY + companionBuffChipBelowGround;
  static const double companionBuffChipBandWidth = 200;
  static const double companionBuffChipBandRight =
      companionCenterFromRight - companionBuffChipBandWidth / 2;

  // Hero card now hosts only the cinematic scene + emblem row. Level /
  // title moved out to the standalone [ProfileTitleBanner] above the
  // card (2026-05-27); handle / friends live in the screen app bar
  // subtitle. No top-anchored elements remain inside this stack.
  // Emblem row — 6 slots laid out horizontally along the BOTTOM of
  // the hero card, evenly distributed between the side gutters
  // (relocated from a right-edge column on 2026-05-26). Slot size
  // is sized for a 6-slot row to fit on a ~360-px-wide screen
  // (6·56 + 5·gap ≤ width − 2·edge) without overlapping; the
  // [Row]'s spaceBetween distribution handles wider screens by
  // expanding the gaps instead of the slots themselves.
  static const double emblemRowBottom = 6;
  static const double emblemRowLeft = edge;
  static const double emblemRowRight = edge;

  static const double emblemSlotSize = 56;
  // Visible dashed frame drawn for empty/locked slots. Intentionally
  // smaller than [emblemSlotSize] so equipped emblem artwork visibly
  // overflows the placeholder frame — slot reads as a hint, emblem
  // reads as the main object.
  static const double emblemFrameSize = 48;
  // Minimum visual breathing room between adjacent slots; the
  // actual gap on a given screen comes from spaceBetween + the
  // available width, so this constant is informational rather than
  // load-bearing.
  static const double emblemGap = 4;

  /// Number of slots in the emblem collection (mirrors
  /// `EmblemBoard.slotCount`).
  static const int emblemSlotCount = 6;
}

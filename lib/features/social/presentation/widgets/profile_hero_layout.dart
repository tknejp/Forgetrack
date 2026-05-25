/// Shared geometry constants for the [ProfileDetailHeroCard] scene.
///
/// Hero + companion + background + shadows all hang off a single
/// vertical anchor (the "ground line"). Lifted to top-level constants
/// so the per-element widgets in sibling files can compute their own
/// sizing without each one needing a back-reference to the parent.
class ProfileHeroLayout {
  ProfileHeroLayout._();

  static const double height = 480;
  static const double edge = 16;

  static const double groundLineFromBottom = 66;
  static const double groundLineY = height - groundLineFromBottom;

  // Hero + companion sprite format: 512² with painted feet 48 px above
  // the asset's bottom edge.
  static const double assetFeetFraction = 48 / 512;

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
  static const double companionGroundGlowBottom = 14;

  static const double companionBuffChipBottom = 6;
  static const double companionBuffChipBandWidth = 200;
  static const double companionBuffChipBandRight =
      companionCenterFromRight - companionBuffChipBandWidth / 2;

  // Inline `@handle · Přátelé N` row — muted subtitle pinned to the
  // very top of the hero card, above the louder level + title label.
  // The reorder (handle on top, level below) lands on 2026-05-25;
  // the rationale is that the app bar already mirrors the player's
  // display name, so the visual "who am I looking at" identifiers
  // group near the top, with the louder LVL / TITLE banner sitting
  // beneath them as the primary game-state row. Top inset pulled
  // up by 8 px on 2026-05-25 so the whole identity strip kisses the
  // app bar's lower edge instead of leaving a visual gap.
  static const double identityTop = 8;
  // Level + title label sits below the handle row, full card width.
  // Bumped 8 px upward together with `identityTop` so the spacing
  // between the two rows stays unchanged.
  static const double levelTitleTop = 32;
  // Emblem grid no longer sits in the top-right corner — it
  // anchors LEFT, immediately below the level + title row, so the
  // grid reads as a continuation of the identity column rather
  // than a parallel side-element. Top inset clears the bigger
  // LVL / TITLE typography (line height ~28 px) plus a small gap.
  static const double emblemTop = 64;

  static const double emblemSlotSize = 46;
  static const double emblemGap = 5;

  /// Number of slots in the emblem collection (mirrors
  /// `EmblemBoard.slotCount`).
  static const int emblemSlotCount = 6;
}

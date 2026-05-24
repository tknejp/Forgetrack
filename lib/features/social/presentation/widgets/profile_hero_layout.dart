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
  static const double heroAvatarBottom =
      groundLineFromBottom - heroAvatarSize * assetFeetFraction;
  static const double heroAvatarOverhang = 32;
  static const double heroAvatarLeft = edge - heroAvatarOverhang;

  static const double avatarShadowWidth = 220;
  static const double avatarShadowHeight = 48;
  static const double avatarShadowNudgeX = 6;
  static const double avatarShadowLeft = heroAvatarLeft +
      (heroAvatarSize - avatarShadowWidth) / 2 +
      avatarShadowNudgeX;
  static const double avatarShadowBottom =
      groundLineFromBottom - avatarShadowHeight / 2;

  static const double companionSize = 220;
  static const double companionInset = 0;
  static const double companionRight = edge + companionInset;
  static const double companionBottom =
      groundLineFromBottom - companionSize * assetFeetFraction;
  static const double companionStandeeNudgeX = 8;
  static const double companionCenterFromRight =
      companionRight - companionStandeeNudgeX + companionSize / 2;

  static const double companionShadowWidth = 200;
  static const double companionShadowHeight = avatarShadowHeight;
  static const double companionShadowBottom = avatarShadowBottom;
  static const double companionShadowRight =
      companionCenterFromRight - companionShadowWidth / 2;

  static const double companionGroundGlowWidth = 120;
  static const double companionGroundGlowRight =
      companionCenterFromRight - companionGroundGlowWidth / 2;
  static const double companionGroundGlowBottom = 14;

  static const double companionBuffChipBottom = 6;
  static const double companionBuffChipBandWidth = 200;
  static const double companionBuffChipBandRight =
      companionCenterFromRight - companionBuffChipBandWidth / 2;

  static const double identityTop = 16;
  static const double emblemTop = 16;

  static const double emblemSlotSize = 44;
  static const double emblemGap = 5;
  static const double emblemGridWidth = 3 * emblemSlotSize + 2 * emblemGap;
  static const double identityEmblemGutter = 12;
  static const double identityRight = edge + emblemGridWidth + identityEmblemGutter;

  /// Number of slots in the emblem collection (mirrors
  /// `EmblemBoard.slotCount`).
  static const int emblemSlotCount = 11;
}

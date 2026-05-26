import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/companion_buff_chip.dart';
import '../../../progression_engine/domain/policy/level_policy.dart';
import '../../domain/social_models.dart';
import 'profile_hero_avatar.dart';
import 'profile_hero_emblem_collection.dart';
import 'profile_hero_layout.dart';
import 'profile_hero_scene.dart';
import 'profile_hero_scene_props.dart';
import 'social_cosmetic_avatar.dart'
    show socialBackgroundDefinition, socialCosmeticById;

/// Cinematic 480-px tall hero card surfaced at the top of
/// [SocialUserProfileSheet]. Ports `design_handoff_social_profile`:
///
///   * Background image (cosmetic) with vertical fade overlay
///   * Hero body bottom-left with foot shadow
///   * Identity block (name + handle + title pill) top-left
///   * Companion bottom-right with warm ground glow + buff chip
///   * Single-column emblem collection along the right edge
///
/// Designed to render flush against the top of the surrounding screen
/// (no rounded outer corners, no horizontal padding) — the caller is
/// responsible for clipping the top corners if it lives inside a sheet
/// with rounded chrome.
class ProfileDetailHeroCard extends StatelessWidget {
  const ProfileDetailHeroCard({
    super.key,
    required this.displayName,
    required this.profile,
    required this.isMe,
    this.raceId,
    this.skinId,
    this.emblemSlots = const <Cosmetic?>[],
    this.onTapEmblemSlot,
    this.onTapCompanion,
    this.onTapAvatar,
  });

  final String displayName;
  final SocialUserProfile? profile;
  final bool isMe;
  final String? raceId;
  final String? skinId;
  final List<Cosmetic?> emblemSlots;
  final void Function(int slotIndex)? onTapEmblemSlot;
  final void Function(Cosmetic companion)? onTapCompanion;

  /// Tap on the hero body / avatar → skin slot sheet (own profile
  /// only). Receives the currently equipped skin id, which may be
  /// null if nothing is equipped yet — the sheet handles the empty
  /// case by collapsing the manage block.
  final void Function(String? equippedSkinId)? onTapAvatar;

  /// Total emblem slots in the collection grid. Mirrors
  /// `EmblemBoard.slotCount` so the data model and the visual grid
  /// stay aligned.
  static const int kEmblemSlotCount = ProfileHeroLayout.emblemSlotCount;

  // Resolves what each of the 11 grid slots actually shows.
  //
  // * Own profile: caller passes `emblemSlots` (length 11) from the
  //   `EmblemBoardProvider`.
  // * Friend profile: caller has no slot map, so we fabricate one from
  //   the single `equipped.emblemId` so slot 0 shows their current
  //   emblem and the rest stay locked.
  List<Cosmetic?> _resolveSlots(Cosmetic? equipped) {
    if (emblemSlots.length == kEmblemSlotCount) return emblemSlots;
    return <Cosmetic?>[
      equipped,
      for (var i = 1; i < kEmblemSlotCount; i++) null,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats;
    final equipped = profile?.equippedCosmetics;
    final background = socialBackgroundDefinition(equipped?.backgroundId);
    final companion = socialCosmeticById(equipped?.companionId);
    final emblem = socialCosmeticById(equipped?.emblemId);
    final playerLevel =
        const ProgressionLevelPolicy().resolve(stats?.totalXp ?? 0).level;

    return SizedBox(
      height: ProfileHeroLayout.height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: ProfileHeroBackground(definition: background)),
          // Edge fade stays pinned to the header frame regardless of
          // the background shift, so feathering always lands at the
          // card's true top and bottom seams.
          const Positioned.fill(child: ProfileHeroBackgroundEdgeFade()),
          // Identity block (handle + friends) lives in the screen's
          // top app bar (`ScreenHeader.subtitle`). Level + class title
          // moved out of the hero stack into the standalone
          // [ProfileTitleBanner] above this card on 2026-05-27. Both
          // were previously rendered here as text overlays; the hero
          // card is now pure cinematic scene + emblem row.
          // Emblem row — horizontal band along the BOTTOM edge of
          // the hero card, evenly distributed between the side
          // gutters. The companion buff chip was pulled upward
          // ([ProfileHeroLayout.companionBuffChipBottom]) to make
          // room for this row. Slots unlock progressively with the
          // player's level (see [EmblemBoard.slotUnlockLevels]).
          Positioned(
            left: ProfileHeroLayout.emblemRowLeft,
            right: ProfileHeroLayout.emblemRowRight,
            bottom: ProfileHeroLayout.emblemRowBottom,
            child: ProfileHeroEmblemCollection(
              slots: _resolveSlots(emblem),
              playerLevel: playerLevel,
              slotSize: ProfileHeroLayout.emblemSlotSize,
              onTapSlot: onTapEmblemSlot,
            ),
          ),
          // Soft elliptical shadow under the avatar's feet. Rendered
          // behind the avatar so the sprite occludes the centre.
          const Positioned(
            left: ProfileHeroLayout.avatarShadowLeft,
            bottom: ProfileHeroLayout.avatarShadowBottom,
            child: ProfileHeroFootShadow(
              width: ProfileHeroLayout.avatarShadowWidth,
              height: ProfileHeroLayout.avatarShadowHeight,
            ),
          ),
          // Hero body — bottom-left, full-body skin asset. Wrapped in
          // a GestureDetector so a tap opens the skin slot sheet
          // (own profile only — friend profiles pass null and the
          // detector becomes a no-op).
          Positioned(
            left: ProfileHeroLayout.heroAvatarLeft,
            bottom: ProfileHeroLayout.heroAvatarBottom,
            child: _SpriteWithTapTarget(
              size: ProfileHeroLayout.heroAvatarSize,
              onTap: onTapAvatar == null
                  ? null
                  : () => onTapAvatar!(skinId),
              child: ProfileHeroSceneBlendFade(
                child: ProfileHeroBodyAvatar(
                  raceId: raceId,
                  skinId: skinId,
                  fallbackLabel: displayName,
                  size: ProfileHeroLayout.heroAvatarSize,
                ),
              ),
            ),
          ),
          // Companion standee — foot shadow + ground glow + sprite +
          // buff chip below.
          if (companion != null) ...[
            const Positioned(
              right: ProfileHeroLayout.companionShadowRight,
              bottom: ProfileHeroLayout.companionShadowBottom,
              child: ProfileHeroFootShadow(
                width: ProfileHeroLayout.companionShadowWidth,
                height: ProfileHeroLayout.companionShadowHeight,
              ),
            ),
            const Positioned(
              right: ProfileHeroLayout.companionGroundGlowRight,
              bottom: ProfileHeroLayout.companionGroundGlowBottom,
              child: ProfileHeroGroundGlow(
                width: ProfileHeroLayout.companionGroundGlowWidth,
              ),
            ),
            // Standee is anchored separately so the buff chip does NOT
            // push the sprite upward — pairing the standee with the
            // chip inside a Column would make the companion sprite sit
            // chipHeight + gap higher than the hero avatar, breaking
            // the "same 512² asset, same vertical position" contract.
            // The outward nudge is baked into `right` directly so the
            // visible sprite still kisses the scene edge.
            Positioned(
              right: ProfileHeroLayout.companionRight -
                  ProfileHeroLayout.companionStandeeNudgeX,
              bottom: ProfileHeroLayout.companionBottom,
              child: _SpriteWithTapTarget(
                size: ProfileHeroLayout.companionSize,
                onTap: onTapCompanion == null
                    ? null
                    : () => onTapCompanion!(companion),
                child: ProfileHeroSceneBlendFade(
                  child: ProfileHeroCompanionStandee(
                    definition: companion,
                    size: ProfileHeroLayout.companionSize,
                  ),
                ),
              ),
            ),
            if (companion is Companion && companion.buff != null)
              Positioned(
                right: ProfileHeroLayout.companionBuffChipBandRight,
                bottom: ProfileHeroLayout.companionBuffChipBottom,
                width: ProfileHeroLayout.companionBuffChipBandWidth,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: CompanionBuffChip(
                      buff: companion.buff!,
                      color: RarityPalette.forRarity(companion.rarity).color,
                      compact: true,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Wraps a 512²-asset sprite (rendered at [size]) with a tap target
/// that only covers the painted figure, not the empty margins baked
/// into the asset. Sprite is painted full-size; the GestureDetector
/// sits on top, inset by [ProfileHeroLayout.assetTapInset*Fraction].
class _SpriteWithTapTarget extends StatelessWidget {
  const _SpriteWithTapTarget({
    required this.size,
    required this.onTap,
    required this.child,
  });

  final double size;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hInset = size * ProfileHeroLayout.assetTapInsetHorizontalFraction;
    final vInset = size * ProfileHeroLayout.assetTapInsetVerticalFraction;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: hInset,
            right: hInset,
            top: vInset,
            bottom: vInset,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

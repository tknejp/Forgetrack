import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/config/skin_asset_resolver.dart';
import '../../../cosmetics/domain/cosmetic_catalog.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/companion_buff_chip.dart';
import '../../../cosmetics/presentation/widgets/companion_fake_idle_preview.dart';
import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../progression_engine/domain/policy/level_policy.dart';
import '../../domain/social_models.dart';
import 'social_cosmetic_avatar.dart'
    show socialBackgroundDefinition, socialCosmeticById;

/// Cinematic 400-px tall hero card surfaced at the top of
/// [SocialUserProfileSheet]. Ports `design_handoff_social_profile`:
///
///   * Background image (cosmetic) with radial + vertical darken overlays
///   * `_FramedAvatar` top-left, tilted -3°, with neutral `LVL N` pin
///   * Identity block (name + handle + title pill) right of the avatar
///   * Companion bottom-right with a warm `_GroundGlow` underneath
///   * `_EmblemCollection` bottom-left, 4·4·3 grid of 52 px slots
///
/// Designed to render flush against the top of the surrounding screen
/// (no rounded outer corners, no horizontal padding) — the caller is
/// responsible for clipping the top corners if it lives inside a sheet
/// with rounded chrome.
class ProfileDetailHeroCard extends StatelessWidget {
  const ProfileDetailHeroCard({
    super.key,
    required this.displayName,
    required this.handle,
    required this.profile,
    required this.isMe,
    this.raceId,
    this.skinId,
    this.emblemSlots = const <Cosmetic?>[],
    this.unlockedCount = 0,
    this.onTapEmblemSlot,
    this.onTapCompanion,
    this.onEditHandle,
    this.friendCount,
    this.onTapFriendChip,
  });

  final String displayName;
  final String handle;
  final SocialUserProfile? profile;
  final bool isMe;

  /// `HeroRace` id resolved for the hero body. Null pre-onboarding /
  /// pre-skin-flow → renders a silhouette placeholder. Parents fill
  /// this from `CosmeticsProvider` (own profile) or from the social
  /// wire format (friend profile — wire extension lands in a follow-up).
  final String? raceId;

  /// Equipped skin cosmetic id. Combined with [raceId] by
  /// [SkinAssetResolver] to pick the on-disk full-body asset.
  final String? skinId;

  /// Per-slot emblem mapping. Length should match `slotCount` (11) —
  /// each entry is either the emblem pinned in that slot, or null for
  /// "empty slot". Slots beyond `unlockedCount - 1` render as locked
  /// dashed squares even if they happen to hold an emblem in the data
  /// (defensive against stale local pins after a slot-count change).
  final List<Cosmetic?> emblemSlots;

  /// How many of the 11 grid slots are unlocked — capped by how many
  /// distinct emblems the user has earned. Slots beyond this index
  /// render locked regardless of [emblemSlots] contents.
  final int unlockedCount;

  /// Tap callback fired with the slot index (0..10). Only unlocked
  /// slots are tappable — the call site decides what to do (e.g. open
  /// a picker, route to the cosmetics screen). Slots above
  /// `unlockedEmblems.length - 1` swallow the tap silently.
  final void Function(int slotIndex)? onTapEmblemSlot;

  /// Tap callback for the equipped companion's standee + buff chip.
  /// Fires the companion's [Cosmetic] definition so the call site
  /// can open the cosmetic details sheet. Null disables the tap.
  final void Function(Cosmetic companion)? onTapCompanion;

  final VoidCallback? onEditHandle;

  /// Number of friends to surface in the small "Přátelé · N" chip under
  /// the @handle. `null` hides the chip — used while the friend list is
  /// still loading.
  final int? friendCount;

  /// Tap callback for the friend chip — typically opens the friends
  /// modal sheet. `null` hides the chip.
  final VoidCallback? onTapFriendChip;

  /// Total emblem slots in the collection grid. Mirrors
  /// `EmblemBoard.slotCount` so the data model and the visual grid
  /// stay aligned.
  static const int kEmblemSlotCount = 11;

  // Resolves what each of the 11 grid slots actually shows.
  //
  // * Own profile: caller passes `emblemSlots` (length 11) from the
  //   `EmblemBoardProvider` — that's the source of truth.
  // * Friend profile: caller has no slot map, so we fabricate one
  //   from the single `equipped.emblemId` so slot 0 shows their
  //   current emblem and the rest stay locked.
  List<Cosmetic?> _resolveSlots(Cosmetic? equipped) {
    if (emblemSlots.length == kEmblemSlotCount) return emblemSlots;
    return <Cosmetic?>[
      equipped,
      for (var i = 1; i < kEmblemSlotCount; i++) null,
    ];
  }

  int _resolveUnlockedCount(Cosmetic? equipped) {
    if (unlockedCount > 0) return unlockedCount;
    return equipped == null ? 0 : 1;
  }

  // ── Design-spec sizing ─────────────────────────────────────────────────────
  static const double _kHeight = 400;
  static const double _kEdge = 16;

  /// Full-body hero avatar — 1.5× the companion standee per the
  /// 2026-05 redesign. Drives the asymmetric "hero on the left,
  /// companion on the right" composition. No frame border applied
  /// (frames live on the compact thumbnail surfaces only).
  static const double _kHeroAvatarSize = 200;
  static const double _kHeroAvatarBottom = 12;

  static const double _kCompanionSize = 134;
  static const double _kCompanionRight = _kEdge;
  static const double _kCompanionBottom = 20;

  static const double _kIdentityTop = 16;
  static const double _kEmblemTop = 16;

  // 3-column × 4-row emblem layout (11 slots, last row 2 of 3). Tile
  // and gap sized so the grid fits in the top-right quadrant alongside
  // the identity block on a 360-px-wide screen.
  static const double _kEmblemSlotSize = 44;
  static const double _kEmblemGap = 5;
  static const double _kEmblemGridWidth =
      3 * _kEmblemSlotSize + 2 * _kEmblemGap;
  static const double _kIdentityEmblemGutter = 12;
  static const double _kIdentityRight =
      _kEdge + _kEmblemGridWidth + _kIdentityEmblemGutter;

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats;
    final equipped = profile?.equippedCosmetics;
    final background = socialBackgroundDefinition(equipped?.backgroundId);
    final companion = socialCosmeticById(equipped?.companionId);
    final emblem = socialCosmeticById(equipped?.emblemId);

    final resolved =
        const ProgressionLevelPolicy().resolve(stats?.totalXp ?? 0);
    final levelDisplay =
        const ProgressionDisplayResolver().levelDisplay(resolved.level);
    final levelTitle = levelDisplay.title(context.l10n);

    final levelAccent =
        const ProgressionDisplayResolver().levelDisplay(resolved.level).accentColor;

    return SizedBox(
      height: _kHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _BackgroundLayer(definition: background),
          // Identity block — top-left. Constrained on the right to
          // leave room for the emblem grid sitting beside it in the
          // top-right quadrant.
          Positioned(
            left: _kEdge,
            top: _kIdentityTop,
            right: _kIdentityRight,
            child: _IdentityBlock(
              displayName: displayName,
              handle: handle,
              level: resolved.level,
              levelTitle: levelTitle,
              levelAccent: levelAccent,
              isMe: isMe,
              onEditHandle: onEditHandle,
              friendCount: friendCount,
              onTapFriendChip: onTapFriendChip,
            ),
          ),
          // Emblem grid — top-right (was bottom-left in the pre-2026-05
          // layout). 3-col × 4-row layout sized to fit alongside the
          // identity block.
          Positioned(
            right: _kEdge,
            top: _kEmblemTop,
            child: _EmblemCollection(
              slots: _resolveSlots(emblem),
              unlockedCount: _resolveUnlockedCount(emblem),
              slotSize: _kEmblemSlotSize,
              gap: _kEmblemGap,
              onTapSlot: onTapEmblemSlot,
            ),
          ),
          // Hero body — bottom-left, full-body skin asset. No frame
          // border per the 2026-05 redesign (frames live in the
          // compact thumbnail surfaces only — top app bar, social feed,
          // settings header, …).
          Positioned(
            left: _kEdge,
            bottom: _kHeroAvatarBottom,
            child: _HeroBodyAvatar(
              raceId: raceId,
              skinId: skinId,
              fallbackLabel: displayName,
              size: _kHeroAvatarSize,
            ),
          ),
          // Companion standee — warm radial glow on the ground + asset on
          // top. Centered roughly at right:6 / bottom:14 per the spec.
          // When the catalog row carries an XP buff (every player-facing
          // Companion does today), a compact buff chip sits below the
          // standee — keeps the mechanical effect adjacent to the
          // sprite without crashing into the emblem grid that occupies
          // the bottom-left quadrant of the hero card.
          if (companion != null) ...[
            const Positioned(
              right: 6,
              bottom: 14,
              child: _GroundGlow(width: 120),
            ),
            Positioned(
              right: _kCompanionRight,
              bottom: _kCompanionBottom,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapCompanion == null
                    ? null
                    : () => onTapCompanion!(companion),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The column is right-aligned to the 16-px card
                    // margin so the chip below sits flush with the
                    // standard right edge. The standee gets shifted
                    // back outward via Transform so the sprite keeps
                    // its "pressed against the scene" position
                    // without overflow-clipping the chip text.
                    Transform.translate(
                      offset: const Offset(8, 0),
                      child: _CompanionStandee(
                        definition: companion,
                        size: _kCompanionSize,
                      ),
                    ),
                    if (companion is Companion && companion.buff != null) ...[
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: CompanionBuffChip(
                          buff: companion.buff!,
                          color:
                              RarityPalette.forRarity(companion.rarity).color,
                          compact: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Background — image + radial darken + vertical fade.
// ─────────────────────────────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.definition});

  final Cosmetic? definition;

  @override
  Widget build(BuildContext context) {
    final assetPath = definition == null
        ? null
        : CosmeticsConfig.standard().resolveAssetPath(
            definition!.previewAssetKey ?? definition!.assetKey,
          );

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (assetPath != null)
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
              // `objectPosition: center 30%` in CSS → align horizontally
              // centered, vertically biased toward the top. Flutter's
              // Alignment(0, -0.4) maps roughly to "30% from the top".
              alignment: const Alignment(0, -0.4),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            const ColoredBox(color: Color(0xFF0A0E1C)),
          // Radial darken: pulls focus to the centre, dims edges.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 0.95,
                colors: [
                  Color(0x00000000),
                  Color(0x730A0E1C), // 0.45
                  Color(0xF20A0E1C), // 0.95
                ],
                stops: [0.0, 0.7, 1.0],
              ),
            ),
          ),
          // Vertical fade: dim top (status bar) and bottom (seam into
          // the rest of the profile page).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.22, 0.55, 1.0],
                colors: [
                  Color(0xF50A0E1C),// 0.5
                  Color(0x000A0E1C),
                  Color(0x000A0E1C),
                  Color(0xF50A0E1C), // 0.96
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// HeroBodyAvatar — full-body skin asset rendered against the scene.
// Replaces the pre-2026-05 framed pixel-art avatar; the frame border is
// reserved for compact thumbnail surfaces only (top app bar, social
// feed cards, settings header, ...).
// ─────────────────────────────────────────────────────────────────────

class _HeroBodyAvatar extends StatelessWidget {
  const _HeroBodyAvatar({
    required this.raceId,
    required this.skinId,
    required this.fallbackLabel,
    required this.size,
  });

  /// `HeroRace` id used to pick the asset subfolder. `null` when the
  /// player hasn't completed onboarding race-pick yet (or for a friend
  /// profile while the social wire format extension is still pending).
  final String? raceId;

  /// Equipped skin cosmetic id. The catalog row's `assetKey` is the
  /// race-agnostic template; the resolver composes it with the race
  /// folder to land on a concrete file.
  final String? skinId;

  /// Player-facing label used in the silhouette placeholder fallback
  /// (pre-asset / unresolved race state). Typically the display name.
  final String fallbackLabel;

  final double size;

  static const _resolver = SkinAssetResolver();

  @override
  Widget build(BuildContext context) {
    // We only read the catalog row to fish out its asset key template
    // — the per-race path goes through `SkinAssetResolver`, not the
    // generic `CosmeticsConfig.resolveAssetPath`.
    final skinDef = skinId == null ? null : const CosmeticCatalog().byId(skinId!);
    final assetPath = _resolver.resolve(
      raceId: raceId,
      skinAssetKey: skinDef?.assetKey,
      variant: SkinAssetVariant.fullBody,
    );
    if (assetPath == null) {
      return _HeroSilhouette(label: fallbackLabel, size: size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        // Sharp pixel art — turn off bilinear sampling so the asset
        // upscales with crisp pixel edges. Matches the rendering style
        // used by companion standees in the same card.
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            _HeroSilhouette(label: fallbackLabel, size: size),
      ),
    );
  }
}

/// Styled placeholder rendered when no skin asset is resolvable (race
/// not picked yet, asset file not yet shipped). Sized for the hero
/// card's 200-px body slot — uses a person glyph + the display name as
/// a label so the placeholder reads as "your hero, art landing soon"
/// rather than "broken image".
class _HeroSilhouette extends StatelessWidget {
  const _HeroSilhouette({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: size * 0.55,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          if (size >= 100) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single-line `LVL N · TITLE` label tinted by the level's rarity
/// accent, with a soft same-colour glow behind the text. Replaces the
/// `LVL N ⚜ TITLE` inscription rendered below the avatar.
///
/// Pure typography — no pill chrome — so it sits inside the fantasy
/// aesthetic (wildwood frame, pixel-art avatar, painted scenes)
/// instead of looking like a modern app UI chip. Readability against
/// busy backgrounds comes from a four-pass shadow stack:
///
///   1. **Hard 1 px black drop** — gives the letters a carved /
///      engraved edge so they don't melt into the scene.
///   2. **Soft black drop** — body shadow that anchors the text to a
///      surface.
///   3. **Wide ambient black halo** — local vignette under the words;
///      darkens busy bg without looking like a backplate.
///   4. **Tight rarity glow** — rim light in the level's rarity
///      colour; small radius so it kisses the strokes rather than
///      bleeding outward.
///
/// The fleur ornament (`⚜`) replaces the prior middle-dot separator
/// for a heraldic feel that matches the cosmetic frame's tone.
class _LevelTitleLabel extends StatelessWidget {
  const _LevelTitleLabel({
    required this.level,
    required this.title,
    required this.accent,
  });

  final int level;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shadows = <Shadow>[
      // Hard one-pixel drop — "engraved letter" depth.
      const Shadow(
        color: Color(0xFF000000),
        blurRadius: 0,
        offset: Offset(0, 1),
      ),
      // Soft body shadow.
      const Shadow(
        color: Color(0xCC000000),
        blurRadius: 6,
        offset: Offset(0, 3),
      ),
      // Wide ambient vignette so the text creates its own pocket of
      // contrast without a hard pill outline.
      const Shadow(
        color: Color(0x66000000),
        blurRadius: 18,
      ),
      // Tight rarity rim glow last, so the colour reads as a
      // kiss-light on the strokes rather than a foggy halo.
      Shadow(
        color: accent.withValues(alpha: 0.55),
        blurRadius: 3,
      ),
    ];

    // Inline eyebrow above the name — `LVL N ⚜ TITLE`. Typography
    // hierarchy splits the two: LVL is a bigger, brighter "stamp"
    // (white-tinted, heavier weight) while the title is the smaller
    // tracked label in the level's rarity colour. Mixed sizing keeps
    // it on one line without needing a backplate.
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: accent,
          height: 1.0,
          shadows: shadows,
        ),
        children: [
          TextSpan(
            text: 'LVL $level',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          TextSpan(
            text: '  ⚔  ',
            style: TextStyle(
              color: accent.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Identity block — name + handle + title pill.
// ─────────────────────────────────────────────────────────────────────

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.displayName,
    required this.handle,
    required this.level,
    required this.levelTitle,
    required this.levelAccent,
    required this.isMe,
    required this.onEditHandle,
    required this.friendCount,
    required this.onTapFriendChip,
  });

  final String displayName;
  final String handle;
  final int level;
  final String levelTitle;
  final Color levelAccent;
  final bool isMe;
  final VoidCallback? onEditHandle;
  final int? friendCount;
  final VoidCallback? onTapFriendChip;

  @override
  Widget build(BuildContext context) {
    const handleText = TextStyle(
      color: Color.fromARGB(255, 124, 122, 136),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    final handleLabel = Text(
      '@$handle',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: handleText,
    );

    final Widget handleWidget;
    if (isMe && onEditHandle != null) {
      // When viewing your own profile, the handle is tappable and an
      // unobtrusive pencil icon clarifies that it's editable. Wrapped
      // in InkWell so the whole row is the hit target, not just the
      // tiny icon.
      handleWidget = InkWell(
        onTap: onEditHandle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: handleLabel),
              const SizedBox(width: 6),
              Icon(
                Icons.edit_rounded,
                size: 12,
                color: const Color.fromARGB(255, 124, 122, 136).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      );
    } else {
      handleWidget = handleLabel;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow kicker — RPG character-sheet pattern: rank/title
        // above the player's name. Kept small + tracked so it reads
        // as a tagline rather than competing with the name.
        _LevelTitleLabel(
          level: level,
          title: levelTitle,
          accent: levelAccent,
        ),
        const SizedBox(height: 4),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF5F3FF),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.52, // -0.02em ≈ 26 * -0.02
            height: 1.05,
            shadows: [
              Shadow(
                color: Color(0xA6000000), // rgba(0,0,0,0.65)
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        handleWidget,
        if (friendCount != null && onTapFriendChip != null) ...[
          const SizedBox(height: 8),
          _FriendsChip(
            count: friendCount!,
            onTap: onTapFriendChip!,
            label: context.l10n.socialProfileFriendsChipLabel,
          ),
        ],
      ],
    );
  }
}

/// Compact pill rendered under @handle in the hero card. Decentní
/// chrome — white-translucent, small icon — designed to read as a
/// secondary affordance, not compete with the player's display name
/// or level pill above it.
class _FriendsChip extends StatelessWidget {
  const _FriendsChip({
    required this.count,
    required this.onTap,
    required this.label,
  });

  final int count;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 12,
                  color: Color(0xCCFFFFFF),
                ),
                const SizedBox(width: 5),
                Text(
                  '$label · $count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xCCFFFFFF),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Companion standee — companion cosmetic + warm ground glow.
// ─────────────────────────────────────────────────────────────────────

class _CompanionStandee extends StatelessWidget {
  const _CompanionStandee({
    required this.definition,
    required this.size,
  });

  final Cosmetic definition;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = CosmeticsConfig.standard().resolveAssetPath(
      definition.previewAssetKey ?? definition.assetKey,
    );

    final image = SizedBox(
      width: size,
      height: size,
      child: assetPath == null
          ? const Icon(Icons.pets_rounded, size: 64, color: Colors.white24)
          : Image.asset(assetPath, fit: BoxFit.contain),
    );

    return CompanionFakeIdlePreview(
      width: size,
      height: size,
      enableGlow: false,
      floatDistance: 2.5,
      minScale: 0.995,
      maxScale: 1.012,
      child: image,
    );
  }
}

class _GroundGlow extends StatelessWidget {
  const _GroundGlow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: 14,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.6,
              colors: [
                const Color(0xFFF4C152).withValues(alpha: 0.45),
                const Color(0xFFF4C152).withValues(alpha: 0),
              ],
              stops: const [0.0, 0.7],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Emblem collection — 4·4·3 grid of slots. Slot 10 is the end-game slot.
// ─────────────────────────────────────────────────────────────────────

class _EmblemCollection extends StatelessWidget {
  const _EmblemCollection({
    required this.slots,
    required this.unlockedCount,
    required this.slotSize,
    required this.gap,
    required this.onTapSlot,
  });

  /// Per-slot emblem mapping; index = grid position 0..10. `null`
  /// entries render as either "empty unlocked slot" (if index <
  /// [unlockedCount]) or "locked dashed square" (if index >=
  /// [unlockedCount]).
  final List<Cosmetic?> slots;

  /// How many of the 11 slots are currently unlocked. Anything at or
  /// above this index always renders locked, even if the data passed
  /// in [slots] happens to have something there (defensive against
  /// stale local pins).
  final int unlockedCount;

  final double slotSize;
  final double gap;

  /// Tap callback fired with a slot's absolute grid index (0..10).
  /// Only forwarded to unlocked slots — locked dashed squares ignore
  /// the callback. Tapping an empty-but-unlocked slot also fires the
  /// callback (caller can open a picker for "pick what goes here").
  final void Function(int slotIndex)? onTapSlot;

  static const int _totalSlots = 11;
  // 3-col × 4-row layout (3+3+3+2 = 11). Switched from the legacy
  // 4·4·3 on 2026-05 to fit alongside the identity block in the new
  // top-right placement.
  static const List<int> _rowSizes = [3, 3, 3, 2];

  @override
  Widget build(BuildContext context) {
    final slotData = List<_SlotData>.generate(_totalSlots, (i) {
      final emblem = (i < slots.length && i < unlockedCount) ? slots[i] : null;
      return _SlotData(
        index: i,
        emblem: emblem,
        unlocked: i < unlockedCount,
        // Highlight whichever slot's emblem is the player's currently
        // equipped one — keeps the "primary" emblem visually distinct
        // even though every slot now belongs to the user.
        pinned: false,
        endGame: i == _totalSlots - 1,
      );
    });

    final rows = <List<_SlotData>>[];
    var cursor = 0;
    for (final rowSize in _rowSizes) {
      rows.add(slotData.sublist(cursor, cursor + rowSize));
      cursor += rowSize;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var ri = 0; ri < rows.length; ri++) ...[
          if (ri > 0) SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var si = 0; si < rows[ri].length; si++) ...[
                if (si > 0) SizedBox(width: gap),
                _EmblemSlot(
                  data: rows[ri][si],
                  size: slotSize,
                  onTap: rows[ri][si].unlocked && onTapSlot != null
                      ? () => onTapSlot!(rows[ri][si].index)
                      : null,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _SlotData {
  const _SlotData({
    required this.index,
    required this.emblem,
    required this.unlocked,
    required this.pinned,
    required this.endGame,
  });

  final int index;
  final Cosmetic? emblem;
  final bool unlocked;
  final bool pinned;
  final bool endGame;
}

class _EmblemSlot extends StatelessWidget {
  const _EmblemSlot({
    required this.data,
    required this.size,
    required this.onTap,
  });

  final _SlotData data;
  final double size;

  /// Only set when the slot is unlocked AND the parent supplied an
  /// `onTapSlot`. Null on locked / non-interactive slots so the dashed
  /// square doesn't suggest a tappable affordance.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final emblem = data.emblem;
    final Widget content;
    if (emblem != null) {
      final assetPath = CosmeticsConfig.standard().resolveAssetPath(
        emblem.previewAssetKey ?? emblem.assetKey,
      );
      // Per-slot glow keyed on the emblem's own rarity. A soft radial
      // gradient sits behind the emblem rather than a BoxShadow on the
      // square hit-target — the prior box-shadow setup tinted the full
      // slot rectangle, which read as a "coloured chequerboard". The
      // radial halo is centred on the emblem image and naturally
      // round, so adjacent slots blend rather than stack.
      final rarityColor = RarityPalette.forRarity(emblem.rarity).color;
      final haloAlpha = data.pinned ? 0.32 : 0.18;
      const topPadding = 8.0;
      content = SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Soft round halo — bleeds slightly past the slot bounds
            // so the rarity colour never aligns with the slot's
            // right/bottom edges.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        rarityColor.withValues(alpha: haloAlpha),
                        rarityColor.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            // Pinned emblems get a second tighter halo for a "lit up"
            // feel without resorting to a hard outline.
            if (data.pinned)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          rarityColor.withValues(alpha: 0.30),
                          rarityColor.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.45],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: topPadding),
              child: SizedBox(
                width: size,
                height: size - topPadding,
                child: assetPath == null
                    ? const Icon(
                        Icons.shield_moon_rounded,
                        color: Colors.white70,
                      )
                    : Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      );
    } else {
      // Empty slot — dashed dim square with a centre dot (or a faint
      // star glyph for the end-game slot). Empty-but-unlocked slots
      // still need the GestureDetector below so the owner can pin
      // something into them — without that wrap they'd be visually
      // present but tap-dead after a "Remove from slot" action.
      content = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0x17FFFFFF), // rgba(255,255,255,0.09)
            radius: 9,
            dashWidth: 3,
            dashGap: 3,
            strokeWidth: 1,
            fillColor: const Color(0x07FFFFFF), // rgba(255,255,255,0.025)
          ),
          child: Center(
            child: data.endGame
                ? CustomPaint(
                    size: Size(size * 0.45, size * 0.45),
                    painter: _StarGlyphPainter(
                      color: const Color(0x38FFFFFF), // rgba(255,255,255,0.22)
                    ),
                  )
                : data.unlocked
                    // Unlocked-but-empty slot: a subtle "+" glyph so
                    // the affordance reads as "tap to pin" instead of
                    // a decorative locked square.
                    ? Icon(
                        Icons.add_rounded,
                        size: size * 0.42,
                        color: Colors.white.withValues(alpha: 0.42),
                      )
                    : Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x2EFFFFFF), // rgba(255,255,255,0.18)
                        ),
                      ),
          ),
        ),
      );
    }

    // Wrap once at the top level so filled and empty branches share
    // the same hit target. `onTap == null` (locked slot) skips the
    // wrap so taps fall through to whatever sits underneath instead
    // of being silently swallowed by an opaque hit area.
    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

/// Paints a rounded rectangle with a dashed border + solid fill. Flutter
/// has no built-in dashed border on BoxDecoration so we draw it manually:
/// the rect is filled first, then the path's segments are stroked in
/// alternating dash / gap chunks.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
    required this.fillColor,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          strokePaint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.strokeWidth != strokeWidth ||
      old.fillColor != fillColor;
}

class _StarGlyphPainter extends CustomPainter {
  const _StarGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // 4-point star with concave waists, matching the SVG path in the
    // reference file: M 12 3 L 13.5 10.5 L 21 12 L 13.5 13.5 L 12 21
    // L 10.5 13.5 L 3 12 L 10.5 10.5 Z (in a 24×24 viewBox).
    final s = size.width / 24;
    final path = Path()
      ..moveTo(12 * s, 3 * s)
      ..lineTo(13.5 * s, 10.5 * s)
      ..lineTo(21 * s, 12 * s)
      ..lineTo(13.5 * s, 13.5 * s)
      ..lineTo(12 * s, 21 * s)
      ..lineTo(10.5 * s, 13.5 * s)
      ..lineTo(3 * s, 12 * s)
      ..lineTo(10.5 * s, 10.5 * s)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarGlyphPainter old) => old.color != color;
}

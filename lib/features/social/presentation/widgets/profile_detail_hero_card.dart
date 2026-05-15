import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/companion_fake_idle_preview.dart';
import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../progression_engine/domain/policy/level_policy.dart';
import '../../domain/social_models.dart';
import 'social_avatar.dart';
import 'social_cosmetic_avatar.dart'
    show socialBackgroundDefinition, socialCosmeticById, socialFrameDefinition;

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
    required this.photoUrl,
    required this.profile,
    required this.isMe,
    this.emblemSlots = const <CosmeticDefinition?>[],
    this.unlockedCount = 0,
    this.onTapEmblemSlot,
    this.onEditPhoto,
    this.onEditHandle,
    this.photoBusy = false,
  });

  final String displayName;
  final String handle;
  final String? photoUrl;
  final SocialUserProfile? profile;
  final bool isMe;

  /// Per-slot emblem mapping. Length should match `slotCount` (11) —
  /// each entry is either the emblem pinned in that slot, or null for
  /// "empty slot". Slots beyond `unlockedCount - 1` render as locked
  /// dashed squares even if they happen to hold an emblem in the data
  /// (defensive against stale local pins after a slot-count change).
  final List<CosmeticDefinition?> emblemSlots;

  /// How many of the 11 grid slots are unlocked — capped by how many
  /// distinct emblems the user has earned. Slots beyond this index
  /// render locked regardless of [emblemSlots] contents.
  final int unlockedCount;

  /// Tap callback fired with the slot index (0..10). Only unlocked
  /// slots are tappable — the call site decides what to do (e.g. open
  /// a picker, route to the cosmetics screen). Slots above
  /// `unlockedEmblems.length - 1` swallow the tap silently.
  final void Function(int slotIndex)? onTapEmblemSlot;

  final VoidCallback? onEditPhoto;
  final VoidCallback? onEditHandle;
  final bool photoBusy;

  /// Total emblem slots in the collection grid. Mirrors
  /// `PinnedEmblemsStore.slotCount` so the data model and the visual
  /// grid stay aligned.
  static const int kEmblemSlotCount = 11;

  // Resolves what each of the 11 grid slots actually shows.
  //
  // * Own profile: caller passes `emblemSlots` (length 11) from the
  //   PinnedEmblemsStore — that's the source of truth.
  // * Friend profile: caller has no slot map, so we fabricate one
  //   from the single `equipped.emblemId` so slot 0 shows their
  //   current emblem and the rest stay locked.
  List<CosmeticDefinition?> _resolveSlots(CosmeticDefinition? equipped) {
    if (emblemSlots.length == kEmblemSlotCount) return emblemSlots;
    return <CosmeticDefinition?>[
      equipped,
      for (var i = 1; i < kEmblemSlotCount; i++) null,
    ];
  }

  int _resolveUnlockedCount(CosmeticDefinition? equipped) {
    if (unlockedCount > 0) return unlockedCount;
    return equipped == null ? 0 : 1;
  }

  // ── Design-spec sizing ─────────────────────────────────────────────────────
  static const double _kHeight = 400;
  static const double _kAvatarSize = 140;
  static const double _kAvatarLeft = 16;
  static const double _kAvatarTop = 16;
  static const double _kIdentityLeft = 172;
  static const double _kIdentityTop = 24;
  static const double _kCompanionSize = 134;
  static const double _kCompanionRight = 6;
  static const double _kCompanionBottom = 14;
  static const double _kEmblemSlotSize = 52;
  static const double _kEmblemGap = 6;
  static const double _kEdge = 16;

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats;
    final equipped = profile?.equippedCosmetics;
    final frame = socialFrameDefinition(equipped?.frameId);
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
          // Avatar block — tilted frame + pixel-art photo. The LVL/title
          // label sits as a separate Positioned below so its width is
          // free to extend past the avatar's 140 px without overflowing
          // the screen edge (the rotated SizedBox would crop or push
          // long titles off-screen).
          Positioned(
            left: _kAvatarLeft,
            top: _kAvatarTop,
            child: _FramedAvatar(
              size: _kAvatarSize,
              tiltDegrees: -3,
              displayName: displayName,
              photoUrl: photoUrl,
              frame: frame,
            ),
          ),
          // Camera edit button — owner-only, hidden in friend's view.
          // Sits near the bottom-right corner of the avatar (a few px
          // higher than flush with the corner so it overlaps the frame
          // less aggressively) and uses a quieter translucent chrome —
          // no purple accent halo.
          if (isMe && onEditPhoto != null)
            Positioned(
              left: 130,
              top: 124,
              child: _CameraEditButton(
                onTap: onEditPhoto!,
                busy: photoBusy,
              ),
            ),
          // Identity block — name + handle right of avatar (title pill
          // moved under the LVL pin so the level/title pair travels with
          // the avatar visually).
          Positioned(
            left: _kIdentityLeft,
            top: _kIdentityTop,
            right: _kEdge,
            child: _IdentityBlock(
              displayName: displayName,
              handle: handle,
              level: resolved.level,
              levelTitle: levelTitle,
              levelAccent: levelAccent,
              isMe: isMe,
              onEditHandle: onEditHandle,
            ),
          ),
          // Companion standee — warm radial glow on the ground + asset on
          // top. Centered roughly at right:6 / bottom:14 per the spec.
          if (companion != null) ...[
            const Positioned(
              right: 20,
              bottom: 10,
              child: _GroundGlow(width: 120),
            ),
            Positioned(
              right: _kCompanionRight,
              bottom: _kCompanionBottom,
              child: _CompanionStandee(
                definition: companion,
                size: _kCompanionSize,
              ),
            ),
          ],
          // Emblem collection — 4·4·3 grid, bottom-left. Per-slot
          // mapping from the caller drives what (if anything) sits in
          // each slot. Friend profiles fall back to a single-slot view
          // of their currently equipped emblem (we don't have their
          // unlocked catalogue or pinning state).
          Positioned(
            left: _kEdge,
            bottom: _kEdge,
            child: _EmblemCollection(
              slots: _resolveSlots(emblem),
              unlockedCount: _resolveUnlockedCount(emblem),
              slotSize: _kEmblemSlotSize,
              gap: _kEmblemGap,
              onTapSlot: onTapEmblemSlot,
            ),
          ),
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

  final CosmeticDefinition? definition;

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
// FramedAvatar — pixel-art avatar inset inside a tilted decorative frame,
// with a neutral-gray `LVL N` pin counter-rotated at the bottom-centre.
// ─────────────────────────────────────────────────────────────────────

class _FramedAvatar extends StatelessWidget {
  const _FramedAvatar({
    required this.size,
    required this.tiltDegrees,
    required this.displayName,
    required this.photoUrl,
    required this.frame,
  });

  final double size;
  final double tiltDegrees;
  final String displayName;
  final String? photoUrl;
  final CosmeticDefinition? frame;

  @override
  Widget build(BuildContext context) {
    final inset = (size * 0.10).roundToDouble();
    final innerSize = size - inset * 2;
    final framePath = frame == null
        ? null
        : CosmeticsConfig.standard().resolveAssetPath(
            frame!.previewAssetKey ?? frame!.assetKey,
          );
    // Soft glow in the frame's rarity colour — doubles as a halo that
    // visually anti-aliases the sharp PNG edges into the background.
    // Skipped when no frame is equipped (nothing to colour-key off of).
    final rarityGlow = frame == null
        ? null
        : RarityPalette.forRarity(frame!.rarity).color;

    return Transform.rotate(
      angle: tiltDegrees * math.pi / 180,
      // Without filterQuality, Flutter applies the rotation directly to
      // the raster grid → diagonal pixel staircases on the frame artwork.
      // FilterQuality.high routes the rotated subtree through a SaveLayer
      // with image-filter sampling, so the frame edges anti-alias smoothly.
      filterQuality: FilterQuality.high,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Drop shadow + rarity halo on the avatar block. Both are
            // outward BoxShadows on an empty transparent Container, so
            // they render outside its bounds without painting a body.
            Positioned(
              left: 0,
              top: 0,
              width: size,
              height: size,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    if (rarityGlow != null)
                      BoxShadow(
                        color: rarityGlow.withValues(alpha: 0.30),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    const BoxShadow(
                      color: Color(0x8C000000), // rgba(0,0,0,0.55)
                      blurRadius: 20,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
              ),
            ),
            // Pixel-art photo, inset so the frame visually surrounds it.
            Positioned(
              left: inset,
              top: inset,
              width: innerSize,
              height: innerSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SocialAvatar(
                  name: displayName,
                  size: innerSize,
                  photoUrl: photoUrl,
                  radius: 6,
                ),
              ),
            ),
            // Decorative frame artwork on top, full size.
            if (framePath != null)
              Positioned(
                left: 0,
                top: 0,
                width: size,
                height: size,
                child: Image.asset(
                  framePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
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
// Camera edit button — only rendered when viewing your own profile.
// ─────────────────────────────────────────────────────────────────────

class _CameraEditButton extends StatelessWidget {
  const _CameraEditButton({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            // Translucent dark chrome — reads as an affordance over the
            // avatar without competing with the rarity-coloured glow.
            color: const Color(0xCC0A0E1C),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1,
            ),
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(5),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.photo_camera_rounded,
                  size: 14,
                  color: Color(0xCCFFFFFF),
                ),
        ),
      ),
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
  });

  final String displayName;
  final String handle;
  final int level;
  final String levelTitle;
  final Color levelAccent;
  final bool isMe;
  final VoidCallback? onEditHandle;

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
      ],
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

  final CosmeticDefinition definition;
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
  final List<CosmeticDefinition?> slots;

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
  static const List<int> _rowSizes = [4, 4, 3];

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
  final CosmeticDefinition? emblem;
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
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
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
        ),
      );
    }

    // Locked slot — dashed dim square with a centre dot (or a faint
    // star glyph for the end-game slot).
    return SizedBox(
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

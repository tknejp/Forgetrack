import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/application/food_trigger_provider.dart';
import '../../../cosmetics/application/food_trigger_service.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/companion_buff_chip.dart';
import '../../../cosmetics/presentation/widgets/companion_fake_idle_preview.dart';
import '../../../cosmetics/presentation/widgets/companion_food_trigger_pill.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_frame_preview.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/features/progression_engine/domain/progression_domain_chrome.dart';
import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../progression_engine/presentation/widgets/level_badge.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'social_avatar.dart';

/// Unified hero/progression header used across all top-level tabs.
///
/// Goals:
///   * Single widget across all tabs → no height swap during PageView swipes.
///   * Always shows: avatar, display name, muted `@handle`, level orb,
///     level title, XP bar, XP ratio.
///   * Tap on avatar → opens [SocialUserProfileSheet] (which owns editing
///     of photo + handle for the signed-in user).
///   * Tap on the rest of the header → toggles an expanded panel revealing
///     pending reward count, current streak and unlocked achievement count.
class HeroProgressionHeader extends StatefulWidget {
  const HeroProgressionHeader({
    super.key,
    this.barKey,
  });

  /// Optional key handed to the inner XP progress bar so the celebration
  /// overlay can target it from outside the widget tree.
  final GlobalKey? barKey;

  @override
  State<HeroProgressionHeader> createState() => _HeroProgressionHeaderState();
}

class _HeroProgressionHeaderState extends State<HeroProgressionHeader> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final social = context.watch<SocialProvider>();
    final uid = social.currentUid ?? auth.user?.id;

    if (!auth.isSignedIn || uid == null) {
      return _HeaderFrame(
        child: Row(
          children: [
            const _SignedOutAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.l10n.profileNotSignedIn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Tokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _HeaderActionIcon(
              icon: Icons.login_rounded,
              tooltip: context.l10n.profileContinueWithGoogle,
              onTap: auth.isBusy ? null : () => auth.signIn(),
            ),
          ],
        ),
      );
    }

    final fallbackHandle = buildDefaultSocialHandle(
      uid: uid,
      email: auth.user?.email ?? '',
      displayName: auth.user?.displayName,
    );

    final stream = social.backendReady && social.isReady
        ? social.watchProfileById(uid)
        : Stream<SocialUserProfile?>.value(null);

    return StreamBuilder<SocialUserProfile?>(
      stream: stream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = _firstNonEmpty([
          profile?.displayName,
          auth.user?.displayName,
          auth.user?.email,
          'Forgetrack',
        ]);
        final handle = _firstNonEmpty([
          profile?.handle,
          fallbackHandle,
        ]);
        final photoUrl =
            _clean(profile?.photoUrl) ?? _clean(auth.user?.photoUrl);

        final cosmetics = context.watch<CosmeticsProvider>();
        final equippedFrame = _resolveEquippedFrame(cosmetics);
        final equippedBackground = _resolveEquippedBackground(cosmetics);
        final equippedCompanion = _resolveEquippedCompanion(cosmetics);
        // Own race + skin come straight from CosmeticsProvider — the
        // hero header is always the signed-in player's, so we don't
        // need to wait for the Firestore profile to round-trip.
        final raceId = cosmetics.currentRaceId;
        final skinId = cosmetics.state?.equipped.skinId;
        // Subscribed so the gold dot / claim pill repaint when the
        // calorie log changes or the player completes a claim. The
        // provider returns null while still hydrating from prefs —
        // _HeaderBody treats that as "nothing to show", same as a
        // zero-claimable snapshot.
        final foodTrigger = context.watch<FoodTriggerProvider>();
        final foodSnapshot = foodTrigger.currentSnapshot;

        return _HeaderBody(
          displayName: displayName,
          handle: handle,
          photoUrl: photoUrl,
          raceId: raceId,
          skinId: skinId,
          equippedFrame: equippedFrame,
          equippedBackground: equippedBackground,
          equippedCompanion: equippedCompanion,
          foodTriggerSnapshot: foodSnapshot,
          foodTriggerBusy: foodTrigger.isClaiming,
          onClaimFoodTrigger: () => foodTrigger.claim(),
          expanded: _expanded,
          onToggleExpanded: _toggle,
          onOpenProfile: () => openUserProfile(
            context,
            uid: uid,
            initialDisplayName: displayName,
            initialPhotoUrl: photoUrl,
          ),
          barKey: widget.barKey,
        );
      },
    );
  }
}

class _HeaderBody extends StatelessWidget {
  const _HeaderBody({
    required this.displayName,
    required this.handle,
    required this.photoUrl,
    required this.raceId,
    required this.skinId,
    required this.equippedFrame,
    required this.equippedBackground,
    required this.equippedCompanion,
    required this.foodTriggerSnapshot,
    required this.foodTriggerBusy,
    required this.onClaimFoodTrigger,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onOpenProfile,
    required this.barKey,
  });

  final String displayName;
  final String handle;
  final String? photoUrl;
  final String? raceId;
  final String? skinId;
  final Cosmetic? equippedFrame;
  final Cosmetic? equippedBackground;
  final Cosmetic? equippedCompanion;
  final FoodTriggerSnapshot? foodTriggerSnapshot;
  final bool foodTriggerBusy;
  final VoidCallback onClaimFoodTrigger;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onOpenProfile;
  final GlobalKey? barKey;

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionEngineProvider>();
    final profile = progression.profile;
    final levelDisplay =
        const ProgressionDisplayResolver().levelDisplay(profile.level);
    final levelTitle = levelDisplay.title(context.l10n);
    final levelAccent = levelDisplay.accentColor;
    final xpSpan =
        (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30);
    final xpProgress = (profile.xpIntoLevel / xpSpan).clamp(0.0, 1.0);

    final dailyQuests = progression.currentDailyQuests.take(3).toList();
    // Bars only need to leave room for the companion sprite when one is
    // actually equipped; without a companion the corner is empty and the
    // bars can run full-width.
    final reservedRight =
        equippedCompanion == null ? 0.0 : _kCompanionReservedWidth;

    return _HeaderFrame(
      backgroundDefinition: equippedBackground,
      onTap: onToggleExpanded,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (equippedCompanion != null)
            Positioned(
              right: -16,
              bottom: -22,
              child: IgnorePointer(
                child: CompanionFakeIdlePreview(
                  width: _kCompanionSlot,
                  height: _kCompanionSlot,
                  enableGlow: false,
                  floatDistance: 2.5,
                  minScale: 0.995,
                  maxScale: 1.012,
                  // Render the raw 512² companion canvas at full slot
                  // size instead of routing through `CompanionAsset` —
                  // the latter scales past the empty foot pad to keep
                  // small surfaces compact, which clips antlers + feet
                  // here. The hero card has room for the full sprite,
                  // and the slot's `bottom: -22` deliberately bleeds
                  // the foot pad off the card so the silhouette reads
                  // as resting against the bottom edge.
                  child: _HeroHeaderCompanion(
                    definition: equippedCompanion!,
                    size: _kCompanionSlot,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onToggleExpanded,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Collapsed-only gold dot hint that a claim is
                    // waiting. Hidden the moment the header is
                    // expanded — the claim pill below carries the
                    // affordance from there.
                    if (!expanded &&
                        foodTriggerSnapshot?.hasClaimable == true) ...[
                      const CompanionFoodTriggerDot(),
                      const SizedBox(width: 4),
                    ],
                    ExpandChevron(
                      expanded: expanded,
                      color: Colors.white.withValues(alpha: 0.72),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IdentityRow(
                displayName: displayName,
                handle: handle,
                photoUrl: photoUrl,
                raceId: raceId,
                skinId: skinId,
                equippedFrame: equippedFrame,
                onTapAvatar: onOpenProfile,
              ),
              const SizedBox(height: 12),
              _ProgressionRow(
                level: profile.level,
                levelTitle: levelTitle.toUpperCase(),
                levelAccent: levelAccent,
                xpInto: profile.xpIntoLevel,
                xpMax: xpSpan,
                xpProgress: xpProgress,
                barKey: barKey,
                reservedRight: reservedRight,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child: child,
                    ),
                  );
                },
                child: expanded
                    ? Padding(
                        key: const ValueKey('hero-header-expanded'),
                        padding: EdgeInsets.only(
                          top: 12,
                          right: reservedRight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((equippedCompanion is Companion &&
                                    (equippedCompanion as Companion)
                                            .buff !=
                                        null) ||
                                foodTriggerSnapshot?.hasClaimable ==
                                    true ||
                                (foodTriggerSnapshot?.alreadyClaimedXp ??
                                        0) >
                                    0) ...[
                              // Buff chip + (optional) food-trigger
                              // pill on a single row. The trigger
                              // pill is a thin wrapper over
                              // XpClaimPill — it flips between the
                              // claimable +XP state and the muted
                              // check-circle claimed state from the
                              // same snapshot, matching the pill
                              // chrome used on quest / chapter /
                              // long-term cards. Locked state stays
                              // invisible. Wrap so a long buff copy
                              // on a narrow device pushes the pill
                              // onto the next line instead of
                              // overflowing.
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                children: [
                                  if (equippedCompanion is Companion &&
                                      (equippedCompanion as Companion)
                                              .buff !=
                                          null)
                                    CompanionBuffChip(
                                      buff: (equippedCompanion
                                              as Companion)
                                          .buff!,
                                      color: RarityPalette.forRarity(
                                        equippedCompanion!.rarity,
                                      ).color,
                                      compact: true,
                                    ),
                                  if (foodTriggerSnapshot != null &&
                                      (foodTriggerSnapshot!
                                                  .claimableXp >
                                              0 ||
                                          foodTriggerSnapshot!
                                                  .alreadyClaimedXp >
                                              0))
                                    CompanionFoodTriggerPill(
                                      snapshot: foodTriggerSnapshot!,
                                      // Sparkle flies to the same XP
                                      // bar the rest of the screen
                                      // claims target. barKey may be
                                      // null on auth-locked / loading
                                      // states where the bar is not
                                      // mounted — the pill silently
                                      // skips the launch then.
                                      sparkleTargetKey: barKey,
                                      isBusy: foodTriggerBusy,
                                      onClaim: onClaimFoodTrigger,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                            _DailyQuestsPreview(quests: dailyQuests),
                          ],
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('hero-header-collapsed'),
                        width: double.infinity,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.displayName,
    required this.handle,
    required this.photoUrl,
    required this.raceId,
    required this.skinId,
    required this.equippedFrame,
    required this.onTapAvatar,
  });

  final String displayName;
  final String handle;
  final String? photoUrl;
  final String? raceId;
  final String? skinId;
  final Cosmetic? equippedFrame;
  final VoidCallback onTapAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTapAvatar,
          behavior: HitTestBehavior.opaque,
          child: CosmeticFramePreview(
            definition: equippedFrame,
            size: 64,
            borderRadius: BorderRadius.circular(20),
            frameOverscan: 1.16,
            child: SocialAvatar(
              name: displayName,
              size: 64,
              raceId: raceId,
              skinId: skinId,
              photoUrl: photoUrl,
              radius: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Tokens.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '@$handle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: Tokens.fontSizeCaption,
                  color: Tokens.onSurfaceFaint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressionRow extends StatelessWidget {
  const _ProgressionRow({
    required this.level,
    required this.levelTitle,
    required this.levelAccent,
    required this.xpInto,
    required this.xpMax,
    required this.xpProgress,
    required this.barKey,
    required this.reservedRight,
  });

  final int level;
  final String levelTitle;
  final Color levelAccent;
  final int xpInto;
  final int xpMax;
  final double xpProgress;
  final GlobalKey? barKey;

  /// Right-side gutter the bar + label must avoid — set to the companion
  /// reserved width when one is equipped, 0 otherwise so the bar runs
  /// full-width and the section feels right with an empty corner.
  final double reservedRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LevelBadge(level: level, accentColor: levelAccent, size: 36),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: Padding(
            // Reserve right-side room for the companion asset bled into
            // the card's bottom-right corner (see `_HeaderBody`). Without
            // this, the XP bar runs underneath the companion sprite. The
            // gutter collapses to 0 when no companion is equipped.
            padding: EdgeInsets.only(right: reservedRight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  levelTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w900,
                    color: levelAccent,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  key: barKey,
                  child: ProgressBar(
                    value: xpProgress,
                    color: Tokens.xp,
                    glow: Tokens.xpGlow,
                    height: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.progBadgeXpRange(xpInto, xpMax),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    color: Color(0xA8FFFFFF),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Display side of the companion sprite slot inside the hero header. The
/// slot is intentionally larger than the silhouette's visual footprint
/// — the raw 512² canvas carries antlers near its top edge and ~48 px
/// of empty pad below the feet, so the slot needs headroom to show
/// both. `right`/`bottom` overhang values pair with this size to bleed
/// the foot pad off the card while keeping antlers in view.
const double _kCompanionSlot = 150;

/// Right-side gutter under the companion sprite that bars + quest rows
/// must avoid. Math: slot is `_kCompanionSlot` wide with `right: -16`
/// offset, so its visible left edge sits ~154 px from the content's
/// right edge; the silhouette itself fills the centre ~100 px of the
/// slot, so its true left edge lands ~110 px from the right. Round up
/// to 130 for a small breathing gap before the XP bar.
const double _kCompanionReservedWidth = 110;

class _DailyQuestsPreview extends StatelessWidget {
  const _DailyQuestsPreview({required this.quests});

  final List<EngineQuestProgress> quests;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.progQuestsDailyTasksHeader.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: Tokens.onSurfaceFaint,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 2),
        if (quests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              l10n.progQuestsDailyTasksHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: Tokens.onSurfaceFaint,
              ),
            ),
          )
        else
          for (int i = 0; i < quests.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            _MiniQuestRow(quest: quests[i]),
          ],
      ],
    );
  }
}

class _MiniQuestRow extends StatelessWidget {
  const _MiniQuestRow({required this.quest});

  final EngineQuestProgress quest;

  @override
  Widget build(BuildContext context) {
    final domain = quest.domain ?? ProgressionDomain.activity;
    final color = domain.color;
    final rawPct = quest.progress * 100;
    final pct =
        (rawPct.isNaN || rawPct.isInfinite) ? 0 : rawPct.clamp(0, 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _QuestThumb(asset: quest.node.assetKey, domain: domain, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.node.titleKey(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  value: quest.progress,
                  color: color,
                  glow: color.withValues(alpha: 0.28),
                  height: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            quest.isAvailableForClaim ? '✓' : '$pct%',
            style: TextStyle(
              fontSize: Tokens.fontSizeCaption,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a cosmetic's preview asset as a plain image with no chrome —
/// used for companion + emblem on hero/profile cards. Falls back to a
/// type-appropriate icon when the asset is missing or fails to decode.
class CompanionAsset extends StatelessWidget {
  const CompanionAsset({
    super.key,
    required this.definition,
    required this.size,
    this.fallbackIcon = Icons.pets_rounded,
  });

  final Cosmetic definition;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final assetPath = CosmeticsConfig.standard().resolveAssetPath(
      definition.previewAssetKey ?? definition.assetKey,
    );

    Widget fallback() => Icon(
          fallbackIcon,
          size: size * 0.5,
          color: Tokens.accent,
        );

    if (assetPath == null) {
      return SizedBox(width: size, height: size, child: Center(child: fallback()));
    }
    // Use the catalog row's per-asset `displayScale` so each
    // companion reads at a comparable visual size in this small
    // surface — tiny silhouettes (ember sprite) zoom up, wide ones
    // (mountain gryphon) render closer to raw. Below-centre anchor
    // matches the other companion previews (forging, morph, details,
    // grid tiles) so a companion seen in two surfaces side-by-side
    // lines up vertically. Falls back to 1.0 for non-Companion
    // cosmetics that happen to pass through here.
    final scale =
        definition is Companion ? (definition as Companion).displayScale : 1.0;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: const Alignment(0, 0.5),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(child: fallback()),
          ),
        ),
      ),
    );
  }
}

/// Hero-header-specific companion renderer that paints the raw 512²
/// asset at full slot size, bypassing the `kCompanionAssetContentScale`
/// crop used on small surfaces. The hero header has enough room for
/// the full canvas (antlers, body, foot pad) and relies on the slot's
/// negative `bottom` offset to bleed the empty foot pad off the card
/// — the standard cropped renderer instead truncates both antlers and
/// feet when the slot is this small.
class _HeroHeaderCompanion extends StatelessWidget {
  const _HeroHeaderCompanion({
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
    if (assetPath == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            Icons.pets_rounded,
            size: size * 0.4,
            color: Tokens.accent,
          ),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.pets_rounded,
          size: size * 0.4,
          color: Tokens.accent,
        ),
      ),
    );
  }
}

class _QuestThumb extends StatelessWidget {
  const _QuestThumb({
    required this.asset,
    required this.domain,
    required this.size,
  });

  final String? asset;
  final ProgressionDomain domain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = domain.color;
    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Icon(
          domain.icon,
          color: color,
          size: size * 0.55,
        ),
      );
    }

    final key = asset;
    if (key == null || key.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.asset(
        key,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }
}

class _HeaderFrame extends StatelessWidget {
  const _HeaderFrame({
    required this.child,
    this.backgroundDefinition,
    this.onTap,
  });

  final Widget child;
  final Cosmetic? backgroundDefinition;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundPath = CosmeticsConfig.standard().resolveAssetPath(
      backgroundDefinition?.previewAssetKey ?? backgroundDefinition?.assetKey,
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Tokens.bg,
          borderRadius: BorderRadius.circular(Tokens.radiusCard),
          boxShadow: const [
            BoxShadow(
              color: Color(0x267C6FFF),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.9, -1),
              end: Alignment(1, 1),
              colors: [
                Color(0x267C6FFF),
                Color(0x0B31E6D2),
                Color(0x087C6FFF),
              ],
            ),
            image: backgroundPath == null
                ? null
                : DecorationImage(
                    image: AssetImage(backgroundPath),
                    fit: BoxFit.cover,
                    opacity: 0.62,
                  ),
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            border: Border.all(color: Tokens.accent.withValues(alpha: 0.30)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.065),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? Tokens.onSurfaceFaint : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SignedOutAvatar extends StatelessWidget {
  const _SignedOutAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Tokens.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.28)),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: Tokens.accent,
        size: 26,
      ),
    );
  }
}

Cosmetic? _resolveEquippedFrame(CosmeticsProvider cosmetics) {
  final state = cosmetics.state;
  if (state == null) return null;
  final catalog = cosmetics.service.catalog;

  final equippedId = state.equipped.frameId;
  if (equippedId != null) {
    final def = catalog.byId(equippedId);
    if (def != null && def.isEnabled) return def;
  }

  const fallbackId = 'frame_pilgrim';
  if (state.unlocked.containsKey(fallbackId)) {
    final def = catalog.byId(fallbackId);
    if (def != null && def.isEnabled) return def;
  }
  return null;
}

Cosmetic? _resolveEquippedCompanion(CosmeticsProvider cosmetics) {
  final state = cosmetics.state;
  if (state == null) return null;
  final catalog = cosmetics.service.catalog;
  final equippedId = state.equipped.companionId;
  if (equippedId == null) return null;
  final def = catalog.byId(equippedId);
  if (def == null || !def.isEnabled) return null;
  return def;
}

Cosmetic? _resolveEquippedBackground(CosmeticsProvider cosmetics) {
  final state = cosmetics.state;
  if (state == null) return null;
  final catalog = cosmetics.service.catalog;

  final equippedId = state.equipped.backgroundId;
  if (equippedId != null) {
    final def = catalog.byId(equippedId);
    if (def != null && def.isEnabled) return def;
  }

  const fallbackId = 'background_camp';
  if (state.unlocked.containsKey(fallbackId)) {
    final def = catalog.byId(fallbackId);
    if (def != null && def.isEnabled) return def;
  }
  return null;
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

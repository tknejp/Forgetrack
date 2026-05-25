import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../progression_engine/domain/display/progression_display_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_back_button.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/application/emblem_board_provider.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/cosmetics_inventory_section.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'companion_slot_sheet.dart';
import 'emblem_slot_sheet.dart';
import 'profile_detail_hero_card.dart';
import 'profile_stats_section.dart';
import 'skin_slot_sheet.dart';
import 'social_cosmetic_avatar.dart';
import 'social_edit_handle_sheet.dart';
import 'social_feed_card.dart';
import 'social_profile_achievement_grid.dart';
import 'social_profile_friends_section.dart';

class SocialUserProfileScreen extends StatefulWidget {
  const SocialUserProfileScreen({
    super.key,
    required this.uid,
    this.initialDisplayName,
    this.initialPhotoUrl,
  });

  final String uid;
  final String? initialDisplayName;
  final String? initialPhotoUrl;

  @override
  State<SocialUserProfileScreen> createState() =>
      _SocialUserProfileScreenState();
}

class _SocialUserProfileScreenState extends State<SocialUserProfileScreen> {
  late final Stream<SocialUserProfile?> _profileStream;
  late final Stream<List<SocialUnlockedAchievement>> _achievementsStream;
  late final Stream<List<SocialAchievementShare>> _sharesStream;
  late final Stream<List<SocialUserProfile>> _friendsStream;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    final social = context.read<SocialProvider>();
    _profileStream = social.watchProfileById(widget.uid);
    _achievementsStream = social.watchFriendAchievements(widget.uid);
    _sharesStream = social.watchProfileShares(widget.uid);
    _friendsStream = social.watchFriendProfilesForUser(widget.uid);
  }

  Future<void> _editOwnHandle(String currentHandle) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditHandleSheet(initialHandle: currentHandle),
    );

    if (next == null || !mounted) return;
    final social = context.read<SocialProvider>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final savedHandle = await social.updateCurrentHandle(next);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          savedHandle == null
              ? l10n.socialHandleSaveFailed(
                  social.error ?? l10n.socialTryAgain,
                )
              : l10n.socialHandleSaved(savedHandle),
        ),
      ),
    );
  }

  /// Returns the signed-in user's unlocked emblems sorted by unlock
  /// time (oldest first) so the collection grid fills left-to-right in
  /// the order the player earned them. Returns an empty list if not the
  /// own profile, or if cosmetics state hasn't loaded yet.
  List<Cosmetic> _ownUnlockedEmblems(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final state = cosmetics.state;
    if (state == null) return const <Cosmetic>[];

    final catalog = cosmetics.service.catalog;
    final unlocked = <Cosmetic>[];
    for (final def in catalog.byType(CosmeticType.emblem)) {
      if (!def.isEnabled) continue;
      if (state.unlocked.containsKey(def.id)) unlocked.add(def);
    }
    unlocked.sort((a, b) {
      final at = state.unlocked[a.id]!.unlockedAt;
      final bt = state.unlocked[b.id]!.unlockedAt;
      return at.compareTo(bt);
    });
    return unlocked;
  }

  /// Resolves the 11 grid slots → emblem definition map for the own
  /// profile. Combines:
  ///   * The user's saved pin layout (from [EmblemBoardProvider]) —
  ///     auto-filled from unlock order on first render.
  ///   * The unlocked emblem catalogue from [CosmeticsProvider].
  ///
  /// Stale pin ids (e.g. an emblem the user lost) collapse to null
  /// for that slot.
  List<Cosmetic?> _ownEmblemSlots(
    BuildContext context,
    List<Cosmetic> unlocked,
    String uid,
  ) {
    final board = context.watch<EmblemBoardProvider>().boardForUserOrAutoFill(
          uid,
          unlocked.map((def) => def.id).toList(growable: false),
        );
    final byId = {for (final def in unlocked) def.id: def};
    return [for (final id in board.slots) id == null ? null : byId[id]];
  }

  /// Opens the companion-slot management sheet for the equipped
  /// companion. The sheet lets the owner swap to any other unlocked
  /// companion or unequip the current one — both routed through the
  /// shared [CosmeticsProvider] equip / unequip API. No-ops when the
  /// inventory state hasn't loaded yet.
  Future<void> _openCompanionDetails(Cosmetic companion) async {
    final cosmetics = context.read<CosmeticsProvider>();
    final state = cosmetics.state;
    if (state == null) return;
    final unlockedCompanions = [
      for (final id in state.unlocked.keys)
        if (socialCosmeticById(id) case final def?
            when def.type == CosmeticType.companion)
          def,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final pick = await CompanionSlotSheet.show(
      context,
      current: companion,
      unlocked: unlockedCompanions,
    );
    if (pick == null || !mounted) return;
    if (pick.removed) {
      await cosmetics.unequip(CosmeticType.companion);
    } else if (pick.cosmeticId != null) {
      await cosmetics.equip(pick.cosmeticId!);
    }
  }

  /// Mirrors [_openCompanionDetails] for the skin slot. Tap on the
  /// avatar opens a manage sheet; the sheet's `equip` / `remove`
  /// result is routed through the same `CosmeticsProvider` API.
  /// No-op when the inventory state hasn't loaded yet — without it
  /// there's no race / unlock data to drive the picker.
  Future<void> _openSkinDetails(String? equippedSkinId) async {
    final cosmetics = context.read<CosmeticsProvider>();
    final state = cosmetics.state;
    if (state == null) return;
    final currentSkin =
        equippedSkinId == null ? null : socialCosmeticById(equippedSkinId);
    final unlockedSkins = [
      for (final id in state.unlocked.keys)
        if (socialCosmeticById(id) case final def?
            when def.type == CosmeticType.skin)
          def,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final pick = await SkinSlotSheet.show(
      context,
      current: currentSkin,
      unlocked: unlockedSkins,
      raceId: cosmetics.currentRaceId,
    );
    if (pick == null || !mounted) return;
    if (pick.removed) {
      await cosmetics.unequip(CosmeticType.skin);
    } else if (pick.cosmeticId != null) {
      await cosmetics.equip(pick.cosmeticId!);
    }
  }

  Future<void> _openEmblemSlotSheet({
    required int slotIndex,
    required bool isOwner,
    required String uid,
    required List<Cosmetic?> slots,
    required List<Cosmetic> unlocked,
  }) async {
    final current = slotIndex >= 0 && slotIndex < slots.length
        ? slots[slotIndex]
        : null;
    final result = await EmblemSlotSheet.show(
      context,
      slotIndex: slotIndex,
      currentEmblem: current,
      unlockedEmblems: unlocked,
      isOwner: isOwner,
    );
    if (result == null || !isOwner || !mounted) return;
    await context.read<EmblemBoardProvider>().setPin(
          uid: uid,
          slotIndex: result.slotIndex,
          cosmeticId: result.cosmeticId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final l10n = context.l10n;

    final isMe = social.currentUid == widget.uid;
    final ownUnlockedEmblems =
        isMe ? _ownUnlockedEmblems(context) : const <Cosmetic>[];

    return Scaffold(
      // Bg matches the hero header's fade-out target so the top/bottom
      // gradient lands on the same shade and there's no visible seam.
      backgroundColor: const Color(0xFF0A0E1C),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<SocialUserProfile?>(
          stream: _profileStream,
          builder: (context, profileSnap) {
            final profile = profileSnap.data;
            final displayName =
                profile?.displayName ?? widget.initialDisplayName ?? '';
            final handle = profile?.handle ?? '';
            // Slot mapping → cosmetic def. For friend profiles we
            // only know their single equipped emblem, so slot 0 shows
            // it and everything else is null.
            final emblemSlots = isMe
                ? _ownEmblemSlots(context, ownUnlockedEmblems, widget.uid)
                : <Cosmetic?>[
                    socialCosmeticById(
                        profile?.equippedCosmetics.emblemId),
                    for (var i = 1;
                        i < ProfileDetailHeroCard.kEmblemSlotCount;
                        i++)
                      null,
                  ];
            // The top app bar is rendered as a transparent overlay on
            // top of the hero header — the background scene shows
            // through under the status bar / back button, no chrome
            // strip cutting into the cinematic image.
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(top: 58, bottom: bottomPad + 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero header bleeds to the screen edges — the
                      // rest of the profile keeps the 16-px gutter.
                      // Wrapped in StreamBuilder so the "Přátelé · N"
                      // chip under @handle reflects the live friend
                      // count from the same stream the modal sheet
                      // opens onto.
                      StreamBuilder<List<SocialUserProfile>>(
                        stream: _friendsStream,
                        builder: (context, friendsSnap) {
                          final friendCount = friendsSnap.data?.length;
                          // For own profile the hero body reads
                          // race + equipped skin straight from the
                          // local cosmetics provider. Friend profiles
                          // have no race/skin payload on the wire
                          // format yet (extension lands in a follow-up)
                          // — they fall back to the silhouette.
                          final cosmeticsState = isMe
                              ? context.watch<CosmeticsProvider>()
                              : null;
                          return ProfileDetailHeroCard(
                            displayName: displayName,
                            handle: handle,
                            profile: profile,
                            isMe: isMe,
                            raceId: cosmeticsState?.currentRaceId,
                            skinId: cosmeticsState?.state?.equipped.skinId,
                            emblemSlots: emblemSlots,
                            onEditHandle:
                                isMe ? () => _editOwnHandle(handle) : null,
                            friendCount: friendCount,
                            // `_friendsStream` is single-subscription
                            // and already listened-to by this hero
                            // card's StreamBuilder for the chip count
                            // — handing the same instance to the sheet
                            // would silently fail to subscribe and the
                            // sheet would stick at "loading". Spin up
                            // a fresh stream for the sheet instead;
                            // the repository serves an independent
                            // Firestore snapshot listener per call.
                            onTapFriendChip: () =>
                                ProfileFriendsListSheet.show(
                              context,
                              stream: social
                                  .watchFriendProfilesForUser(widget.uid),
                            ),
                            // Friend profiles get read-only detail; the
                            // owner gets the full picker (equip / remove /
                            // swap). Locked slots ignore the tap.
                            onTapEmblemSlot: (slotIndex) =>
                                _openEmblemSlotSheet(
                              slotIndex: slotIndex,
                              isOwner: isMe,
                              uid: widget.uid,
                              slots: emblemSlots,
                              unlocked: ownUnlockedEmblems,
                            ),
                            // Tap on the companion standee → cosmetic
                            // details sheet (own profile only — friend
                            // profiles don't carry the local cosmetics
                            // state needed to render lifecycle / equip).
                            onTapCompanion: isMe
                                ? (c) => _openCompanionDetails(c)
                                : null,
                            // Tap on the hero body → skin slot sheet,
                            // same restriction as the companion tap.
                            onTapAvatar: isMe
                                ? (id) => _openSkinDetails(id)
                                : null,
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isMe) ...[
                              // Owner section order (2026-05-25 stats
                              // section landing): Inventář →
                              // Statistiky (subsumes Streak rekordy as
                              // one of its cards) → Připnuté
                              // achievementy → Sdílené příspěvky.
                              // Inventář sits above stats because users
                              // open the profile to manage cosmetics
                              // more often than to scan numbers.
                              const CosmeticsInventorySection(),
                              const SizedBox(height: Tokens.spaceLg),
                              _buildProfileStatsSection(
                                  profile, isMe: true),
                              const SizedBox(height: Tokens.spaceLg),
                            ] else ...[
                              // Foreign profile: pending request /
                              // add/remove-friend action sits above
                              // the stats section. Inventář is
                              // owner-only.
                              _buildActionArea(
                                  context, social, displayName),
                              const SizedBox(height: Tokens.spaceLg),
                              _buildProfileStatsSection(
                                  profile, isMe: false),
                              const SizedBox(height: Tokens.spaceLg),
                            ],
                            _SectionTitle(
                              icon: Icons.push_pin_rounded,
                              title:
                                  l10n.socialProfilePinnedAchievements,
                            ),
                            const SizedBox(height: 10),
                            _PinnedAchievementsSection(
                              profile: profile,
                              isMe: isMe,
                              stream: _achievementsStream,
                              l10n: l10n,
                            ),
                            const SizedBox(height: 18),
                            _SectionTitle(
                              icon: Icons.forum_rounded,
                              title: l10n.socialProfileSharedPosts,
                            ),
                            const SizedBox(height: 10),
                            _ProfileSharesSection(
                              stream: _sharesStream,
                              canDelete: isMe,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Top fade overlay — pure decoration behind the app
                // bar so the back button + display name read against
                // a darker band regardless of the hero scene under
                // them. Wrapped in IgnorePointer so it never eats
                // taps on the chrome above it.
                //
                // Scope limited to the app bar zone only: the band
                // behind the inline handle/friends subtitle row is
                // darkened by a separate fade INSIDE the hero card
                // (`profile_detail_hero_card.dart`), so the text
                // there sits in front of its darkener instead of
                // behind a screen-fixed overlay.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      // Status bar + ~56 chrome + ~14 pad below.
                      height: MediaQuery.of(context).padding.top + 70,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.65, 1.0],
                          colors: [
                            Color(0xE60A0E1C),
                            Color(0x990A0E1C),
                            Color(0x000A0E1C),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // App bar chrome — pure tap target, no own gradient
                // (handled by the overlay above).
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    child: ScreenHeader(
                      greeting: '',
                      // Show the player's display name in the app
                      // bar instead of the generic "Profil" label —
                      // the screen is always about a specific user,
                      // and the hero card already devotes its biggest
                      // text slot to the same name, so anchoring the
                      // bar to it ties the two surfaces together.
                      // Falls back to the screen label only while
                      // the profile stream hasn't produced a name
                      // yet, so the bar never sits empty.
                      title: displayName.isEmpty
                          ? l10n.screenProfile
                          : displayName,
                      leading: Navigator.of(context).canPop()
                          ? const FtBackButton()
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Renders the stat-visibility section under the streak card.
  ///
  /// Wraps the section in two nested StreamBuilders so the friend
  /// count + shared posts count come from the same live streams the
  /// rest of the profile screen already subscribes to (a fresh
  /// subscription per builder; the repository serves an independent
  /// snapshot listener per call so each StreamBuilder is fed
  /// regardless of how many other widgets watch the same data).
  Widget _buildProfileStatsSection(
    SocialUserProfile? profile, {
    required bool isMe,
  }) {
    final social = context.read<SocialProvider>();
    return StreamBuilder<List<SocialUserProfile>>(
      stream: social.watchFriendProfilesForUser(widget.uid),
      builder: (context, friendsSnap) {
        return StreamBuilder<List<SocialAchievementShare>>(
          stream: _sharesStream,
          builder: (context, sharesSnap) {
            return ProfileStatsSection(
              profile: profile,
              isMe: isMe,
              friendCount: friendsSnap.data?.length,
              sharedPostsCount: sharesSnap.data?.length,
            );
          },
        );
      },
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    SocialProvider social,
    String displayName,
  ) {
    final isFriend = social.isFriendWith(widget.uid);
    final hasPending = social.getPendingRequestTo(widget.uid) != null;

    if (isFriend) {
      return _RemoveFriendButton(
        name: displayName,
        onConfirm: () async {
          final nav = Navigator.of(context);
          await social.removeFriend(widget.uid);
          if (mounted) nav.pop();
        },
      );
    }
    if (hasPending) {
      return const _PendingRequestChip();
    }
    return _AddFriendButton(
      busy: _actionBusy,
      onTap: () async {
        setState(() => _actionBusy = true);
        await social.sendFriendRequest(widget.uid);
        if (mounted) setState(() => _actionBusy = false);
      },
    );
  }
}

// ── Action area widgets ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Tokens.accent),
        const SizedBox(width: Tokens.spaceSm),
        Text(
          title,
          style: const TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _PinnedAchievementsSection extends StatelessWidget {
  const _PinnedAchievementsSection({
    required this.profile,
    required this.isMe,
    required this.stream,
    required this.l10n,
  });

  final SocialUserProfile? profile;
  final bool isMe;
  final Stream<List<SocialUnlockedAchievement>> stream;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final pinnedIds = profile?.pinnedAchievementIds ?? const [];
    if (pinnedIds.isEmpty) {
      return _ProfileEmptyLine(
        text: isMe ? l10n.socialPinnedEmptyMine : l10n.socialPinnedEmptyOther,
      );
    }

    return StreamBuilder<List<SocialUnlockedAchievement>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _ProfileSectionLoader();
        }

        final displays = mapSocialAchievementsToDisplays(
          snap.data ?? const [],
          context.l10n,
        );
        final byId = {
          for (final display in displays) display.nodeId: display,
        };
        final pinned = <NodeDisplay>[];
        for (final id in pinnedIds) {
          final display = byId[id];
          if (display != null) pinned.add(display);
        }

        if (pinned.isEmpty) {
          return _ProfileEmptyLine(
            text: l10n.socialPinnedUnavailable,
          );
        }

        return FriendAchievementsGrid(
          achievements: pinned,
          l10n: l10n,
        );
      },
    );
  }
}

class _ProfileSharesSection extends StatelessWidget {
  const _ProfileSharesSection({
    required this.stream,
    required this.canDelete,
  });

  final Stream<List<SocialAchievementShare>> stream;

  /// True when the viewer owns this profile — wires a kebab menu into
  /// each share card so the owner can remove their own posts.
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SocialAchievementShare>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const _ProfileSectionLoader();
        }

        final shares = snap.data ?? const [];
        if (shares.isEmpty) {
          return _ProfileEmptyLine(
            text: context.l10n.socialSharedPostsEmpty,
          );
        }

        return Column(
          children: [
            for (final share in shares)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SocialFeedCard(
                  share: share,
                  onDelete: canDelete
                      ? () => _confirmAndDeleteShare(context, share)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndDeleteShare(
    BuildContext context,
    SocialAchievementShare share,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusButton),
        ),
        title: Text(
          l10n.socialSharedPostDeleteConfirmTitle,
          style: const TextStyle(
            color: Tokens.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.socialSharedPostDeleteConfirmBody,
          style: const TextStyle(
            color: Tokens.onSurfaceMuted,
            fontSize: Tokens.fontSizeBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.socialCancel,
              style: const TextStyle(color: Tokens.onSurfaceMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.socialSharedPostDelete,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final social = context.read<SocialProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await social.deleteAchievementShare(share.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Tokens.surface,
        content: Text(
          social.error == null
              ? l10n.socialSharedPostDeleted
              : l10n.socialErrorWithMessage(social.error!),
          style: const TextStyle(color: Tokens.onSurface),
        ),
      ),
    );
  }
}

class _ProfileSectionLoader extends StatelessWidget {
  const _ProfileSectionLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Tokens.accent,
        ),
      ),
    );
  }
}

class _ProfileEmptyLine extends StatelessWidget {
  const _ProfileEmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Tokens.onSurfaceFaint,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AddFriendButton extends StatelessWidget {
  const _AddFriendButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Tokens.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Tokens.radiusInner)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.person_add_rounded),
        label: Text(context.l10n.socialAddFriend,
            style: const TextStyle(
                fontSize: Tokens.fontSizeBody, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PendingRequestChip extends StatelessWidget {
  const _PendingRequestChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Tokens.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: Tokens.accent),
          const SizedBox(width: Tokens.spaceSm),
          Text(context.l10n.socialRequestSent,
              style: const TextStyle(
                  fontSize: Tokens.fontSizeBody,
                  fontWeight: FontWeight.w700,
                  color: Tokens.accent)),
        ],
      ),
    );
  }
}

class _RemoveFriendButton extends StatefulWidget {
  const _RemoveFriendButton({required this.name, required this.onConfirm});
  final String name;
  final Future<void> Function() onConfirm;

  @override
  State<_RemoveFriendButton> createState() => _RemoveFriendButtonState();
}

class _RemoveFriendButtonState extends State<_RemoveFriendButton> {
  bool _loading = false;

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Tokens.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusButton)),
        title: Text(context.l10n.socialRemoveFriendConfirmTitle,
            style: const TextStyle(
                color: Tokens.onSurface, fontWeight: FontWeight.w800)),
        content: Text(
          context.l10n.socialRemoveFriendConfirmBody(widget.name),
          style: const TextStyle(
              color: Tokens.onSurfaceMuted, fontSize: Tokens.fontSizeBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.socialCancel,
                style: const TextStyle(color: Tokens.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.socialRemoveFriend,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(context.l10n.socialErrorWithMessage('$e')),
              backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _confirm,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          if (_loading)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: Color(0x88EF4444)),
            )
          else
            const Icon(Icons.person_remove_rounded,
                size: 13, color: Color(0x88EF4444)),
          const SizedBox(width: 6),
          Text(
            context.l10n.socialRemoveFriend,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: Color(0x88EF4444),
            ),
          ),
        ],
      ),
    );
  }
}


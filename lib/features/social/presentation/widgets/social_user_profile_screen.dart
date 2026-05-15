import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../progression_engine/domain/display/progression_display_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_back_button.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_equipped_chip.dart';
import '../../../cosmetics/presentation/widgets/cosmetics_inventory_section.dart';
import '../../application/pinned_emblems_store.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'emblem_slot_sheet.dart';
import 'profile_detail_hero_card.dart';
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
  bool _photoBusy = false;

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

  Future<void> _pickOwnProfilePhoto() async {
    if (_photoBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    final social = context.read<SocialProvider>();
    final l10n = context.l10n;
    XFile? image;

    try {
      final implementation = ImagePickerPlatform.instance;
      if (implementation is ImagePickerAndroid) {
        implementation.useAndroidPhotoPicker = true;
      }
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 86,
        requestFullMetadata: false,
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.socialPhotoPickFailed(error.toString())),
        ),
      );
      return;
    }

    if (image == null || !mounted) return;

    setState(() => _photoBusy = true);
    final url = await social.uploadCurrentProfilePhoto(image);
    if (!mounted) return;
    setState(() => _photoBusy = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          url == null
              ? l10n.socialPhotoSaveFailed(
                  social.error ?? l10n.socialTryAgain,
                )
              : l10n.socialPhotoSaved,
        ),
      ),
    );
  }

  /// Returns the signed-in user's unlocked emblems sorted by unlock
  /// time (oldest first) so the collection grid fills left-to-right in
  /// the order the player earned them. Returns an empty list if not the
  /// own profile, or if cosmetics state hasn't loaded yet.
  List<CosmeticDefinition> _ownUnlockedEmblems(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final state = cosmetics.state;
    if (state == null) return const <CosmeticDefinition>[];

    final catalog = cosmetics.service.catalog;
    final unlocked = <CosmeticDefinition>[];
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
  ///   * The user's saved pin layout (from [PinnedEmblemsStore]) —
  ///     auto-filled from unlock order on first render.
  ///   * The unlocked emblem catalogue from [CosmeticsProvider].
  ///
  /// Stale pin ids (e.g. an emblem the user lost) collapse to null
  /// for that slot.
  List<CosmeticDefinition?> _ownEmblemSlots(
    BuildContext context,
    List<CosmeticDefinition> unlocked,
    String uid,
  ) {
    final pins = context
        .watch<PinnedEmblemsStore>()
        .pinsForUserOrAutoFill(
          uid,
          unlocked.map((def) => def.id).toList(growable: false),
        );
    final byId = {for (final def in unlocked) def.id: def};
    return [for (final id in pins) id == null ? null : byId[id]];
  }

  Future<void> _openEmblemSlotSheet({
    required int slotIndex,
    required bool isOwner,
    required String uid,
    required List<CosmeticDefinition?> slots,
    required List<CosmeticDefinition> unlocked,
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
    await context.read<PinnedEmblemsStore>().setPin(
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
        isMe ? _ownUnlockedEmblems(context) : const <CosmeticDefinition>[];

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
            final photoUrl = profile?.photoUrl ?? widget.initialPhotoUrl;
            final handle = profile?.handle ?? '';
            final stats = profile?.stats;
            // Slot mapping → cosmetic def. For friend profiles we
            // only know their single equipped emblem, so slot 0 shows
            // it and everything else is null.
            final emblemSlots = isMe
                ? _ownEmblemSlots(context, ownUnlockedEmblems, widget.uid)
                : <CosmeticDefinition?>[
                    socialCosmeticById(
                        profile?.equippedCosmetics.emblemId),
                    for (var i = 1;
                        i < ProfileDetailHeroCard.kEmblemSlotCount;
                        i++)
                      null,
                  ];
            final unlockedCount = isMe
                ? ownUnlockedEmblems.length
                : (profile?.equippedCosmetics.emblemId == null ? 0 : 1);

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
                      ProfileDetailHeroCard(
                        displayName: displayName,
                        handle: handle,
                        photoUrl: photoUrl,
                        profile: profile,
                        isMe: isMe,
                        emblemSlots: emblemSlots,
                        unlockedCount: unlockedCount,
                        photoBusy: _photoBusy,
                        onEditPhoto: isMe ? _pickOwnProfilePhoto : null,
                        onEditHandle:
                            isMe ? () => _editOwnHandle(handle) : null,
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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe && social.isFriendWith(widget.uid))
                              _buildActionArea(
                                  context, social, displayName),
                            if (stats != null) ...[
                              if (!isMe && social.isFriendWith(widget.uid))
                                const SizedBox(height: Tokens.spaceMd),
                              _buildStats(stats),
                            ],
                            const SizedBox(height: 10),
                            ProfileFriendsSection(stream: _friendsStream),
                            if (!isMe &&
                                !social.isFriendWith(widget.uid)) ...[
                              const SizedBox(height: 10),
                              _buildActionArea(
                                  context, social, displayName),
                            ],
                            // Own-profile only — friends don't see
                            // your inventory tiles, and we don't have
                            // their unlocked catalogue to render anyway.
                            if (isMe) ...[
                              const SizedBox(height: Tokens.spaceLg),
                              const CosmeticsInventorySection(),
                            ],
                            _ProfileCosmeticsSection(profile: profile),
                            const SizedBox(height: Tokens.spaceLg),
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Transparent overlay app bar — sits above everything,
                // letting the hero background image read under it.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.65, 1.0],
                        colors: [
                          Color(0xE60A0E1C), // strong top fade
                          Color(0x990A0E1C), // soft middle
                          Color(0x000A0E1C), // transparent bottom
                        ],
                      ),
                    ),
                    child: ScreenHeader(
                      greeting: '',
                      title: l10n.screenProfile,
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

  Widget _buildStats(SocialUserStats stats) {
    final l10n = context.l10n;
    final bestStreak = [
      stats.bestStepsStreak,
      stats.bestNutritionStreak,
    ].reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            icon: Icons.shield_moon_rounded,
            value: '${stats.unlockedAchievementCount}',
            label: l10n.socialProfileStatsAchievements,
            color: Tokens.accent,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _StatCell(
            icon: Icons.local_fire_department_rounded,
            value: l10n.socialDaysShort(bestStreak),
            label: l10n.socialProfileStatsBestStreak,
            color: Tokens.active.color,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _StatCell(
            icon: Icons.directions_walk_rounded,
            value: l10n.socialDaysShort(stats.bestStepsStreak),
            label: l10n.socialProfileStatsStepsStreak,
            color: Tokens.steps.color,
          ),
        ),
      ],
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
  const _ProfileSharesSection({required this.stream});

  final Stream<List<SocialAchievementShare>> stream;

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
                child: SocialFeedCard(share: share),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileCosmeticsSection extends StatelessWidget {
  const _ProfileCosmeticsSection({required this.profile});

  final SocialUserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final cosmetics = socialProfileExtraCosmetics(profile);
    if (cosmetics.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: context.l10n.socialProfileCosmetics,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final definition in cosmetics)
                CosmeticEquippedChip(
                  definition: definition,
                  l10n: l10n,
                ),
            ],
          ),
        ],
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

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Tokens.onSurfaceFaint,
                letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

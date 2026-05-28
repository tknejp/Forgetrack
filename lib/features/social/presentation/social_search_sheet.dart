import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../application/social_provider.dart';
import '../domain/social_models.dart';
import 'social_profile_utils.dart';
import 'widgets/social_cosmetic_avatar.dart';

/// Modal bottom sheet pushed from the persistent search field in
/// `SocialScreen`'s top bar. The sheet lands sized to ~92% of the
/// available screen height with the search input pinned at the very
/// top — when the soft keyboard opens the input stays visible right
/// above it (the live result list scrolls underneath via the
/// `viewInsets.bottom` padding the sheet applies to its body).
///
/// Replaces the earlier fullscreen route variant after 2026-05-28
/// UX feedback: the sheet shape lets the player drop back into the
/// social tab with one swipe-down instead of an explicit back tap,
/// and the dimmed underlay reinforces the modal "I'm just looking
/// for someone" affordance.
///
/// Results are split into two clearly-labelled sections so a player
/// hunting for an existing friend and a player hunting for a new
/// person each see exactly one section that's relevant to them:
///
///   * `Friends` — friends whose handle or display name matches the
///     normalised query. Tile opens the profile on tap.
///   * `People` — Firestore-resolved profiles that match and are NOT
///     already friends. Trailing chip resolves the four-way
///     relationship state (icon-only Add / Accept / Pending / Friend
///     badge) identically to the profile screen's action area.
class SocialSearchSheet extends StatefulWidget {
  const SocialSearchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const SocialSearchSheet(),
    );
  }

  @override
  State<SocialSearchSheet> createState() => _SocialSearchSheetState();
}

class _SocialSearchSheetState extends State<SocialSearchSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 240);

  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_handleChange);
    // Autofocus AFTER the first frame so the sheet's open transition
    // has finished laying out — focusing inside `initState` races the
    // sheet animation and on Android can drop the soft keyboard
    // request entirely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_handleChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChange() {
    final next = _controller.text;
    if (next == _query) return;
    setState(() => _query = next);
    _debounce?.cancel();
    final sp = context.read<SocialProvider>();
    if (next.trim().isEmpty) {
      sp.clearSearchResults();
      return;
    }
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      sp.searchUsers(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final l10n = context.l10n;
    final mq = MediaQuery.of(context);

    final normalisedQuery = normalizeSocialHandle(_query);
    final isQuerying = normalisedQuery.isNotEmpty;

    final friendIds = <String>{for (final f in social.friends) f.uid};
    final friendMatches = isQuerying
        ? social.friends
            .where((f) => _matchesQuery(f, normalisedQuery))
            .toList(growable: false)
        : const <SocialUserProfile>[];
    final nonFriendMatches = isQuerying
        ? social.searchResults
            .where((p) => !friendIds.contains(p.uid))
            .toList(growable: false)
        : const <SocialUserProfile>[];

    // Fill the entire available height. With `useSafeArea: true` on
    // the modal the parent constraints already exclude the top status
    // bar, so requesting `mq.size.height` here gets clamped to
    // "screen height minus system chrome" — which is exactly the
    // "all the way up to the top" the search surface needs to give
    // the live result list maximum room. The `viewInsets.bottom`
    // padding pushes the content above the soft keyboard so the
    // input stays anchored right under the drag handle and the
    // result list shrinks instead of disappearing.
    //
    // `enableDrag: true` (the modal's default) handles dismiss-on-
    // swipe-down: a drag started on the handle / header area pops
    // the route; the inner `ListView` keeps its own scroll, and
    // overscroll at offset 0 hands the gesture back to the sheet
    // for dismiss.
    return Container(
      height: mq.size.height,
      decoration: const BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Tokens.cardBorder),
          left: BorderSide(color: Tokens.cardBorder),
          right: BorderSide(color: Tokens.cardBorder),
        ),
      ),
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Tokens.cardBorder,
              borderRadius: BorderRadius.circular(Tokens.radiusProgress),
            ),
          ),
          const SizedBox(height: 12),
          _SearchInputRow(
            controller: _controller,
            focusNode: _focusNode,
            isSearching: social.isSearching,
            hasQuery: isQuerying,
            hintText: l10n.socialSearchHint,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Tokens.cardBorder),
          Expanded(
            child: _buildResultsArea(
              context,
              social: social,
              isQuerying: isQuerying,
              friendMatches: friendMatches,
              nonFriendMatches: nonFriendMatches,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea(
    BuildContext context, {
    required SocialProvider social,
    required bool isQuerying,
    required List<SocialUserProfile> friendMatches,
    required List<SocialUserProfile> nonFriendMatches,
  }) {
    final l10n = context.l10n;
    if (!isQuerying) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Text(
          l10n.socialSearchHint,
          style: const TextStyle(
            fontSize: Tokens.fontSizeBody,
            color: Tokens.onSurfaceFaint,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (friendMatches.isEmpty &&
        nonFriendMatches.isEmpty &&
        !social.isSearching) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Text(
          l10n.socialSearchNoResults,
          style: const TextStyle(
            fontSize: Tokens.fontSizeBody,
            color: Tokens.onSurfaceFaint,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        if (friendMatches.isNotEmpty) ...[
          _SectionHeader(label: l10n.socialFriendBadge),
          for (final profile in friendMatches)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SearchTile(profile: profile, isKnownFriend: true),
            ),
          if (nonFriendMatches.isNotEmpty) const SizedBox(height: 14),
        ],
        if (nonFriendMatches.isNotEmpty) ...[
          _SectionHeader(label: l10n.socialSearchOtherPeopleSection),
          for (final profile in nonFriendMatches)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SearchTile(profile: profile, isKnownFriend: false),
            ),
        ],
      ],
    );
  }

  bool _matchesQuery(SocialUserProfile friend, String normalisedQuery) {
    if (friend.handle.contains(normalisedQuery)) return true;
    final normalisedName = normalizeSocialHandle(friend.displayName);
    return normalisedName.contains(normalisedQuery);
  }
}

class _SearchInputRow extends StatelessWidget {
  const _SearchInputRow({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.hasQuery,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final bool hasQuery;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: Tokens.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                size: 16, color: Tokens.onSurfaceFaint),
            const SizedBox(width: Tokens.spaceSm),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                    fontSize: 13, color: Tokens.onSurface),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Tokens.onSurfaceFaint),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (isSearching)
              const Padding(
                padding: EdgeInsets.only(left: Tokens.spaceSm),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.6, color: Tokens.accent),
                ),
              )
            else if (hasQuery)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.clear,
                child: const Padding(
                  padding: EdgeInsets.only(left: Tokens.spaceSm),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Tokens.onSurfaceFaint),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: Tokens.fontSizeCaption,
          fontWeight: FontWeight.w800,
          color: Tokens.accent,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Single search-result row. Tapping the card opens the player's
/// profile (the profile screen owns the full action area). The
/// trailing slot resolves the four-way relationship state computed
/// against the signed-in user's live `SocialProvider` snapshot:
/// Add (icon-only), Accept (tap fires `acceptFriendRequest` against
/// the incoming pending), Pending (muted badge), Friends (muted
/// badge — surfaces in the `Friends` section above).
class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.profile,
    required this.isKnownFriend,
  });

  final SocialUserProfile profile;

  /// True when the caller already classified this row as a confirmed
  /// friend match (i.e. it lives in the `Friends` section). Avoids a
  /// second `social.isFriendWith` round-trip — purely a micro-
  /// optimisation, the data layer would resolve identically.
  final bool isKnownFriend;

  Future<void> _accept(BuildContext context, String requestId) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final sp = context.read<SocialProvider>();
    await sp.acceptFriendRequest(requestId);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(sp.error == null
          ? l10n.socialFriendRequestAccepted
          : l10n.socialErrorWithMessage(sp.error!)),
    ));
  }

  Future<void> _add(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final sp = context.read<SocialProvider>();
    await sp.sendFriendRequest(profile.uid);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(sp.error == null
          ? l10n.socialFriendRequestSent
          : l10n.socialErrorWithMessage(sp.error!)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final l10n = context.l10n;
    final isFriend = isKnownFriend || social.isFriendWith(profile.uid);
    final hasOutgoing =
        !isFriend && social.getPendingRequestTo(profile.uid) != null;
    final incoming = (!isFriend && !hasOutgoing)
        ? social.getIncomingRequestFrom(profile.uid)
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Dismiss the sheet first so the player lands on the profile
        // route stacked above the social tab, not buried behind a
        // half-open sheet they have to dismiss before they can use
        // the profile screen.
        Navigator.of(context).maybePop();
        openUserProfile(
          context,
          uid: profile.uid,
          initialDisplayName: profile.displayName,
          initialPhotoUrl: profile.photoUrl,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: Tokens.cardBorder),
        ),
        child: Row(
          children: [
            SocialCosmeticAvatar(
              name: profile.displayName,
              size: 38,
              photoUrl: profile.photoUrl,
              profile: profile,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Tokens.onSurface,
                    ),
                  ),
                  Text(
                    l10n.socialHandleLevel(profile.handle, profile.stats.level),
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeCaption,
                      color: Tokens.onSurfaceFaint,
                    ),
                  ),
                ],
              ),
            ),
            _trailing(
              context,
              isFriend: isFriend,
              hasOutgoing: hasOutgoing,
              incomingRequestId: incoming?.id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _trailing(
    BuildContext context, {
    required bool isFriend,
    required bool hasOutgoing,
    required String? incomingRequestId,
  }) {
    final l10n = context.l10n;
    if (isFriend) {
      return _Badge(
        icon: Icons.check_rounded,
        label: l10n.socialFriendBadge,
        color: Tokens.accent,
      );
    }
    if (hasOutgoing) {
      return _Badge(
        icon: Icons.schedule_rounded,
        label: l10n.socialPending,
        color: Tokens.accent,
      );
    }
    if (incomingRequestId != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _accept(context, incomingRequestId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.45)),
          ),
          child: Text(
            l10n.socialAccept,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: l10n.socialAdd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _add(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Tokens.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Tokens.accent.withValues(alpha: 0.28)),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 16,
            color: Tokens.accent,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

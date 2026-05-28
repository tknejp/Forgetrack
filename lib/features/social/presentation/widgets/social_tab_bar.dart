import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

/// Three-way tab strip for the social screen — Feed, Leaderboard,
/// Friends. The retired Activity tab used to live between Feed and
/// Leaderboard and showed reaction notifications with an unread
/// badge; reactions now flow through the bell button in
/// `_SocialTopBar` so the strip has no badge slots — the bell owns
/// every count.
class SocialTabBar extends StatelessWidget {
  const SocialTabBar({
    super.key,
    required this.controller,
  });
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Tokens.cardBorder)),
      ),
      child: TabBar(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        indicatorColor: Tokens.accent,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Tokens.accent,
        unselectedLabelColor: Tokens.onSurfaceMuted,
        labelStyle: const TextStyle(
          fontSize: Tokens.fontSizeSmall,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: Tokens.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: l10n.socialTabFeed),
          Tab(text: l10n.socialTabLeaderboard),
          Tab(text: l10n.socialTabFriends),
        ],
      ),
    );
  }
}

class SocialTabBadge extends StatelessWidget {
  const SocialTabBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: count > 9 ? 20.0 : 14.0,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

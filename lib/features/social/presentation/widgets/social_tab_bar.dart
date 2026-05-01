import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

class SocialTabBar extends StatelessWidget {
  const SocialTabBar({
    super.key,
    required this.controller,
    required this.pendingCount,
    required this.unreadNotifCount,
  });
  final TabController controller;
  final int pendingCount;
  final int unreadNotifCount;

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
          Tab(
            child: _TabWithBadge(
              label: l10n.socialTabActivity,
              count: unreadNotifCount,
            ),
          ),
          Tab(text: l10n.socialTabLeaderboard),
          Tab(
            child: _TabWithBadge(
              label: l10n.socialTabFriends,
              count: pendingCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  const _TabWithBadge({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(label),
        if (count > 0)
          Positioned(
            top: -6,
            right: -10,
            child: SocialTabBadge(count: count),
          ),
      ],
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

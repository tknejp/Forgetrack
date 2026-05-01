import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../widgets/social_empty.dart';
import '../widgets/social_feed_card.dart';
import '../widgets/social_notification_card.dart';

class SocialActivityTab extends StatelessWidget {
  const SocialActivityTab({super.key});

  void _openShare(BuildContext context, String shareId) {
    final share = context.read<SocialProvider>().shareById(shareId);
    if (share == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareDetailSheet(share: share),
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final notifications = social.notifications;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.socialSectionRecentActivity,
            style: const TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: Tokens.onSurfaceFaint,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (notifications.isEmpty)
          SocialEmpty(
            icon: Icons.notifications_none_rounded,
            title: l10n.socialNoNotificationsTitle,
            subtitle: l10n.socialNoNotificationsSubtitle,
          )
        else
          ...notifications.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SocialNotificationCard(
                  notification: n,
                  onOpenShare: () => _openShare(context, n.shareId),
                ),
              )),
      ],
    );
  }
}

class _ShareDetailSheet extends StatelessWidget {
  const _ShareDetailSheet({required this.share});
  final SocialAchievementShare share;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Tokens.cardBorder,
              borderRadius: BorderRadius.circular(Tokens.radiusProgress),
            ),
          ),
          const SizedBox(height: 14),
          SocialFeedCard(share: share),
          const SizedBox(height: Tokens.spaceXs),
        ],
      ),
    );
  }
}

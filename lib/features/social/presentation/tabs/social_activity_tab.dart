import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'NEDÁVNÁ AKTIVITA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FtTokens.onSurfaceFaint,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (notifications.isEmpty)
          const SocialEmpty(
            icon: Icons.notifications_none_rounded,
            title: 'Žádné upozornění',
            subtitle:
                'Zde uvidíš reakce přátel na tvoje sdílené achievementy.',
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
        color: FtTokens.bg,
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
              color: FtTokens.cardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          SocialFeedCard(share: share),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

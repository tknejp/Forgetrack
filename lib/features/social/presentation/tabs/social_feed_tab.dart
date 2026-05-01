import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/social_provider.dart';
import '../widgets/social_empty.dart';
import '../widgets/social_feed_card.dart';

class SocialFeedTab extends StatelessWidget {
  const SocialFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final shares = social.recentShares;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.socialSectionFriendActivity,
            style: const TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: Tokens.onSurfaceFaint,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (shares.isEmpty)
          SocialEmpty(
            icon: Icons.forum_outlined,
            title: l10n.socialFeedEmptyTitle,
            subtitle: l10n.socialFeedEmptySubtitle,
          )
        else
          ...shares.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SocialFeedCard(share: s),
            ),
          ),
      ],
    );
  }
}

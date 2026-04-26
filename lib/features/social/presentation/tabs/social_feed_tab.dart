import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../application/social_provider.dart';
import '../widgets/social_empty.dart';
import '../widgets/social_feed_card.dart';

class SocialFeedTab extends StatelessWidget {
  const SocialFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final shares = social.recentShares;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'AKTIVITA PŘÁTEL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FtTokens.onSurfaceFaint,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (shares.isEmpty)
          const SocialEmpty(
            icon: Icons.forum_outlined,
            title: 'Feed je prázdný',
            subtitle: 'Sdílené achievementy přátel se zobrazí zde.',
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

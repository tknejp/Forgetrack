import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import 'social_feed_card.dart';

/// Renders a [SocialFeedCard] and — when the viewer authored the share —
/// surfaces the kebab "Delete" affordance plus a shared confirm-then-
/// delete flow. The viewer's own posts are detectable wherever shares
/// surface (Chronicle feed, profile "My posts", inline notification
/// preview), so the deletion UX stays consistent without each caller
/// re-implementing ownership checks or the confirm dialog.
class SocialOwnedShareCard extends StatelessWidget {
  const SocialOwnedShareCard({
    super.key,
    required this.share,
  });

  final SocialAchievementShare share;

  @override
  Widget build(BuildContext context) {
    final viewerUid = context.select<SocialProvider, String?>(
      (p) => p.currentUid,
    );
    final viewerOwnsShare =
        viewerUid != null && viewerUid == share.actorUid;
    return SocialFeedCard(
      share: share,
      onDelete:
          viewerOwnsShare ? () => _confirmAndDelete(context, share) : null,
    );
  }

  static Future<void> _confirmAndDelete(
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

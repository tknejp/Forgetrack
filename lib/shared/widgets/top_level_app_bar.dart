import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import 'profile_avatar_action.dart';

enum AppHeaderSyncCopy { health, nutrition }

class TopLevelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool emphasizeTitle;
  final bool isSignedIn;
  final String? photoUrl;
  final String? displayName;
  final String? email;
  final String sessionStateKey;

  const TopLevelAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.emphasizeTitle = false,
    required this.isSignedIn,
    this.photoUrl,
    this.displayName,
    this.email,
    required this.sessionStateKey,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 18,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (emphasizeTitle ? tt.titleMedium : tt.titleLarge)?.copyWith(
                fontSize: emphasizeTitle ? 18 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: emphasizeTitle ? 1.1 : -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.82),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Center(
            child: ProfileAvatarAction(
              isSignedIn: isSignedIn,
              photoUrl: photoUrl,
              displayName: displayName,
              email: email,
              sessionStateKey: sessionStateKey,
            ),
          ),
        ),
      ],
    );
  }
}

String buildTopLevelHeaderSubtitle(
  BuildContext context, {
  required AppHeaderSyncCopy syncCopy,
  DateTime? syncedAt,
  DateTime? currentDate,
}) {
  final locale = Localizations.localeOf(context).toString();
  final dateLabel =
      DateFormat.MMMMd(locale).format(currentDate ?? DateTime.now());
  if (syncedAt == null) return dateLabel;

  final timeLabel = DateFormat('HH:mm', locale).format(syncedAt);
  final syncLabel = switch (syncCopy) {
    AppHeaderSyncCopy.health => context.l10n.healthLastSynced(timeLabel),
    AppHeaderSyncCopy.nutrition => context.l10n.ktSyncedAt(timeLabel),
  }
      .replaceFirst(':', '');

  return '$dateLabel • $syncLabel';
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/application/auth_user.dart';
import '../l10n/l10n.dart';
import '../features/auth/application/auth_provider.dart';
import '../screens/profile/profile_screen.dart';

class ProfileAvatarAction extends StatelessWidget {
  const ProfileAvatarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final photoUrl = auth.isSignedIn ? user?.photoUrl?.trim() : null;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final initials = auth.isSignedIn ? _buildInitials(user) : null;
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: context.l10n.screenProfile,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Container(
          key: ValueKey(
            '${auth.sessionState.name}:${user?.photoUrl ?? ''}:${user?.email ?? ''}',
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasPhoto
                  ? colorScheme.outlineVariant.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
          child: CircleAvatar(
            radius: 16,
            foregroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            backgroundColor: auth.isSignedIn
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            child: initials != null
                ? Text(
                    initials,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                : Icon(
                    Icons.person_outline,
                    size: 18,
                    color: auth.isSignedIn
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }

  String? _buildInitials(AuthUser? user) {
    final displayName = user?.displayName?.trim();
    final raw = displayName != null && displayName.isNotEmpty
        ? displayName
        : user?.email.trim();
    if (raw == null || raw.isEmpty) return null;

    final parts = raw
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return null;

    final initials =
        parts.map((part) => part.substring(0, 1).toUpperCase()).join();
    return initials.isEmpty ? null : initials;
  }
}

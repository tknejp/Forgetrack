import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../features/settings/presentation/settings_screen.dart';

class ProfileAvatarAction extends StatelessWidget {
  final bool isSignedIn;
  final String? photoUrl;
  final String? displayName;
  final String? email;
  final String sessionStateKey;

  const ProfileAvatarAction({
    super.key,
    required this.isSignedIn,
    this.photoUrl,
    this.displayName,
    this.email,
    required this.sessionStateKey,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPhotoUrl = isSignedIn ? photoUrl?.trim() : null;
    final hasPhoto = trimmedPhotoUrl != null && trimmedPhotoUrl.isNotEmpty;
    final initials = isSignedIn ? _buildInitials(displayName, email) : null;
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: context.l10n.screenProfile,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Container(
          key: ValueKey(
            '$sessionStateKey:${photoUrl ?? ''}:${email ?? ''}',
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
            foregroundImage: hasPhoto
                ? NetworkImage(trimmedPhotoUrl!)
                : null,
            backgroundColor: isSignedIn
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
                    color: isSignedIn
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }

  String? _buildInitials(String? displayName, String? email) {
    final trimmedDisplayName = displayName?.trim();
    final raw = trimmedDisplayName != null && trimmedDisplayName.isNotEmpty
        ? trimmedDisplayName
        : email?.trim();
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

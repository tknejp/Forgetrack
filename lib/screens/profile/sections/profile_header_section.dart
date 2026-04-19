import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/google_logo_icon.dart';
import '../../../widgets/google_sign_in_button.dart';

class ProfileHeaderCard extends StatelessWidget {
  final AuthProvider auth;

  const ProfileHeaderCard({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (auth.isRestoring || auth.isLoading) {
      return const _HeaderLoading();
    }

    if (auth.isSignedIn) {
      return _SignedInHeaderContent(auth: auth);
    }

    return _SignedOutHeaderContent(auth: auth);
  }
}

class _HeaderLoading extends StatelessWidget {
  const _HeaderLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SignedInHeaderContent extends StatelessWidget {
  final AuthProvider auth;

  const _SignedInHeaderContent({required this.auth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final l10n = context.l10n;
    final user = auth.user!;
    final photoUrl = user.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isDark = theme.brightness == Brightness.dark;

    final badgeBg = isDark ? const Color(0xFF1B3A1B) : const Color(0xFFE8F5E9);
    final badgeBorder =
        isDark ? const Color(0xFF388E3C) : const Color(0xFFA5D6A7);
    final badgeText = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
          backgroundColor: cs.primaryContainer,
          child: hasPhoto
              ? null
              : Icon(Icons.person, size: 44, color: cs.onPrimaryContainer),
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName ?? user.email,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        if (user.displayName != null &&
            user.displayName != user.email &&
            user.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.email,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoogleLogoIcon(
                size: 16,
                fallback: Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: badgeText,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.profileConnectedGoogle,
                style: tt.labelMedium?.copyWith(color: badgeText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignedOutHeaderContent extends StatelessWidget {
  final AuthProvider auth;

  const _SignedOutHeaderContent({required this.auth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final l10n = context.l10n;

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: cs.surfaceContainerHigh,
          child: Icon(
            Icons.person_outline,
            size: 44,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.profileNotSignedIn,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.profileSignInBenefit,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 15, color: cs.error),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Sign-in failed. Please try again.',
                  style: tt.bodySmall?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        GoogleSignInButton(
          isLoading: auth.isBusy,
          onPressed:
              auth.isBusy ? null : () => context.read<AuthProvider>().signIn(),
        ),
      ],
    );
  }
}

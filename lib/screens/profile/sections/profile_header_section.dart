import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_logo.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
      height: 104,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SignedInHeaderContent extends StatelessWidget {
  final AuthProvider auth;

  const _SignedInHeaderContent({required this.auth});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final user = auth.user!;
    final photoUrl = user.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final primaryLine = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email;
    final showEmail = user.email.isNotEmpty && primaryLine != user.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
              backgroundColor: cs.primaryContainer,
              child: hasPhoto
                  ? null
                  : Icon(
                      Icons.person,
                      size: 28,
                      color: cs.onPrimaryContainer,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    primaryLine,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showEmail) ...[
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _HeaderBadge(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoogleLogoIcon(
                size: 14,
                fallback: Icon(
                  Icons.link_rounded,
                  size: 14,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.profileConnectedGoogle,
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogoIcon(size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppWordmark(height: 22),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileNotSignedIn,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.profileSignInBenefit,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 16, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  auth.error!,
                  style: tt.bodySmall?.copyWith(color: cs.error),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        GoogleSignInButton(
          isLoading: auth.isBusy,
          onPressed:
              auth.isBusy ? null : () => context.read<AuthProvider>().signIn(),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final Widget child;

  const _HeaderBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.14),
        ),
      ),
      child: child,
    );
  }
}

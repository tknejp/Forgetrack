import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/presentation/google_sign_in_button.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../social/presentation/widgets/social_cosmetic_avatar.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_widgets.dart';

// Google brand palette — used to give the account card a distinctive
// "Google rainbow" wash that visually identifies the source without
// fighting with the cooler sky-blue used by Health Connect elsewhere
// in Settings.
const Color _kGoogleBlue = Color(0xFF4285F4);
const Color _kGoogleRed = Color(0xFFEA4335);
const Color _kGoogleYellow = Color(0xFFFBBC04);
const Color _kGoogleGreen = Color(0xFF34A853);

class SettingsHeaderCard extends StatelessWidget {
  final AuthProvider auth;

  const SettingsHeaderCard({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Multi-stop gradient drawn diagonally so the four Google brand
        // colors blend into a single warm-cool wash. Blue dominates as
        // the primary; the red/yellow/green hints add the recognizable
        // "Google" feel without looking like a rainbow chip.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.4, 0.7, 1.0],
          colors: [
            _kGoogleBlue.withValues(alpha: 0.16),
            _kGoogleRed.withValues(alpha: 0.04),
            _kGoogleYellow.withValues(alpha: 0.04),
            _kGoogleGreen.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: _kGoogleBlue.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: _kGoogleBlue.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (auth.isRestoring || auth.isLoading) {
      return const _HeaderLoading();
    }

    if (auth.isSignedIn) {
      // Signed-in mirrors the KT connected-card pattern: a SettingsTile
      // row (avatar + name/email + trailing action), so both account
      // cards in Settings share the same horizontal rhythm.
      return _SignedInHeaderContent(auth: auth);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: _SignedOutHeaderContent(auth: auth),
    );
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
    final primaryLine = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email;
    final showEmail = user.email.isNotEmpty && primaryLine != user.email;
    final cosmetics = context.watch<CosmeticsProvider>();
    final raceId = cosmetics.currentRaceId;
    final skinId = cosmetics.state?.equipped.skinId;
    final frameId = cosmetics.state?.equipped.frameId;
    final canShowSkin = raceId != null && skinId != null;

    return Material(
      color: Colors.transparent,
      child: SettingsTile(
        icon: Icons.person,
        iconWidget: SizedBox(
          width: 36,
          height: 36,
          child: canShowSkin
              ? SocialCosmeticAvatar(
                  name: primaryLine,
                  size: 32,
                  raceId: raceId,
                  skinId: skinId,
                  frameId: frameId,
                  frameOverscan: 1.18,
                  frameMargin: EdgeInsets.zero,
                  radius: 16,
                )
              : CircleAvatar(
                  radius: 18,
                  backgroundColor: _kGoogleBlue.withValues(alpha: 0.22),
                  child: const Icon(
                    Icons.person,
                    size: 18,
                    color: Tokens.onSurface,
                  ),
                ),
        ),
        iconBorderless: true,
        iconBackgroundColor: Colors.transparent,
        label: primaryLine,
        subtitle: showEmail ? user.email : null,
        trailing: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: cs.error,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _confirmSignOut(context),
          child: Text(
            l10n.profileSignOut,
            style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: l10n.profileSignOutConfirmTitle,
      message: l10n.profileSignOutConfirmMessage,
      confirmLabel: l10n.profileSignOut,
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().signOut();
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
                  const SizedBox(height: Tokens.spaceSm),
                  Text(
                    l10n.profileNotSignedIn,
                    style: tt.titleMedium?.copyWith(
                      color: Tokens.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Tokens.spaceMd),
        Text(
          l10n.profileSignInBenefit,
          style: tt.bodySmall?.copyWith(
            color: Tokens.onSurfaceMuted,
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
          backgroundColor: cs.primaryContainer.withValues(alpha: 0.18),
          borderColor: cs.primary.withValues(alpha: 0.28),
          iconColor: cs.primary,
          textColor: cs.onSurface,
        ),
      ],
    );
  }
}

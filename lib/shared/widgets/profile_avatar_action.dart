import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../features/cosmetics/application/cosmetics_provider.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/social/presentation/widgets/social_cosmetic_avatar.dart';

/// Top-app-bar profile action. Renders the signed-in player's
/// race × skin thumbnail (post-onboarding) inside the equipped Frame
/// border. Falls back to a Material person icon when signed out or
/// before the race-pick gate has run.
class ProfileAvatarAction extends StatelessWidget {
  final bool isSignedIn;
  final String? displayName;
  final String? email;
  final String sessionStateKey;

  const ProfileAvatarAction({
    super.key,
    required this.isSignedIn,
    this.displayName,
    this.email,
    required this.sessionStateKey,
  });

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final raceId = cosmetics.currentRaceId;
    final skinId = cosmetics.state?.equipped.skinId;
    final frameId = cosmetics.state?.equipped.frameId;
    final colorScheme = Theme.of(context).colorScheme;
    final canShowSkin = isSignedIn && raceId != null && skinId != null;

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
        child: SizedBox(
          key: ValueKey(
            '$sessionStateKey:${raceId ?? ''}:${skinId ?? ''}:${frameId ?? ''}',
          ),
          width: 36,
          height: 36,
          child: canShowSkin
              ? SocialCosmeticAvatar(
                  name: displayName ?? email ?? '',
                  size: 32,
                  raceId: raceId,
                  skinId: skinId,
                  frameId: frameId,
                  // Compact tap target — frame already supplies its own
                  // border; keep overscan modest so the chrome doesn't
                  // bleed past the IconButton bounds.
                  frameOverscan: 1.18,
                  frameMargin: EdgeInsets.zero,
                  radius: 16,
                  color: colorScheme.primary,
                )
              : Center(
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: isSignedIn
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.person_outline,
                      size: 18,
                      color: isSignedIn
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

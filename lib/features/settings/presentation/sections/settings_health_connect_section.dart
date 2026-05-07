import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/application/health_connect_settings_launcher.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../widgets/settings_widgets.dart';

class SettingsHealthConnectSection extends StatelessWidget {
  const SettingsHealthConnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final l10n = context.l10n;
    final hasAccess = fitness.accessState == FitnessAccessState.ready;

    return SettingsCard(
      children: [
        SettingsTile(
          icon: Icons.health_and_safety_rounded,
          iconColor: Tokens.sleep.color,
          iconBackgroundColor: Tokens.sleep.dim,
          label: l10n.settingsHealthConnectOpen,
          subtitle: l10n.settingsHealthConnectOpenBody,
          trailingLabel: hasAccess
              ? l10n.settingsHealthConnectConnected
              : l10n.settingsHealthConnectNeedsAccess,
          showChevron: true,
          onTap: () async {
            await HealthConnectSettingsLauncher.openSettings();
            if (context.mounted) {
              await context.read<FitnessProvider>().initialize();
            }
          },
        ),
        const SettingsTileDivider(indent: 0),
        SettingsTile(
          icon: Icons.verified_user_rounded,
          iconColor: Tokens.accent,
          iconBackgroundColor: Tokens.accent.withValues(alpha: 0.14),
          label: l10n.settingsHealthConnectPermissions,
          subtitle: l10n.settingsHealthConnectPermissionsBody,
          showChevron: true,
          onTap: () => context.read<FitnessProvider>().requestPermissions(),
        ),
      ],
    );
  }
}

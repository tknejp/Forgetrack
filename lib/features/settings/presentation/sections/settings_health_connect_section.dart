import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/application/health_connect_settings_launcher.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../widgets/settings_widgets.dart';

/// Brand blue for the Health Connect section. Mirrors the accent used on
/// the home HC prompt card so the source has a consistent visual identity
/// across the app.
const Color _kHcBrandColor = Color(0xFF60A5FA);

/// Card decoration shared by the HC section so the same calm blue glow
/// surrounds both tiles (Open / Permissions). Mirrors the KT branded card
/// pattern.
BoxDecoration _hcBrandedCardDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _kHcBrandColor.withValues(alpha: 0.16),
        _kHcBrandColor.withValues(alpha: 0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(Tokens.radiusCard),
    border: Border.all(color: _kHcBrandColor.withValues(alpha: 0.24)),
    boxShadow: [
      BoxShadow(
        color: _kHcBrandColor.withValues(alpha: 0.22),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class SettingsHealthConnectSection extends StatelessWidget {
  const SettingsHealthConnectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final l10n = context.l10n;
    final hasAccess = fitness.accessState == FitnessAccessState.ready;

    return Container(
      decoration: _hcBrandedCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsTile(
              icon: Icons.health_and_safety_rounded,
              iconWidget: Image.asset(
                'assets/icons/hc/health_connect_logo.png',
                fit: BoxFit.contain,
              ),
              iconBorderless: true,
              iconBackgroundColor: Colors.transparent,
              label: l10n.settingsHealthConnectOpen,
              subtitle: l10n.settingsHealthConnectOpenBody,
              trailing: _HcStatusChip(connected: hasAccess, label: hasAccess
                  ? l10n.settingsHealthConnectConnected
                  : l10n.settingsHealthConnectNeedsAccess),
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
              iconColor: _kHcBrandColor,
              iconBackgroundColor: _kHcBrandColor.withValues(alpha: 0.18),
              label: l10n.settingsHealthConnectPermissions,
              subtitle: l10n.settingsHealthConnectPermissionsBody,
              showChevron: true,
              onTap: () => context.read<FitnessProvider>().requestPermissions(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status pill on the "Open Health Connect" tile. Green when connected,
/// amber when access is missing — clearer than the previous muted text.
class _HcStatusChip extends StatelessWidget {
  final bool connected;
  final String label;

  const _HcStatusChip({required this.connected, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = connected ? const Color(0xFF34D399) : const Color(0xFFFBBF24);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

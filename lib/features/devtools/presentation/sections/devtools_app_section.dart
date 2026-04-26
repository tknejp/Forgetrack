import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/constants.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/devtools_permission_service.dart';
import '../../application/devtools_provider.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

class DevToolsAppSection extends StatelessWidget {
  const DevToolsAppSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final devTools = context.watch<DevToolsProvider>();
    final cs = Theme.of(context).colorScheme;

    final uid = auth.user?.firebaseUid;
    final buildMode = kDebugMode
        ? 'debug'
        : kProfileMode
            ? 'profile'
            : 'release';
    final accessReason = kDebugMode
        ? 'kDebugMode'
        : DevToolsPermissionService.hasAccess(uid)
            ? 'UID allowlist'
            : 'unknown';

    return DevToolsSectionCard(
      title: 'App & Auth', // TODO: l10n
      children: [
        DevToolsStatusTile(
          label: 'Build mode',
          value: buildMode,
          valueColor: kDebugMode ? Colors.orangeAccent : cs.onSurface,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'App version',
          value: AppConstants.appVersion,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Access via',
          value: accessReason,
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Debug Mode', // TODO: l10n
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
              Switch.adaptive(
                value: devTools.isDebugModeEnabled,
                onChanged: (v) =>
                    context.read<DevToolsProvider>().setDebugModeEnabled(v),
                activeThumbColor: Colors.orangeAccent,
              ),
            ],
          ),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Sign-in state',
          value: auth.sessionState.name,
          valueColor: auth.isSignedIn ? Colors.greenAccent.shade400 : null,
        ),
        if (uid != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Firebase UID',
            value: _maskUid(uid),
            mono: true,
            onCopy: () => copyToClipboard(context, uid, label: 'UID'),
          ),
        ],
        if (auth.user?.email != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Email',
            value: auth.user!.email,
          ),
        ],
        if (auth.error != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Auth error',
            value: auth.error!,
            valueColor: cs.error,
          ),
        ],
      ],
    );
  }

  String _maskUid(String uid) {
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 6)}…${uid.substring(uid.length - 4)}';
  }
}

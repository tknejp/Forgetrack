import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../core/logging/app_log.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../../auth/application/auth_provider.dart';
import '../application/devtools_permission_service.dart';
import '../application/devtools_provider.dart';
import 'sections/devtools_app_section.dart';
import 'sections/devtools_db_section.dart';
import 'sections/devtools_overrides_section.dart';
import 'sections/devtools_progression_section.dart';
import 'sections/devtools_provider_section.dart';
import 'sections/devtools_background_section.dart';
import 'sections/devtools_health_pipeline_section.dart';
import 'sections/devtools_notification_section.dart';
import 'sections/devtools_sync_section.dart';
import 'sections/devtools_ui_section.dart';

class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DevToolsProvider>().markAccessGranted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firebaseUid = auth.user?.firebaseUid;

    if (!DevToolsPermissionService.hasAccess(firebaseUid)) {
      return _AccessDeniedScreen(uid: firebaseUid);
    }

    AppLog.app.info('DevTools: screen opened uid=$firebaseUid');

    return const _DevToolsBody();
  }
}

class _DevToolsBody extends StatelessWidget {
  const _DevToolsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: FtTokens.bg,
      ),
      child: Scaffold(
        backgroundColor: FtTokens.bg,
        appBar: AppBar(
          backgroundColor: FtTokens.bg,
          foregroundColor: Colors.white,
          title: Text(
            l10n.devtoolsTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
          children: const [
            DevToolsAppSection(),
            SizedBox(height: 16),
            DevToolsProviderSection(),
            SizedBox(height: 16),
            DevToolsDbSection(),
            SizedBox(height: 16),
            DevToolsHealthPipelineSection(),
            SizedBox(height: 16),
            DevToolsSyncSection(),
            SizedBox(height: 16),
            DevToolsBackgroundSection(),
            SizedBox(height: 16),
            DevToolsNotificationSection(),
            SizedBox(height: 16),
            DevToolsUiSection(),
            SizedBox(height: 16),
            DevToolsProgressionSection(),
            SizedBox(height: 16),
            DevToolsOverridesSection(),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  final String? uid;

  const _AccessDeniedScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: FtTokens.bg,
      appBar: AppBar(
        backgroundColor: FtTokens.bg,
        foregroundColor: Colors.white,
        title: const Text('Developer Tools'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Access Denied', // TODO: l10n
              style: TextStyle(
                color: cs.error,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This screen is restricted to developers.', // TODO: l10n
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (uid != null) ...[
              const SizedBox(height: 16),
              Text(
                'Your Firebase UID:',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                uid!,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

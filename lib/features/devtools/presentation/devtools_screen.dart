import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../core/logging/app_log.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
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
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            14,
            MediaQuery.of(context).padding.top + 12,
            14,
            32,
          ),
          children: [
            ScreenHeader(
              greeting: '',
              title: l10n.devtoolsTitle,
              leading: const FtBackButton(),
            ),
            const SizedBox(height: 18),
            const DevToolsAppSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsProviderSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsDbSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsHealthPipelineSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsSyncSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsBackgroundSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsNotificationSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsUiSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsProgressionSection(),
            const SizedBox(height: Tokens.spaceLg),
            const DevToolsOverridesSection(),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                MediaQuery.of(context).padding.top + 12,
                14,
                0,
              ),
              child: ScreenHeader(
                greeting: '',
                title: 'Developer Tools',
                leading: const FtBackButton(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 48, color: cs.error),
                    const SizedBox(height: Tokens.spaceLg),
                    Text(
                      'Access Denied', // TODO: l10n
                      style: TextStyle(
                        color: cs.error,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Tokens.spaceSm),
                    Text(
                      'This screen is restricted to developers.', // TODO: l10n
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    if (uid != null) ...[
                      const SizedBox(height: Tokens.spaceLg),
                      Text(
                        'Your Firebase UID:',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: Tokens.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(height: Tokens.spaceXs),
                      SelectableText(
                        uid!,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: Tokens.fontSizeSmall,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'sections/devtools_cosmetics_section.dart';
import 'sections/devtools_factory_reset_section.dart';
import 'sections/devtools_ui_section.dart';
import 'sections/devtools_unlock_inventory_section.dart';

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

class _DevToolsBody extends StatefulWidget {
  const _DevToolsBody();

  @override
  State<_DevToolsBody> createState() => _DevToolsBodyState();
}

class _DevToolsBodyState extends State<_DevToolsBody> {
  final ScrollController _controller = ScrollController();

  late final List<_DevToolsSectionLink> _sections = [
    _DevToolsSectionLink(
      label: 'App',
      icon: Icons.app_settings_alt_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsAppSection(),
    ),
    _DevToolsSectionLink(
      label: 'Providers',
      icon: Icons.hub_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsProviderSection(),
    ),
    _DevToolsSectionLink(
      label: 'Database',
      icon: Icons.storage_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsDbSection(),
    ),
    _DevToolsSectionLink(
      label: 'Health',
      icon: Icons.monitor_heart_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsHealthPipelineSection(),
    ),
    _DevToolsSectionLink(
      label: 'Sync',
      icon: Icons.sync_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsSyncSection(),
    ),
    _DevToolsSectionLink(
      label: 'Background',
      icon: Icons.cloud_sync_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsBackgroundSection(),
    ),
    _DevToolsSectionLink(
      label: 'Notifications',
      icon: Icons.notifications_active_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsNotificationSection(),
    ),
    _DevToolsSectionLink(
      label: 'UI',
      icon: Icons.palette_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsUiSection(),
    ),
    _DevToolsSectionLink(
      label: 'Progression',
      icon: Icons.military_tech_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsProgressionSection(),
    ),
    _DevToolsSectionLink(
      label: 'Unlocks',
      icon: Icons.fact_check_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsUnlockInventorySection(),
    ),
    _DevToolsSectionLink(
      label: 'Cosmetics',
      icon: Icons.auto_awesome_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsCosmeticsSection(),
    ),
    _DevToolsSectionLink(
      label: 'Overrides',
      icon: Icons.tune_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsOverridesSection(),
    ),
    _DevToolsSectionLink(
      label: 'Factory Reset',
      icon: Icons.delete_sweep_rounded,
      key: GlobalKey(),
      builder: () => const DevToolsFactoryResetSection(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(_DevToolsSectionLink section) {
    final context = section.key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _showJumpSheet() async {
    final section = await showModalBottomSheet<_DevToolsSectionLink>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DevToolsJumpSheet(sections: _sections),
    );
    if (section != null) _jumpTo(section);
  }

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
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _controller,
              padding: EdgeInsets.fromLTRB(
                14,
                MediaQuery.of(context).padding.top + 12,
                14,
                MediaQuery.of(context).padding.bottom + 112,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScreenHeader(
                    greeting: '',
                    title: l10n.devtoolsTitle,
                    leading: const FtBackButton(),
                  ),
                  const SizedBox(height: 18),
                  for (final section in _sections) ...[
                    KeyedSubtree(
                      key: section.key,
                      child: section.builder(),
                    ),
                    if (section != _sections.last)
                      const SizedBox(height: Tokens.spaceLg),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: _DevToolsBottomJumpBar(
                sections: _sections,
                onJump: _jumpTo,
                onOpenMenu: _showJumpSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevToolsSectionLink {
  const _DevToolsSectionLink({
    required this.label,
    required this.icon,
    required this.key,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final GlobalKey key;
  final Widget Function() builder;
}

class _DevToolsBottomJumpBar extends StatelessWidget {
  const _DevToolsBottomJumpBar({
    required this.sections,
    required this.onJump,
    required this.onOpenMenu,
  });

  final List<_DevToolsSectionLink> sections;
  final ValueChanged<_DevToolsSectionLink> onJump;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final priority = sections
        .where((s) =>
            const {'Progression', 'Unlocks', 'Cosmetics'}.contains(s.label))
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ft.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final section in priority) ...[
            Expanded(
              child: _DevToolsJumpChip(
                section: section,
                onTap: () => onJump(section),
              ),
            ),
            const SizedBox(width: 7),
          ],
          _DevToolsMoreButton(onTap: onOpenMenu),
        ],
      ),
    );
  }
}

class _DevToolsJumpSheet extends StatelessWidget {
  const _DevToolsJumpSheet({required this.sections});

  final List<_DevToolsSectionLink> sections;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: ft.surface,
          borderRadius: BorderRadius.circular(Tokens.radiusCard),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Row(
                children: [
                  Icon(Icons.menu_open_rounded, size: 18, color: ft.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Jump to section',
                    style: TextStyle(
                      color: ft.onSurface,
                      fontSize: Tokens.fontSizeSmall,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.7,
              children: [
                for (final section in sections)
                  _DevToolsSheetItem(section: section),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DevToolsSheetItem extends StatelessWidget {
  const _DevToolsSheetItem({required this.section});

  final _DevToolsSectionLink section;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return InkWell(
      onTap: () => Navigator.of(context).pop(section),
      borderRadius: BorderRadius.circular(Tokens.radiusInner),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Row(
          children: [
            Icon(section.icon, size: 16, color: ft.onSurfaceMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ft.onSurface,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevToolsMoreButton extends StatelessWidget {
  const _DevToolsMoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusProgress),
      child: Container(
        width: 46,
        height: 38,
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Icon(Icons.more_horiz_rounded, color: ft.onSurfaceMuted),
      ),
    );
  }
}

class _DevToolsJumpChip extends StatelessWidget {
  const _DevToolsJumpChip({
    required this.section,
    required this.onTap,
  });

  final _DevToolsSectionLink section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusProgress),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: ft.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(color: ft.accent.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(section.icon, size: 15, color: ft.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ft.accent,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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

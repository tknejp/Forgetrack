import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../features/settings/presentation/dialogs/settings_dialogs.dart';
import '../../../../features/social/application/social_provider.dart';
import '../../application/devtools_provider.dart';
import '../../application/devtools_sync_logger.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

String _permissionLabel(AuthorizationStatus status) {
  switch (status) {
    case AuthorizationStatus.authorized:
      return 'authorized';
    case AuthorizationStatus.denied:
      return 'denied';
    case AuthorizationStatus.notDetermined:
      return 'not determined';
    case AuthorizationStatus.provisional:
      return 'provisional';
  }
}

Color? _permissionColor(AuthorizationStatus status, ColorScheme cs) {
  switch (status) {
    case AuthorizationStatus.authorized:
      return Colors.greenAccent.shade400;
    case AuthorizationStatus.denied:
      return cs.error;
    case AuthorizationStatus.notDetermined:
    case AuthorizationStatus.provisional:
      return Colors.orangeAccent;
  }
}

class DevToolsNotificationSection extends StatefulWidget {
  const DevToolsNotificationSection({super.key});

  @override
  State<DevToolsNotificationSection> createState() =>
      _DevToolsNotificationSectionState();
}

class _DevToolsNotificationSectionState
    extends State<DevToolsNotificationSection> {
  AuthorizationStatus? _permissionStatus;
  String? _tokenPreview;
  String? _lastFcmInitResult;
  int? _lastFcmInitDurationMs;
  bool _loading = true;
  bool _sendingTestNotif = false;
  bool _copyingToken = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        FirebaseMessaging.instance.getNotificationSettings(),
        FcmService.instance.debugGetTokenPreview(),
        DevToolsSyncLogger.instance.getEvents(),
      ]);
      final settings = results[0] as NotificationSettings;
      final preview = results[1] as String?;
      final events = results[2] as List;
      final lastFcm = events
          .cast<dynamic>()
          .where((e) => e.source == 'appStart' && e.feature == 'social') // lint-ignore: widget-no-logic — devtools last-FCM lookup
          .firstOrNull;
      if (mounted) {
        setState(() {
          _permissionStatus = settings.authorizationStatus;
          _tokenPreview = preview;
          _lastFcmInitResult = lastFcm?.result as String?;
          _lastFcmInitDurationMs = lastFcm?.durationMs as int?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMsg = 'Load error: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _copyToken() async {
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: context.l10n.devtoolsNotificationsCopyTokenTitle,
      message: 'The full FCM token will be copied to clipboard. '
          'Treat it like a password — do not share it publicly.',
      confirmLabel: 'Copy',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() { _copyingToken = true; _statusMsg = null; });
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (!mounted) return;
      if (token == null) {
        setState(() => _statusMsg = 'Token unavailable');
        return;
      }
      await Clipboard.setData(ClipboardData(text: token));
      if (mounted) setState(() => _statusMsg = 'Token copied to clipboard');
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _copyingToken = false);
    }
  }

  Future<void> _sendTestNotification() async {
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: context.l10n.devtoolsNotificationsSendTestTitle,
      message: 'Sends a local debug notification. '
          'Does not affect any business state or goal reminder date.',
      confirmLabel: 'Send',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() { _sendingTestNotif = true; _statusMsg = null; });
    try {
      await NotificationService.instance.showDebugTestNotification();
      if (mounted) setState(() => _statusMsg = 'Test notification sent');
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _sendingTestNotif = false);
    }
  }

  Future<void> _toggleBgDebugNotifs(
      DevToolsProvider devTools, bool value) async {
    await devTools.setBgDebugNotificationsEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final devTools = context.watch<DevToolsProvider>();
    final social = context.watch<SocialProvider>();
    final cs = Theme.of(context).colorScheme;

    final canSendTest = devTools.isDebugModeEnabled;

    return DevToolsSectionCard(
      title: context.l10n.devtoolsSectionNotifications,
      children: [
        // ── Service state ─────────────────────────────────────────────────
        DevToolsStatusTile(
          label: 'NotificationService init',
          value: NotificationService.instance.isInitialized ? 'yes' : 'no',
          valueColor: NotificationService.instance.isInitialized
              ? Colors.greenAccent.shade400
              : cs.error,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'FcmService init',
          value: FcmService.instance.isInitialized ? 'yes' : 'no',
          valueColor: FcmService.instance.isInitialized
              ? Colors.greenAccent.shade400
              : cs.error,
        ),
        const DevToolsSectionDivider(),

        // ── FCM permission ────────────────────────────────────────────────
        DevToolsStatusTile(
          label: 'FCM permission',
          value: _loading
              ? 'loading…'
              : (_permissionStatus != null
                  ? _permissionLabel(_permissionStatus!)
                  : '—'),
          valueColor: _loading || _permissionStatus == null
              ? null
              : _permissionColor(_permissionStatus!, cs),
        ),
        const DevToolsSectionDivider(),

        // ── FCM token preview ─────────────────────────────────────────────
        DevToolsStatusTile(
          label: 'FCM token (preview)',
          value: _loading ? 'loading…' : (_tokenPreview ?? 'unavailable'),
        ),
        const DevToolsSectionDivider(),

        // ── Social state ──────────────────────────────────────────────────
        DevToolsStatusTile(
          label: 'Social ready',
          value: social.isReady ? 'yes' : 'no',
          valueColor:
              social.isReady ? Colors.greenAccent.shade400 : Colors.orangeAccent,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Backend ready',
          value: social.backendReady ? 'yes' : 'no',
          valueColor: social.backendReady
              ? Colors.greenAccent.shade400
              : Colors.orangeAccent,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Backend message',
          value: social.backendMessage,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Unread notifications',
          value: '${social.unreadNotificationCount}',
          valueColor: social.unreadNotificationCount > 0
              ? Colors.orangeAccent
              : null,
        ),
        const DevToolsSectionDivider(),
        if (social.error != null) ...[
          DevToolsStatusTile(
            label: 'Social error',
            value: social.error!,
            valueColor: cs.error,
          ),
          const DevToolsSectionDivider(),
        ],

        // ── FCM init event ────────────────────────────────────────────────
        DevToolsStatusTile(
          label: 'Last FCM/notif init',
          value: _lastFcmInitResult != null
              ? '$_lastFcmInitResult  ${_lastFcmInitDurationMs != null ? '${_lastFcmInitDurationMs}ms' : ''}'
              : '—',
          valueColor: _lastFcmInitResult == 'failure' ? cs.error : null,
        ),
        const DevToolsSectionDivider(),

        // ── Debug notifications toggle ────────────────────────────────────
        DevToolsStatusTile(
          label: 'BG debug notifications',
          value: devTools.isBgDebugNotificationsEnabled ? 'ON' : 'OFF',
          valueColor: devTools.isBgDebugNotificationsEnabled
              ? Colors.greenAccent.shade400
              : null,
        ),
        const DevToolsSectionDivider(),
        _ToggleTile(
          label: context.l10n.devtoolsNotificationsBgToggleLabel,
          subtitle: devTools.isDebugModeEnabled
              ? 'Sends local notifications at BG sync start/end/failure'
              : 'Enable Debug Mode to unlock',
          value: devTools.isBgDebugNotificationsEnabled,
          isDisabled: !devTools.isDebugModeEnabled,
          onChanged: devTools.isDebugModeEnabled
              ? (v) => _toggleBgDebugNotifs(devTools, v)
              : null,
        ),
        const DevToolsSectionDivider(),

        // ── Status message ────────────────────────────────────────────────
        if (_statusMsg != null) ...[
          DevToolsStatusTile(label: 'Status', value: _statusMsg!),
          const DevToolsSectionDivider(),
        ],

        // ── Actions ───────────────────────────────────────────────────────
        DevToolsActionTile(
          label: 'Refresh diagnostics',
          isLoading: _loading,
          isDisabled: _loading,
          onTap: _loading ? null : _loadDiagnostics,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Refresh Social',
          subtitle: 'Social is stream-based — no pull refresh available',
          isDisabled: true,
          onTap: null,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Copy FCM token',
          subtitle: 'Full token copied to clipboard after confirmation',
          isLoading: _copyingToken,
          isDisabled: _loading || _copyingToken || _tokenPreview == null,
          onTap: (!_loading && !_copyingToken && _tokenPreview != null)
              ? _copyToken
              : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Send debug test notification',
          subtitle: canSendTest
              ? 'One-off local notification — no business state mutated'
              : 'Enable Debug Mode to unlock',
          isLoading: _sendingTestNotif,
          isDisabled: !canSendTest || _sendingTestNotif,
          onTap: canSendTest && !_sendingTestNotif
              ? _sendTestNotification
              : null,
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    this.subtitle,
    required this.value,
    required this.isDisabled,
    required this.onChanged,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final bool isDisabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDisabled
                        ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                        : cs.onSurface,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: isDisabled ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

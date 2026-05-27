import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../logging/app_log.dart';
import '../navigation/navigator_key.dart';
import 'notification_preferences.dart';
import '../../features/devtools/application/devtools_sync_logger.dart';
import '../../features/devtools/domain/devtools_sync_event.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const _log = 'NotificationService';
  static const _localePrefKey = 'selected_language_code';

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionsRequested = false;

  // Notification ID ranges
  static const _idQuestBase = 2000;
  static const _idAchievementBase = 3000;
  static const _idFriendRequest = 4000;
  static const _idFriendAccepted = 4001;
  static const _idReactionBase = 5000;
  static const _idGoalReminder = 6000;
  static const _idFcmForeground = 7000;
  static const _idDebug = 8000; // DevTools debug notifications — no business state

  // Android notification channels — names + descriptions are localized at
  // [initialize] time so a fresh install on an English device doesn't surface
  // Czech channel names in the system settings. Calling
  // `createNotificationChannel` with the same id on Android 8+ updates the
  // displayed name/description, so subsequent app launches with a different
  // locale also stay in sync.
  AndroidNotificationChannel _chProgression = const AndroidNotificationChannel(
    'progression',
    'Progress',
    description: 'Completed quests and unlocked achievements',
    importance: Importance.defaultImportance,
  );
  AndroidNotificationChannel _chSocial = const AndroidNotificationChannel(
    'social',
    'Social',
    description: 'Friend requests and reactions to posts',
    importance: Importance.high,
  );
  AndroidNotificationChannel _chReminders = const AndroidNotificationChannel(
    'reminders',
    'Reminders',
    description: 'Daily goal reminders',
    importance: Importance.defaultImportance,
  );
  static const _chDebug = AndroidNotificationChannel(
    'devtools_debug',
    'DevTools Debug',
    description: 'Debug notifications — only visible when DevTools debug mode is ON',
    importance: Importance.low,
  );

  /// Loads [AppLocalizations] for the user's selected language, or the system
  /// locale when no explicit choice is persisted, falling back to English when
  /// neither matches a supported locale. Mirrors the resolution logic in
  /// `MaterialApp.localeResolutionCallback` so notifications stay in sync
  /// with the on-screen UI — including from background isolates that have
  /// no [BuildContext].
  Future<AppLocalizations> _resolveL10n() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefKey);
    Locale locale;
    if (code != null) {
      locale = Locale(code);
    } else {
      final system = PlatformDispatcher.instance.locale;
      locale = AppLocalizations.supportedLocales.firstWhere(
        (l) => l.languageCode == system.languageCode,
        orElse: () => const Locale('en'),
      );
    }
    return AppLocalizations.delegate.load(locale);
  }

  // ─── Debug/diagnostic getters (read-only) ────────────────────────────────
  bool get isInitialized => _initialized;

  /// Main notification initialization.
  ///
  /// [requestPermissions] must be true only from normal app startup / foreground.
  /// Do not request permissions from WorkManager or FCM background isolates.
  Future<void> initialize({
    bool requestPermissions = false,
  }) async {
    try {
      if (!_initialized) {
        final initStart = DateTime.now();
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        const settings = InitializationSettings(android: android);

        await _plugin.initialize(
          settings,
          onDidReceiveNotificationResponse: (response) {
            handleNotificationTap(response.payload);
          },
        );

        await refreshChannelLocalization();

        _initialized = true;

        AppLog.app.debug('$_log: initialized');
        unawaited(DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
          timestamp: initStart,
          source: 'appStart',
          feature: 'social',
          result: 'success',
          durationMs: DateTime.now().difference(initStart).inMilliseconds,
        )));
      }

      if (requestPermissions && !_permissionsRequested) {
        await requestNotificationPermissions();
      }
    } catch (e, st) {
      AppLog.app.error(
        '$_log: initialize failed',
        err: e,
        stackTrace: st,
      );
      unawaited(DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
        timestamp: DateTime.now(),
        source: 'appStart',
        feature: 'social',
        result: 'failure',
        errorMessage: e.toString(),
      )));
      rethrow;
    }
  }

  /// Call only from foreground app startup / settings screen.
  Future<void> requestNotificationPermissions() async {
    if (!await NotificationPreferences.areEnabled()) {
      AppLog.app.info('$_log: permission request skipped, notifications off');
      return;
    }
    if (_permissionsRequested) {
      AppLog.app.debug('$_log: permission already requested this session');
      return;
    }

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final granted = await androidPlugin?.requestNotificationsPermission();

      _permissionsRequested = true;

      AppLog.app.info('$_log: Android notification permission granted=$granted');
    } catch (e, st) {
      AppLog.app.error(
        '$_log: requestNotificationPermissions failed',
        err: e,
        stackTrace: st,
      );
    }
  }

  /// Rebuilds the localized progression / social / reminders channels from
  /// the current locale and (re-)registers them with Android. Safe to call
  /// repeatedly — on Android 8+ `createNotificationChannel` updates an
  /// existing channel's name/description in place. Invoked at [initialize]
  /// and again when the user switches language in settings.
  Future<void> refreshChannelLocalization() async {
    final l10n = await _resolveL10n();

    _chProgression = AndroidNotificationChannel(
      _chProgression.id,
      l10n.notifChannelProgressionName,
      description: l10n.notifChannelProgressionDescription,
      importance: _chProgression.importance,
    );
    _chSocial = AndroidNotificationChannel(
      _chSocial.id,
      l10n.notifChannelSocialName,
      description: l10n.notifChannelSocialDescription,
      importance: _chSocial.importance,
    );
    _chReminders = AndroidNotificationChannel(
      _chReminders.id,
      l10n.notifChannelRemindersName,
      description: l10n.notifChannelRemindersDescription,
      importance: _chReminders.importance,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_chProgression);
    await androidPlugin?.createNotificationChannel(_chSocial);
    await androidPlugin?.createNotificationChannel(_chReminders);
    await androidPlugin?.createNotificationChannel(_chDebug);
  }

  /// Parses notification payload and switches tab.
  void handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      switch (data['type'] as String?) {
        case 'quest':
          pendingTabSwitch.value = 1;
          break;
        case 'achievement':
          pendingTabSwitch.value = 2;
          break;
        case 'friend_request':
        case 'reaction':
          pendingTabSwitch.value = 3;
          break;
        case 'goal_reminder':
          pendingTabSwitch.value = 0;
          break;
      }
    } catch (e, st) {
      AppLog.app.error(
        '$_log: invalid notification payload=$payload',
        err: e,
        stackTrace: st,
      );
    }
  }

  Future<void> showQuestCompleted(
    String questTitle,
    int xp, {
    int index = 0,
  }) async {
    if (!await NotificationPreferences.isAllowed(
        NotificationCategory.progression)) {
      return;
    }
    await initialize();
    final l10n = await _resolveL10n();

    return _plugin.show(
      _idQuestBase + index,
      l10n.notifQuestCompletedTitle,
      l10n.notifQuestCompletedBody(questTitle, xp),
      _details(_chProgression),
      payload: jsonEncode({'type': 'quest'}),
    );
  }

  Future<void> showAchievementUnlocked(
    String title,
    String description, {
    int index = 0,
  }) async {
    if (!await NotificationPreferences.isAllowed(
        NotificationCategory.progression)) {
      return;
    }
    await initialize();
    final l10n = await _resolveL10n();

    return _plugin.show(
      _idAchievementBase + index,
      l10n.notifAchievementUnlockedTitle,
      l10n.notifAchievementUnlockedBody(title, description),
      _details(_chProgression),
      payload: jsonEncode({'type': 'achievement'}),
    );
  }

  Future<void> showFriendRequest(String fromName) async {
    if (!await NotificationPreferences.isAllowed(
        NotificationCategory.social)) {
      return;
    }
    await initialize();
    final l10n = await _resolveL10n();

    return _plugin.show(
      _idFriendRequest,
      l10n.notifFriendRequestTitle,
      l10n.notifFriendRequestBody(fromName),
      _details(
        _chSocial,
        importance: Importance.high,
        priority: Priority.high,
      ),
      payload: jsonEncode({'type': 'friend_request'}),
    );
  }

  Future<void> showFriendRequestAccepted(String byName) async {
    if (!await NotificationPreferences.isAllowed(
        NotificationCategory.social)) {
      return;
    }
    await initialize();
    final l10n = await _resolveL10n();

    return _plugin.show(
      _idFriendAccepted,
      l10n.notifFriendRequestAcceptedTitle,
      l10n.notifFriendRequestAcceptedBody(byName),
      _details(
        _chSocial,
        importance: Importance.high,
        priority: Priority.high,
      ),
      payload: jsonEncode({'type': 'friend_request'}),
    );
  }

  Future<void> showReaction(
    String actorName,
    String emoji,
    String achievementTitle, {
    int index = 0,
  }) async {
    if (!await NotificationPreferences.isAllowed(
        NotificationCategory.social)) {
      return;
    }
    await initialize();
    final l10n = await _resolveL10n();

    return _plugin.show(
      _idReactionBase + index,
      l10n.notifReactionTitle(actorName, emoji),
      achievementTitle,
      _details(
        _chSocial,
        importance: Importance.high,
        priority: Priority.high,
      ),
      payload: jsonEncode({'type': 'reaction'}),
    );
  }

  /// Returns payload of notification that launched the app.
  /// Call only once during normal app startup, not from background isolate.
  Future<String?> getLaunchDetails() async {
    await initialize();

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;

    return details.notificationResponse?.payload;
  }

  /// Shows a debug-only local notification. Does NOT update any business state
  /// (no last_goal_reminder_date or other SharedPreferences side effects).
  Future<void> showDebugNotification({
    required String title,
    required String body,
  }) async {
    if (!await NotificationPreferences.areEnabled()) return;
    await initialize();
    return _plugin.show(
      _idDebug,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chDebug.id,
          _chDebug.name,
          channelDescription: _chDebug.description,
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      payload: null, // no tap handler — no tab switch
    );
  }

  /// DevTools test notification. Wraps [showDebugNotification].
  Future<void> showDebugTestNotification() => showDebugNotification(
        title: '[DevTools] Test notification',
        body: 'Debug test — no business state mutated',
      );

  Future<void> showGoalReminder() async {
    if (!await NotificationPreferences.isAllowed(
        NotificationCategory.reminders)) {
      return;
    }
    await initialize();
    final l10n = await _resolveL10n();

    return _plugin.show(
      _idGoalReminder,
      l10n.notifGoalReminderTitle,
      l10n.notifGoalReminderBody,
      _details(_chReminders),
      payload: jsonEncode({'type': 'goal_reminder'}),
    );
  }

  /// Shows FCM message received while app is in foreground.
  /// Android does not display foreground FCM notification automatically.
  Future<void> showFcmMessage(String title, String body, String? type) async {
    final category = _categoryForFcmType(type);
    if (!await NotificationPreferences.isAllowed(category)) return;
    await initialize();

    final channel = category == NotificationCategory.social
        ? _chSocial
        : (category == NotificationCategory.reminders
            ? _chReminders
            : _chProgression);

    final isSocial = channel.id == _chSocial.id;

    return _plugin.show(
      _idFcmForeground,
      title,
      body,
      _details(
        channel,
        importance:
            isSocial ? Importance.high : Importance.defaultImportance,
        priority: isSocial ? Priority.high : Priority.defaultPriority,
      ),
      payload: type != null ? jsonEncode({'type': type}) : null,
    );
  }

  NotificationCategory _categoryForFcmType(String? type) {
    switch (type) {
      case 'friend_request':
      case 'reaction':
        return NotificationCategory.social;
      case 'goal_reminder':
        return NotificationCategory.reminders;
      case 'quest':
      case 'achievement':
      default:
        return NotificationCategory.progression;
    }
  }

  NotificationDetails _details(
    AndroidNotificationChannel channel, {
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: importance,
        priority: priority,
      ),
    );
  }
}

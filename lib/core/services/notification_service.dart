import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../logging/app_log.dart';
import '../navigation/navigator_key.dart';
import '../../features/devtools/application/devtools_sync_logger.dart';
import '../../features/devtools/domain/devtools_sync_event.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const _log = 'NotificationService';

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

  // Android notification channels
  static const _chProgression = AndroidNotificationChannel(
    'progression',
    'Postup',
    description: 'Dokončené questy a odemčené achievementy',
    importance: Importance.defaultImportance,
  );

  static const _chSocial = AndroidNotificationChannel(
    'social',
    'Sociální',
    description: 'Žádosti o přátelství a reakce na příspěvky',
    importance: Importance.high,
  );

  static const _chReminders = AndroidNotificationChannel(
    'reminders',
    'Připomínky',
    description: 'Denní připomínky cílů',
    importance: Importance.defaultImportance,
  );

  static const _chDebug = AndroidNotificationChannel(
    'devtools_debug',
    'DevTools Debug',
    description: 'Debug notifications — only visible when DevTools debug mode is ON',
    importance: Importance.low,
  );

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

        await _createAndroidChannels();

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

  Future<void> _createAndroidChannels() async {
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
    await initialize();

    return _plugin.show(
      _idQuestBase + index,
      'Quest dokončen! 🏆',
      '$questTitle · +$xp XP',
      _details(_chProgression),
      payload: jsonEncode({'type': 'quest'}),
    );
  }

  Future<void> showAchievementUnlocked(
    String title,
    String description, {
    int index = 0,
  }) async {
    await initialize();

    return _plugin.show(
      _idAchievementBase + index,
      'Achievement odemčen! ⚔️',
      '$title – $description',
      _details(_chProgression),
      payload: jsonEncode({'type': 'achievement'}),
    );
  }

  Future<void> showFriendRequest(String fromName) async {
    await initialize();

    return _plugin.show(
      _idFriendRequest,
      'Žádost o přátelství',
      '$fromName ti poslal/a žádost o přátelství',
      _details(
        _chSocial,
        importance: Importance.high,
        priority: Priority.high,
      ),
      payload: jsonEncode({'type': 'friend_request'}),
    );
  }

  Future<void> showFriendRequestAccepted(String byName) async {
    await initialize();

    return _plugin.show(
      _idFriendAccepted,
      'Žádost o přátelství přijata',
      '$byName přijal/a tvoji žádost',
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
    await initialize();

    return _plugin.show(
      _idReactionBase + index,
      '$actorName reagoval/a $emoji',
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
    await initialize();

    return _plugin.show(
      _idGoalReminder,
      'Jak jde dnešek? 🎯',
      'Nezapomeň splnit svoje denní cíle',
      _details(_chReminders),
      payload: jsonEncode({'type': 'goal_reminder'}),
    );
  }

  /// Shows FCM message received while app is in foreground.
  /// Android does not display foreground FCM notification automatically.
  Future<void> showFcmMessage(String title, String body, String? type) async {
    await initialize();

    final channel = (type == 'friend_request' || type == 'reaction')
        ? _chSocial
        : _chProgression;

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
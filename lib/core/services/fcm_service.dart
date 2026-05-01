import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_log.dart';
import 'notification_service.dart';
import '../../features/devtools/application/devtools_sync_logger.dart';
import '../../features/devtools/domain/devtools_sync_event.dart';

/// Returns the same canonical UID as AuthUser.fromFirebase – Google subject ID
/// when present, falling back to Firebase Auth UID.
///
/// Important: Cloud Functions and client writes must use the same UID.
String canonicalUid(User user) {
  for (final provider in user.providerData) {
    if (provider.providerId == 'google.com' &&
        (provider.uid?.isNotEmpty ?? false)) {
      return provider.uid!;
    }
  }

  return user.uid;
}

/// Top-level handler called by the OS when an FCM message arrives while the app
/// is in background or terminated.
///
/// Must be top-level and marked with @pragma.
///
/// Important:
/// Do NOT show a local notification here when the FCM payload contains
/// `notification.title/body`. Android displays that notification automatically
/// in background/killed state. Showing it manually here causes duplicates.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    AppLog.app.info(
      'FcmService: background message received '
      'id=${message.messageId} '
      'type=${message.data['type']} '
      'hasNotification=${message.notification != null} '
      'title=${message.notification?.title != null}',
      payload: _safeMessageDebugPayload(message),
    );

    // Do not mirror the FCM payload here.
    // Android shows FCM notification payload automatically in background.
  } catch (e, st) {
    AppLog.app.error(
      'FcmService: background handler failed',
      err: e,
      stackTrace: st,
    );
  }
}

Future<void> _logSuppressedForegroundMessage(RemoteMessage message) async {
  final title = message.notification?.title;
  final body = message.notification?.body;
  final type = message.data['type'] as String?;

  if (title == null || body == null) {
    AppLog.app.debug(
      'FcmService: skipped foreground message without notification title/body '
      'id=${message.messageId} type=$type',
      payload: _safeMessageDebugPayload(message),
    );
    return;
  }

  AppLog.app.info(
    'FcmService: foreground notification suppressed '
    'id=${message.messageId} type=$type title=$title',
    payload: _safeMessageDebugPayload(message),
  );
}

Map<String, Object?> _safeMessageDebugPayload(RemoteMessage message) {
  return {
    'messageId': message.messageId,
    'sentTime': message.sentTime?.toIso8601String(),
    'from': message.from,
    'category': message.category,
    'collapseKey': message.collapseKey,
    'data': message.data,
    'notificationTitle': message.notification?.title,
    'notificationBody': message.notification?.body,
    'androidChannelId': message.notification?.android?.channelId,
    'androidClickAction': message.notification?.android?.clickAction,
  };
}

class FcmService {
  FcmService._();

  static final instance = FcmService._();

  static const _log = 'FcmService';

  bool _initialized = false;

  // ─── Debug/diagnostic getters (read-only) ────────────────────────────────
  bool get isInitialized => _initialized;

  /// Returns a masked preview of the FCM token: first 6 + last 4 chars.
  /// Never returns the full token. Returns null if unavailable.
  Future<String?> debugGetTokenPreview() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return null;
      if (token.length <= 10) return '(${token.length} chars)';
      return '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (_initialized) {
      AppLog.app.debug('$_log: initialize skipped, already initialized');
      return;
    }

    final initStart = DateTime.now();
    _initialized = true;

    AppLog.app.info('$_log: initialize start');

    await _requestNotificationPermission();

    // Foreground messages stay in-app only; Android does not display the FCM
    // notification automatically here and we intentionally do not mirror it.
    FirebaseMessaging.onMessage.listen((message) async {
      AppLog.app.info(
        '$_log: foreground message received '
        'id=${message.messageId} '
        'type=${message.data['type']} '
        'hasNotification=${message.notification != null}',
        payload: _safeMessageDebugPayload(message),
      );

      await _logSuppressedForegroundMessage(message);
    });

    // User tapped a notification while the app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLog.app.info(
        '$_log: opened from background notification '
        'id=${message.messageId} type=${message.data['type']}',
        payload: _safeMessageDebugPayload(message),
      );

      NotificationService.instance.handleNotificationTap(
        jsonEncode(message.data),
      );
    });

    // User launched the app by tapping a notification while the app was killed.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      AppLog.app.info(
        '$_log: launched from terminated notification '
        'id=${initialMessage.messageId} type=${initialMessage.data['type']}',
        payload: _safeMessageDebugPayload(initialMessage),
      );

      NotificationService.instance.handleNotificationTap(
        jsonEncode(initialMessage.data),
      );
    } else {
      AppLog.app.debug('$_log: no initial notification message');
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final uid = canonicalUid(currentUser);

      AppLog.app.info(
        '$_log: saving token for already signed-in user '
        'uid=$uid firebaseUid=${currentUser.uid}',
      );

      await _refreshTokenForUser(currentUser);
    } else {
      AppLog.app.debug('$_log: no signed-in user during initialize');
    }

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        AppLog.app.debug('$_log: auth state changed, no user');
        return;
      }

      final uid = canonicalUid(user);

      AppLog.app.info(
        '$_log: auth state changed, saving token '
        'uid=$uid firebaseUid=${user.uid}',
      );

      await _refreshTokenForUser(user);
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLog.app.warn('$_log: token refreshed but no signed-in user');
        return;
      }

      final uid = canonicalUid(user);

      AppLog.app.info(
        '$_log: token refreshed uid=$uid token=${_maskToken(token)}',
      );

      await _saveToken(uid, token);
    });

    AppLog.app.success('$_log: initialize done');
    unawaited(DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
      timestamp: initStart,
      source: 'appStart',
      feature: 'social',
      result: 'success',
      durationMs: DateTime.now().difference(initStart).inMilliseconds,
    )));
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      AppLog.app.info(
        '$_log: notification permission=${settings.authorizationStatus}',
      );
    } catch (e, st) {
      AppLog.app.error(
        '$_log: requestPermission failed',
        err: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshTokenForUser(User user) async {
    final uid = canonicalUid(user);

    try {
      AppLog.app.debug('$_log: getToken start uid=$uid');

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        AppLog.app.warn('$_log: getToken returned null for uid=$uid');
        return;
      }

      AppLog.app.info(
        '$_log: getToken success uid=$uid token=${_maskToken(token)}',
      );

      await _saveToken(uid, token);
    } catch (e, st) {
      AppLog.app.error(
        '$_log: getToken failed for uid=$uid',
        err: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locale = prefs.getString('selected_language_code') ?? 'cs';

      AppLog.app.debug(
        '$_log: saving token to Firestore uid=$uid locale=$locale',
      );

      await FirebaseFirestore.instance.doc('users/$uid').set({
        'fcmToken': token,
        'locale': locale,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLog.app.success(
        '$_log: token saved uid=$uid locale=$locale '
        'token=${_maskToken(token)}',
      );
    } catch (e, st) {
      AppLog.app.error(
        '$_log: saveToken failed for uid=$uid',
        err: e,
        stackTrace: st,
      );
    }
  }

  Future<void> saveCurrentUserLocale(String localeCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLog.app.warn('$_log: saveLocale skipped, no signed-in user');
        return;
      }

      final uid = canonicalUid(user);

      await FirebaseFirestore.instance.doc('users/$uid').set({
        'locale': localeCode,
      }, SetOptions(merge: true));

      AppLog.app.debug(
        '$_log: locale saved uid=$uid locale=$localeCode',
      );
    } catch (e, st) {
      AppLog.app.error(
        '$_log: saveLocale failed',
        err: e,
        stackTrace: st,
      );
    }
  }

  /// Kept only for backwards compatibility.
  /// Prefer saveCurrentUserLocale() to avoid Firebase UID vs Google UID mismatch.
  Future<void> saveLocale(String uid, String localeCode) async {
    AppLog.app.warn(
      '$_log: saveLocale(uid, localeCode) is deprecated. '
      'Use saveCurrentUserLocale(localeCode) instead.',
    );

    try {
      await FirebaseFirestore.instance.doc('users/$uid').set({
        'locale': localeCode,
      }, SetOptions(merge: true));

      AppLog.app.debug(
        '$_log: locale saved uid=$uid locale=$localeCode',
      );
    } catch (e, st) {
      AppLog.app.error(
        '$_log: saveLocale failed for uid=$uid',
        err: e,
        stackTrace: st,
      );
    }
  }
}

String _maskToken(String token) {
  if (token.length <= 10) return '${token.length} chars';
  return '${token.substring(0, 10)}...';
}

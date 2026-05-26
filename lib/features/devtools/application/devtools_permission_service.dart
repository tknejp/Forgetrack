import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/build_config.dart';
import '../../../core/errors/firebase_error_classifier.dart';
import '../../../core/logging/app_log.dart';

/// Controls who can open Developer Tools.
///
/// Access is granted in three layers (first hit wins):
/// 1. `BuildConfig.isDev` — dev flavor always has access.
/// 2. Hardcoded UID allowlist — offline fallback, baked into the prod
///    binary. Used when a developer's own device needs guaranteed
///    access even with Firestore unreachable.
/// 3. Firestore `devUsers/{uid}` lookup — runtime grant without
///    rebuild. Trello #106 (2026-05-27).
///
/// **Why a [ChangeNotifier], not the previous static class?** A new
/// remote grant arriving from Firestore needs to trigger a UI rebuild
/// so the entry tile appears in Settings without an app restart. Static
/// state would require a separate notifier signal anyway; promoting
/// the service itself is cheaper and keeps the access decision local
/// to one class. Callers resolve the service via `context.watch`
/// against [DevToolsPermissionService] and call [hasAccess] on it.
///
/// **Cache shape.** A single uid → granted bit + last-check timestamp
/// in [SharedPreferences]. Only the active (bound) uid is cached —
/// caching multiple uids is over-engineering for an app where the
/// signed-in user is the sole relevant subject. Cache survives app
/// restart so a dev opening the app offline still gets in (assuming
/// they were granted at least once before going offline).
///
/// **Failure handling.** Firestore errors are classified via
/// [classifyFirebaseError] and logged through [AppLog.sync]. The
/// cached value (if any) stays as-is; a transient outage never
/// downgrades a previously-granted user mid-session.
class DevToolsPermissionService extends ChangeNotifier {
  DevToolsPermissionService({
    FirebaseFirestore? firestore,
    Set<String> hardcodedUids = _defaultHardcodedUids,
  })  : _firestore = firestore,
        _hardcodedUids = hardcodedUids;

  /// Firebase UIDs baked into the binary — offline fallback for the
  /// primary developer (so a fresh prod build on the dev's device
  /// still works before Firestore replies). Add your own here only
  /// if you need guaranteed access without a network round-trip;
  /// otherwise prefer adding a `devUsers/{uid}` doc.
  static const Set<String> _defaultHardcodedUids = {
    'ZolbJyQwpzSuUDsCV09UDwWXgX93',
  };

  static const _prefRemoteGrantedUid = 'devtools_remote_granted_uid';
  static const _prefRemoteGrantedAt = 'devtools_remote_granted_checked_at_ms';

  final FirebaseFirestore? _firestore;
  final Set<String> _hardcodedUids;

  String? _grantedUid;
  DateTime? _grantedAt;
  String? _boundUid;
  Future<void>? _refreshInFlight;

  /// Hydrates the cache from [SharedPreferences]. Call once during app
  /// boot before binding to auth so the first `hasAccess` call after
  /// a relaunch returns the previous session's verdict even before
  /// Firestore replies.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_prefRemoteGrantedUid);
      final atMs = prefs.getInt(_prefRemoteGrantedAt);
      if (uid != null && uid.isNotEmpty) {
        _grantedUid = uid;
        _grantedAt = atMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(atMs);
      }
    } catch (error, st) {
      AppLog.sync.warn(
        'devtools permission hydrate failed',
        payload: 'error=$error',
      );
      AppLog.sync.debug('devtools permission hydrate stack', payload: st);
    }
  }

  /// Returns true if [firebaseUid] may open DevTools. Synchronous —
  /// reads only the in-memory cache + compile-time fallbacks. Safe to
  /// call from inside `build()`.
  bool hasAccess(String? firebaseUid) {
    if (BuildConfig.isDev) return true;
    if (firebaseUid == null || firebaseUid.isEmpty) return false;
    if (_hardcodedUids.contains(firebaseUid)) return true;
    return _grantedUid == firebaseUid;
  }

  /// True iff this uid's access came from the live Firestore lookup.
  /// Exposed for the DevTools "access reason" status tile so the
  /// developer can tell hardcoded vs runtime grant apart.
  bool isRemoteGrant(String? firebaseUid) {
    if (firebaseUid == null || firebaseUid.isEmpty) return false;
    if (_hardcodedUids.contains(firebaseUid)) return false;
    return _grantedUid == firebaseUid;
  }

  /// Timestamp of the last successful Firestore refresh, or null if
  /// the cache has never been populated.
  DateTime? get lastCheckedAt => _grantedAt;

  /// Binds the service to the active uid. Triggers an async Firestore
  /// refresh against `devUsers/{uid}` when the bound uid changes.
  /// No-op when Firestore is unavailable (`_firestore == null`) —
  /// hardcoded + dev-flavor fallbacks still cover the developer's own
  /// device.
  void bindUser(String? uid) {
    if (uid == _boundUid) return;
    _boundUid = uid;
    if (uid == null || uid.isEmpty) return;
    final firestore = _firestore;
    if (firestore == null) return;
    if (_refreshInFlight != null) return;
    _refreshInFlight = _refresh(uid, firestore)
        .whenComplete(() => _refreshInFlight = null);
  }

  Future<void> _refresh(String uid, FirebaseFirestore firestore) async {
    try {
      final snap =
          await firestore.collection('devUsers').doc(uid).get();
      final enabled = snap.exists && snap.data()?['enabled'] == true;
      final now = DateTime.now();
      final changed = enabled
          ? _grantedUid != uid
          : _grantedUid == uid;

      if (enabled) {
        _grantedUid = uid;
      } else if (_grantedUid == uid) {
        _grantedUid = null;
      }
      _grantedAt = now;

      await _persist();
      if (changed) {
        AppLog.sync.info(
          'devtools remote grant ${enabled ? "ON" : "OFF"}',
          payload: 'uid=$uid',
        );
        notifyListeners();
      } else {
        AppLog.sync.debug(
          'devtools remote grant unchanged',
          payload: 'uid=$uid enabled=$enabled',
        );
      }
    } catch (error, stackTrace) {
      final classified = classifyFirebaseError(
        error,
        stackTrace,
        endpoint: 'devtools.devUsers.refresh',
      );
      if (classified.isTransient) {
        AppLog.sync.warn(
          'devtools remote grant refresh transient',
          payload: 'uid=$uid error=${classified.label}',
        );
      } else {
        AppLog.sync.error(
          'devtools remote grant refresh permanent',
          payload: 'uid=$uid error=${classified.label}',
          err: classified.originalError,
          stackTrace: classified.stackTrace,
        );
      }
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _grantedUid;
      if (uid == null) {
        await prefs.remove(_prefRemoteGrantedUid);
      } else {
        await prefs.setString(_prefRemoteGrantedUid, uid);
      }
      final at = _grantedAt;
      if (at == null) {
        await prefs.remove(_prefRemoteGrantedAt);
      } else {
        await prefs.setInt(
          _prefRemoteGrantedAt,
          at.millisecondsSinceEpoch,
        );
      }
    } catch (error) {
      AppLog.sync.warn(
        'devtools permission persist failed',
        payload: 'error=$error',
      );
    }
  }
}

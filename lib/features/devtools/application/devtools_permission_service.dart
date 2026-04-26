import 'package:flutter/foundation.dart';

/// Controls who can open Developer Tools.
///
/// Access is granted if the app runs in debug mode, or if the current
/// Firebase Auth UID is listed in [_developerUids].
///
/// This is the single place for that check — do not scatter UID comparisons
/// across UI files.
///
/// TODO: Add Firestore devUsers/{uid} lookup to support runtime grants without
/// a rebuild.
class DevToolsPermissionService {
  DevToolsPermissionService._();

  /// Firebase Auth UIDs that can access DevTools in release/profile builds.
  /// Add your own Firebase UID here to enable access on a physical device.
  static const Set<String> _developerUids = {
    'ZolbJyQwpzSuUDsCV09UDwWXgX93',
  };

  /// Returns true if [firebaseUid] is allowed to open Developer Tools.
  ///
  /// Always true in debug mode. In release/profile: only if the UID is in
  /// [_developerUids].
  static bool hasAccess(String? firebaseUid) {
    if (kDebugMode) return true;
    if (firebaseUid == null || firebaseUid.isEmpty) return false;
    return _developerUids.contains(firebaseUid);
  }
}

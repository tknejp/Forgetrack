/// Identifies a single phase of the factory reset orchestration.
///
/// The order in this enum matches the on-screen progress list and the
/// execution order in [FactoryResetService.run]. Add new steps in the
/// position where they should run; the UI iterates the enum directly.
enum FactoryResetStep {
  cancelBackgroundSync,
  captureUid,
  firestorePurge,
  kalorickeTabulkyLogout,
  googleSheetsExportReset,
  googleAccountDisconnect,
  firebaseSignOut,
  clearLocalDatabases,
  clearSharedPreferences,
  clearSecureStorage,
  healthConnectRevoke,
  resetProviders,
  openHealthConnectSettings,
}

extension FactoryResetStepLabel on FactoryResetStep {
  /// Short human-readable label for UI rows. Dev-only, English only.
  String get label {
    switch (this) {
      case FactoryResetStep.cancelBackgroundSync:
        return 'Cancel background sync (WorkManager)';
      case FactoryResetStep.captureUid:
        return 'Capture current uid';
      case FactoryResetStep.firestorePurge:
        return 'Purge Firestore user data';
      case FactoryResetStep.kalorickeTabulkyLogout:
        return 'Log out from Kaloricke Tabulky';
      case FactoryResetStep.googleSheetsExportReset:
        return 'Clear Google Sheets export state';
      case FactoryResetStep.googleAccountDisconnect:
        return 'Disconnect Google account';
      case FactoryResetStep.firebaseSignOut:
        return 'Firebase sign-out';
      case FactoryResetStep.clearLocalDatabases:
        return 'Clear local Isar databases';
      case FactoryResetStep.clearSharedPreferences:
        return 'Clear SharedPreferences';
      case FactoryResetStep.clearSecureStorage:
        return 'Clear SecureStorage';
      case FactoryResetStep.healthConnectRevoke:
        return 'Revoke Health Connect permissions';
      case FactoryResetStep.resetProviders:
        return 'Reset in-memory providers';
      case FactoryResetStep.openHealthConnectSettings:
        return 'Open Health Connect settings';
    }
  }
}

enum FactoryResetStepStatus {
  pending,
  running,
  succeeded,
  skipped,
  failed,
}

class FactoryResetStepResult {
  const FactoryResetStepResult({
    required this.step,
    required this.status,
    required this.elapsed,
    this.note,
    this.errorMessage,
  });

  final FactoryResetStep step;
  final FactoryResetStepStatus status;
  final Duration elapsed;

  /// Optional, free-form note. e.g. "uid=abc123" on captureUid, or
  /// "5 docs deleted" on firestorePurge.
  final String? note;

  /// Populated when [status] is [FactoryResetStepStatus.failed].
  final String? errorMessage;

  bool get isFailure => status == FactoryResetStepStatus.failed;
  bool get isSuccess => status == FactoryResetStepStatus.succeeded;
  bool get isSkipped => status == FactoryResetStepStatus.skipped;
}

class FactoryResetReport {
  const FactoryResetReport({
    required this.results,
    required this.totalElapsed,
    required this.startedAt,
    required this.finishedAt,
  });

  final List<FactoryResetStepResult> results;
  final Duration totalElapsed;
  final DateTime startedAt;
  final DateTime finishedAt;

  int get failureCount => results.where((r) => r.isFailure).length;
  int get successCount => results.where((r) => r.isSuccess).length;
  int get skippedCount => results.where((r) => r.isSkipped).length;
  bool get hasFailures => failureCount > 0;
}

class FactoryResetOptions {
  const FactoryResetOptions({
    this.purgeFirestoreData = false,
    this.openHealthConnectSettings = true,
  });

  /// When true, the reset deletes user-scoped Firestore docs/sub-collections
  /// owned by Forgetrack for the captured uid. Cross-user social documents
  /// (friend_requests, friendships, achievement_shares, handles) are never
  /// touched — destroying them would mutate other users' state.
  final bool purgeFirestoreData;

  /// When true, the reset opens Android Health Connect settings as the
  /// final step so the user can manually verify the permission revoke.
  final bool openHealthConnectSettings;
}

/// Streamed progress update fired by [FactoryResetService.run] before and
/// after each step.
class FactoryResetProgress {
  const FactoryResetProgress({
    required this.step,
    required this.status,
    this.note,
    this.errorMessage,
  });

  final FactoryResetStep step;
  final FactoryResetStepStatus status;
  final String? note;
  final String? errorMessage;
}

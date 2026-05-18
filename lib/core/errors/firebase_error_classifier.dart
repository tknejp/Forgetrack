import 'package:firebase_core/firebase_core.dart';

import 'app_error.dart';

/// Maps a caught exception from a Firebase / Firestore call into an
/// [AppError] subtype, preserving the original error + stack trace so
/// downstream `AppLog` dumps survive.
///
/// Phase 18 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 18) plumbs this through the outermost Firebase boundary
/// (`HybridProgressionEngineRepository` push/pull/wipe) so the sync
/// codepath stops swallowing arbitrary `Object`s.
///
/// **Categorisation table** (FirebaseException.code → AppError):
///   - `unavailable` / `deadline-exceeded` / `cancelled` / `internal` /
///     `aborted` / `resource-exhausted` → [NetworkError](transient).
///   - `permission-denied` / `unauthenticated` → [PermissionError].
///   - `not-found` → [NotFoundError].
///   - `invalid-argument` / `failed-precondition` / `out-of-range`
///     / `already-exists` → [ValidationError].
///   - Anything else → [UpstreamError](transient) so WorkManager keeps
///     retrying until the cause is understood + remapped.
///
/// Non-Firebase exceptions fall through to [UpstreamError].
AppError classifyFirebaseError(
  Object error,
  StackTrace stackTrace, {
  String? endpoint,
}) {
  if (error is FirebaseException) {
    final code = error.code;
    switch (code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
      case 'internal':
      case 'aborted':
      case 'resource-exhausted':
        return NetworkError(
          originalError: error,
          stackTrace: stackTrace,
          endpoint: endpoint,
        );
      case 'permission-denied':
      case 'unauthenticated':
        return PermissionError(
          scope: endpoint ?? 'firebase.${error.plugin}',
          originalError: error,
          stackTrace: stackTrace,
        );
      case 'not-found':
        return NotFoundError(
          entityType: endpoint ?? 'firebase',
          id: error.message ?? '<unknown>',
          originalError: error,
          stackTrace: stackTrace,
        );
      case 'invalid-argument':
      case 'failed-precondition':
      case 'out-of-range':
      case 'already-exists':
        return ValidationError(
          reason: '${error.code}: ${error.message ?? "<no message>"}',
          originalError: error,
          stackTrace: stackTrace,
        );
      default:
        return UpstreamError(
          originalError: error,
          stackTrace: stackTrace,
          context: endpoint == null ? 'firebase' : 'firebase.$endpoint',
        );
    }
  }
  return UpstreamError(
    originalError: error,
    stackTrace: stackTrace,
    context: endpoint,
  );
}

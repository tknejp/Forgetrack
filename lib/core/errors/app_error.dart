import 'package:meta/meta.dart';

/// Sealed hierarchy of categorised errors crossing the app's data-
/// layer boundaries.
///
/// Phase 18 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 18) introduces this so the sync codepath stops swallowing
/// arbitrary `Object`s. Outermost adapters (Firestore gateway, KT
/// HTTP service, BackgroundSync callback) classify exceptions into
/// one of the 5 subtypes; consumers pattern-match on severity to
/// decide WorkManager retry / re-login / surface-as-warning.
///
/// **Scope discipline (per plan).** This hierarchy is the contract
/// for data-layer boundaries. Widget try/catch + UI snackbar
/// handling are explicitly out of scope and stay as-is until a
/// later phase.
@immutable
sealed class AppError {
  const AppError({this.originalError, this.stackTrace});

  /// The exception caught at the boundary, preserved so the original
  /// error survives any classification step. Null when the error was
  /// raised by domain logic (e.g. invalid input) rather than caught
  /// from a lower layer.
  final Object? originalError;

  /// Stack trace captured at the catch site, preserved for debugging
  /// + AppLog dumps. Null for domain-raised errors.
  final StackTrace? stackTrace;

  /// Short label suitable for AppLog payload / DevTools display.
  String get label;

  /// True when the failure is expected to clear on retry (network
  /// blip, Firestore offline, KT 401 needing re-login). False for
  /// permanent failures (permission denied, validation, not found,
  /// unknown upstream).
  ///
  /// `BackgroundSyncService` uses this to decide WorkManager retry
  /// vs early exit; the Firestore gateway uses it to decide whether
  /// to back off or surface.
  bool get isTransient;
}

/// Network-layer failure. Firestore offline, KT 401 / 5xx,
/// connectivity loss, Health Connect quota exceeded.
class NetworkError extends AppError {
  const NetworkError({
    super.originalError,
    super.stackTrace,
    this.isTransient = true,
    this.statusCode,
    this.endpoint,
  });

  /// HTTP status when the wrapped error was an `HttpException` /
  /// `Response`. Firebase errors leave this null (use [originalError]
  /// for codes).
  final int? statusCode;

  /// Optional endpoint hint for logs ("firestore.users.profile",
  /// "kt.diary.day", ...).
  final String? endpoint;

  /// Network failures default to transient. Permanent network
  /// failures (e.g. HTTP 410 Gone) set this to false at the call
  /// site that knows the semantics.
  @override
  final bool isTransient;

  @override
  String get label {
    final parts = <String>['network'];
    if (endpoint != null) parts.add(endpoint!);
    if (statusCode != null) parts.add('http=$statusCode');
    parts.add(isTransient ? 'transient' : 'permanent');
    return parts.join('|');
  }
}

/// Input violated a domain invariant. Always permanent — the caller
/// supplied bad data, retrying won't help.
class ValidationError extends AppError {
  const ValidationError({
    required this.reason,
    super.originalError,
    super.stackTrace,
  });

  final String reason;

  @override
  bool get isTransient => false;

  @override
  String get label => 'validation|$reason';
}

/// User lacks the required permission. Always permanent —
/// re-attempting with the same identity will fail again. Carries
/// [scope] so the surface UI knows what to request (e.g.
/// "health_connect.steps", "firestore.users.write").
class PermissionError extends AppError {
  const PermissionError({
    required this.scope,
    super.originalError,
    super.stackTrace,
  });

  final String scope;

  @override
  bool get isTransient => false;

  @override
  String get label => 'permission|$scope';
}

/// Requested entity does not exist. Always permanent. Carries
/// [entityType] + [id] for diagnostics.
class NotFoundError extends AppError {
  const NotFoundError({
    required this.entityType,
    required this.id,
    super.originalError,
    super.stackTrace,
  });

  final String entityType;
  final String id;

  @override
  bool get isTransient => false;

  @override
  String get label => 'not_found|$entityType:$id';
}

/// Catch-all for failures the adapter could not categorise.
/// Treated as transient by default so WorkManager retries — flip to
/// `isTransient: false` at the call site when the original error
/// signals a permanent failure (e.g. Firestore `permission-denied`
/// that wasn't already mapped to [PermissionError]).
class UpstreamError extends AppError {
  const UpstreamError({
    super.originalError,
    super.stackTrace,
    this.isTransient = true,
    this.context,
  });

  /// Optional human-readable context ("hybrid repo push events",
  /// "social profile upsert", ...).
  final String? context;

  @override
  final bool isTransient;

  @override
  String get label {
    final parts = <String>['upstream'];
    if (context != null) parts.add(context!);
    parts.add(isTransient ? 'transient' : 'permanent');
    return parts.join('|');
  }
}

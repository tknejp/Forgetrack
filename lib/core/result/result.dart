import 'package:meta/meta.dart';

/// Sealed Result-style return type for operations whose failure mode
/// the caller is expected to pattern-match on.
///
/// Phase 18 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 18) ships this so outermost data-layer adapters
/// (`HybridProgressionEngineRepository`, `KalorickeTabulkyService`,
/// `BackgroundSyncService`) stop relying on `try/catch` swallow +
/// `AppLog.warn` patterns that silently bury sync failures.
///
/// **Usage shape.**
/// ```dart
/// final result = await syncBackground();
/// final shouldRetry = switch (result) {
///   Success() => false,
///   Failure(error: final e) => e.isTransient,
/// };
/// ```
///
/// **Scope (per plan).** Domain layer + repository contracts +
/// outermost data layer. Widget `try/catch` blocks and UI snackbar
/// handling stay imperative and out of scope.
@immutable
sealed class Result<T, E> {
  const Result();

  /// Convenience predicate. Use pattern matching when the success
  /// payload is needed.
  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  /// Maps the success payload. No-op on failure.
  Result<U, E> map<U>(U Function(T value) f) => switch (this) {
        Success(value: final v) => Success<U, E>(f(v)),
        Failure(error: final e) => Failure<U, E>(e),
      };

  /// Chains a follow-up operation on success. No-op on failure.
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) f) => switch (this) {
        Success(value: final v) => f(v),
        Failure(error: final e) => Failure<U, E>(e),
      };

  /// Returns the success payload or [fallback] when failed. Eager —
  /// pattern-match yourself if you need lazy fallback construction.
  T unwrapOr(T fallback) => switch (this) {
        Success(value: final v) => v,
        Failure() => fallback,
      };
}

/// Successful result with the produced [value].
final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash(Success, value);

  @override
  String toString() => 'Success($value)';
}

/// Failed result carrying the typed [error].
final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);

  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash(Failure, error);

  @override
  String toString() => 'Failure($error)';
}

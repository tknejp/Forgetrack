import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';

class CosmeticEntitlement {
  const CosmeticEntitlement({
    required this.cosmeticId,
    required this.sourceType,
    this.sourceId,
  });

  final String cosmeticId;
  final String sourceType;
  final String? sourceId;
}

/// Read-side contract for the Firestore-backed cosmetic entitlements
/// store (`users/{uid}/cosmeticEntitlements`).
///
/// **R.4 (2026-05-19) — Result-typed return.** A Firestore read on
/// this collection can transiently fail (offline, deadline-exceeded)
/// or permanently fail (permission-denied on a malformed rule), and
/// the single hot-path consumer ([CosmeticsProvider._applyEntitlements])
/// needs to tell those apart so a transient outage doesn't silently
/// drop a promo grant. The previous shape returned `Future<List<...>>`
/// and the consumer wrapped it in `try/catch` to swallow + warn,
/// which collapsed both failure modes into the same no-op.
///
/// **Trello #82 (2026-05-27) — Realtime stream.** [watchForUser]
/// is the live-subscription variant. The provider subscribes after
/// the initial local load so Cloud-Function–pushed promo grants apply
/// without an app restart. [loadForUser] is retained as a one-shot
/// helper for tests and ad-hoc callers; both shapes use the same
/// classification + filtering rules so a consumer can switch between
/// them without behavioural drift.
abstract class CosmeticEntitlementsSource {
  Future<Result<List<CosmeticEntitlement>, AppError>> loadForUser(String uid);

  /// Live subscription to the entitlements collection. Each emission is
  /// the current authoritative snapshot — consumers should treat it as
  /// the replacement set, not a delta. Stream errors are converted to
  /// `Failure` emissions via [classifyFirebaseError] so subscribers
  /// pattern-match on severity (transient vs permanent) without
  /// catching `Object`. The stream is non-broadcast — one subscription
  /// per uid is expected.
  Stream<Result<List<CosmeticEntitlement>, AppError>> watchForUser(
    String uid,
  );
}

class NoopCosmeticEntitlementsSource implements CosmeticEntitlementsSource {
  const NoopCosmeticEntitlementsSource();

  @override
  Future<Result<List<CosmeticEntitlement>, AppError>> loadForUser(
    String uid,
  ) async {
    return const Success<List<CosmeticEntitlement>, AppError>(
        <CosmeticEntitlement>[]);
  }

  @override
  Stream<Result<List<CosmeticEntitlement>, AppError>> watchForUser(
    String uid,
  ) {
    return Stream<Result<List<CosmeticEntitlement>, AppError>>.value(
      const Success<List<CosmeticEntitlement>, AppError>(
        <CosmeticEntitlement>[],
      ),
    );
  }
}

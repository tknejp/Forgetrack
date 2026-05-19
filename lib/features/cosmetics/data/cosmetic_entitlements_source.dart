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
abstract class CosmeticEntitlementsSource {
  Future<Result<List<CosmeticEntitlement>, AppError>> loadForUser(String uid);
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
}

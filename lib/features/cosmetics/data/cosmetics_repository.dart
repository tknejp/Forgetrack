import '../domain/cosmetic_models.dart';

/// Persistence boundary for the cosmetics feature.
///
/// All implementations must keep [UserCosmeticsState] consistent for a given
/// uid across calls. Mutations should validate against the catalog/config
/// and throw [CosmeticsException] (defined in `cosmetic_models.dart`) for
/// invalid operations rather than silently no-oping.
///
/// TODO(remote): A future Firestore implementation should mirror the
/// progression hybrid pattern — see
/// `lib/features/progression/data/hybrid_progression_repository.dart`
/// and `firestore_progression_gateway.dart` for the local-first + cloud
/// fire-and-forget approach. The social feature
/// (`lib/features/social/data/social_repository_firestore.dart` /
/// `social_repository_disabled.dart`) shows the dual-implementation
/// (enabled/disabled) split for environments without Firebase.
abstract class CosmeticsRepository {
  /// Returns the current state for [uid], creating a default state on first
  /// access. Implementations must never return null.
  Future<UserCosmeticsState> loadForUser(String uid);

  /// Replaces the stored state wholesale. Mostly used by tests / migrations;
  /// normal callers should prefer the targeted mutators below.
  Future<void> saveState(UserCosmeticsState state);

  /// Adds [cosmeticId] to the user's unlocked set. No-op (without throwing)
  /// if already unlocked. Throws [CosmeticsException] if the cosmetic is
  /// unknown or disabled.
  Future<void> unlockCosmetic({
    required String uid,
    required String cosmeticId,
    required String sourceType,
    String? sourceId,
  });

  /// Equips [cosmeticId] in the slot for [type]. Must validate that the
  /// cosmetic exists, is enabled, matches [type], is unlocked for the user,
  /// and that the slot is allowed by the active config. Throws
  /// [CosmeticsException] otherwise.
  Future<void> equipCosmetic({
    required String uid,
    required CosmeticType type,
    required String cosmeticId,
  });

  /// Clears the slot for [type]. Always succeeds (no-op if already empty).
  Future<void> unequipCosmetic({
    required String uid,
    required CosmeticType type,
  });
}

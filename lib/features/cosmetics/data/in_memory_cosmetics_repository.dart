import '../config/cosmetics_config.dart';
import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_unlock_rules.dart';
import 'cosmetics_repository.dart';

/// In-memory implementation of [CosmeticsRepository].
///
/// Suitable for development, tests, and the current placeholder app wiring.
/// State is lost on process restart — replace with an Isar- or
/// Firestore-backed implementation before shipping persisted unlocks.
class InMemoryCosmeticsRepository implements CosmeticsRepository {
  InMemoryCosmeticsRepository({
    CosmeticCatalog catalog = const CosmeticCatalog(),
    CosmeticsConfig? config,
    CosmeticUnlockRules unlockRules = const CosmeticUnlockRules(),
    DateTime Function()? clock,
  })  : _catalog = catalog,
        _config = config ?? CosmeticsConfig.standard(),
        _unlockRules = unlockRules,
        _clock = clock ?? DateTime.now;

  final CosmeticCatalog _catalog;
  final CosmeticsConfig _config;
  final CosmeticUnlockRules _unlockRules;
  final DateTime Function() _clock;
  final Map<String, UserCosmeticsState> _states = <String, UserCosmeticsState>{};

  @override
  Future<UserCosmeticsState> loadForUser(String uid) async {
    final existing = _states[uid];
    if (existing != null) return existing;
    final fresh = _buildDefaultState(uid);
    _states[uid] = fresh;
    return fresh;
  }

  @override
  Future<void> saveState(UserCosmeticsState state) async {
    _states[state.uid] = state;
  }

  @override
  Future<void> unlockCosmetic({
    required String uid,
    required String cosmeticId,
    required String sourceType,
    String? sourceId,
  }) async {
    final definition = _catalog.byId(cosmeticId);
    if (definition == null) {
      throw CosmeticsException(
        'cosmetic_not_found',
        'No cosmetic with id "$cosmeticId"',
      );
    }
    if (!definition.isEnabled) {
      throw CosmeticsException(
        'cosmetic_disabled',
        'Cosmetic "$cosmeticId" is disabled',
      );
    }
    final state = await loadForUser(uid);
    if (state.unlocked.containsKey(cosmeticId)) return;
    final now = _clock();
    final unlocked = Map<String, UnlockedCosmetic>.from(state.unlocked)
      ..[cosmeticId] = UnlockedCosmetic(
        cosmeticId: cosmeticId,
        unlockedAt: now,
        sourceType: sourceType,
        sourceId: sourceId,
      );
    _states[uid] = state.copyWith(unlocked: unlocked, updatedAt: now);
  }

  @override
  Future<void> equipCosmetic({
    required String uid,
    required CosmeticType type,
    required String cosmeticId,
  }) async {
    final definition = _catalog.byId(cosmeticId);
    if (definition == null) {
      throw CosmeticsException(
        'cosmetic_not_found',
        'No cosmetic with id "$cosmeticId"',
      );
    }
    if (!definition.isEnabled) {
      throw CosmeticsException(
        'cosmetic_disabled',
        'Cosmetic "$cosmeticId" is disabled',
      );
    }
    if (definition.type != type) {
      throw CosmeticsException(
        'cosmetic_type_mismatch',
        'Cosmetic "$cosmeticId" is ${definition.type.name}, '
        'cannot equip in ${type.name} slot',
      );
    }
    if (!_isSlotAllowed(type)) {
      throw CosmeticsException(
        'slot_disabled',
        'Slot ${type.name} is not allowed by current config',
      );
    }
    final state = await loadForUser(uid);
    if (!state.unlocked.containsKey(cosmeticId)) {
      throw CosmeticsException(
        'cosmetic_locked',
        'Cosmetic "$cosmeticId" is not unlocked for user "$uid"',
      );
    }
    final now = _clock();
    _states[uid] = state.copyWith(
      equipped: state.equipped.copyWithSlot(type, cosmeticId),
      updatedAt: now,
    );
  }

  @override
  Future<void> unequipCosmetic({
    required String uid,
    required CosmeticType type,
  }) async {
    final state = await loadForUser(uid);
    if (state.equipped.slotId(type) == null) return;
    final now = _clock();
    _states[uid] = state.copyWith(
      equipped: state.equipped.copyWithSlot(type, null),
      updatedAt: now,
    );
  }

  @override
  Future<void> revokeCosmetic({
    required String uid,
    required String cosmeticId,
  }) async {
    final state = await loadForUser(uid);
    if (!state.unlocked.containsKey(cosmeticId)) return;
    final unlocked = Map<String, UnlockedCosmetic>.from(state.unlocked)
      ..remove(cosmeticId);
    var equipped = state.equipped;
    for (final type in CosmeticType.values) {
      if (equipped.slotId(type) == cosmeticId) {
        equipped = equipped.copyWithSlot(type, null);
      }
    }
    final now = _clock();
    _states[uid] = state.copyWith(
      unlocked: unlocked,
      equipped: equipped,
      updatedAt: now,
    );
  }

  @override
  Future<int> clearAllUnlocks(String uid) async {
    final state = await loadForUser(uid);
    final removed = state.unlocked.length;
    if (removed == 0 &&
        CosmeticType.values.every((t) => state.equipped.slotId(t) == null)) {
      return 0;
    }
    final now = _clock();
    _states[uid] = state.copyWith(
      unlocked: const <String, UnlockedCosmetic>{},
      equipped: const EquippedCosmetics.empty(),
      updatedAt: now,
    );
    return removed;
  }

  bool _isSlotAllowed(CosmeticType type) {
    if (_config.allowedSlots.contains(type)) return true;
    if (type == CosmeticType.mapEffect && _config.experimentalTypesEnabled) {
      return true;
    }
    return false;
  }

  UserCosmeticsState _buildDefaultState(String uid) {
    final now = _clock();
    final unlocked = <String, UnlockedCosmetic>{};
    for (final def in _catalog.all) {
      if (!def.isEnabled) continue;
      if (!_unlockRules.isDefaultUnlocked(def.id)) continue;
      unlocked[def.id] = UnlockedCosmetic(
        cosmeticId: def.id,
        unlockedAt: now,
        sourceType: CosmeticUnlockSource.defaultBaseline.name,
      );
    }
    return UserCosmeticsState(
      uid: uid,
      unlocked: unlocked,
      equipped: _config.defaultEquipped,
      updatedAt: now,
    );
  }
}

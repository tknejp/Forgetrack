import '../config/cosmetics_config.dart';
import '../data/cosmetics_repository.dart';
import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_models.dart';

class CosmeticsProgressionResetResult {
  const CosmeticsProgressionResetResult({
    required this.state,
    required this.removedCount,
  });

  final UserCosmeticsState state;
  final int removedCount;
}

/// Pure business layer over [CosmeticCatalog] + [CosmeticsRepository] +
/// [CosmeticsConfig]. Has no Flutter or persistence dependency, so it is
/// trivially unit-testable.
class CosmeticsService {
  CosmeticsService({
    required CosmeticsRepository repository,
    CosmeticCatalog catalog = const CosmeticCatalog(),
    CosmeticsConfig? config,
  })  : _repository = repository,
        _catalog = catalog,
        _config = config ?? CosmeticsConfig.standard();

  final CosmeticsRepository _repository;
  final CosmeticCatalog _catalog;
  final CosmeticsConfig _config;

  CosmeticCatalog get catalog => _catalog;
  CosmeticsConfig get config => _config;

  Future<UserCosmeticsState> load(String uid) => _repository.loadForUser(uid);

  Future<UserCosmeticsState> unlock(
    String uid,
    String cosmeticId, {
    required String sourceType,
    String? sourceId,
  }) async {
    await _repository.unlockCosmetic(
      uid: uid,
      cosmeticId: cosmeticId,
      sourceType: sourceType,
      sourceId: sourceId,
    );
    return _repository.loadForUser(uid);
  }

  Future<CosmeticsProgressionResetResult> resetProgressionUnlocks(
    String uid,
  ) async {
    final state = await _repository.loadForUser(uid);
    final kept = <String, UnlockedCosmetic>{};
    final removedIds = <String>{};

    for (final entry in state.unlocked.entries) {
      if (_isProgressionUnlockSource(entry.value.sourceType)) {
        removedIds.add(entry.key);
      } else {
        kept[entry.key] = entry.value;
      }
    }

    if (removedIds.isEmpty) {
      return CosmeticsProgressionResetResult(
        state: state,
        removedCount: 0,
      );
    }

    var equipped = state.equipped;
    for (final type in CosmeticType.values) {
      final equippedId = equipped.slotId(type);
      if (equippedId != null && removedIds.contains(equippedId)) {
        equipped = equipped.copyWithSlot(type, null);
      }
    }

    final nextState = state.copyWith(
      unlocked: kept,
      equipped: equipped,
      updatedAt: DateTime.now(),
    );
    await _repository.saveState(nextState);
    return CosmeticsProgressionResetResult(
      state: nextState,
      removedCount: removedIds.length,
    );
  }

  Future<UserCosmeticsState> equip(String uid, String cosmeticId) async {
    final definition = _catalog.byId(cosmeticId);
    if (definition == null) {
      throw CosmeticsException(
        'cosmetic_not_found',
        'No cosmetic with id "$cosmeticId"',
      );
    }
    await _repository.equipCosmetic(
      uid: uid,
      type: definition.type,
      cosmeticId: cosmeticId,
    );
    return _repository.loadForUser(uid);
  }

  Future<UserCosmeticsState> unequip(String uid, CosmeticType type) async {
    await _repository.unequipCosmetic(uid: uid, type: type);
    return _repository.loadForUser(uid);
  }

  /// Returns the catalog definitions for whatever is currently equipped, in
  /// slot order. Slots with nothing equipped are skipped.
  List<CosmeticDefinition> getEquippedDefinitions(UserCosmeticsState state) {
    final out = <CosmeticDefinition>[];
    for (final type in CosmeticType.values) {
      final id = state.equipped.slotId(type);
      if (id == null) continue;
      final def = _catalog.byId(id);
      if (def != null) out.add(def);
    }
    return out;
  }

  List<CosmeticDefinition> getUnlockedDefinitions(UserCosmeticsState state) {
    final out = <CosmeticDefinition>[];
    for (final id in state.unlocked.keys) {
      final def = _catalog.byId(id);
      if (def != null) out.add(def);
    }
    out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return out;
  }

  /// All cosmetics of [type] that the user has unlocked and that the config
  /// currently considers usable.
  List<CosmeticDefinition> getAvailableByType(
    UserCosmeticsState state,
    CosmeticType type,
  ) {
    final out = <CosmeticDefinition>[];
    for (final def in _catalog.byType(type)) {
      if (!_config.isUsable(def)) continue;
      if (!state.unlocked.containsKey(def.id)) continue;
      out.add(def);
    }
    out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return out;
  }

  /// Non-throwing pre-equip check. Useful for greying out UI tiles with a
  /// reason tooltip.
  CanEquipResult canEquip(UserCosmeticsState state, String cosmeticId) {
    final def = _catalog.byId(cosmeticId);
    if (def == null) {
      return const CanEquipResult.blocked('cosmetic_not_found');
    }
    if (!def.isEnabled) {
      return const CanEquipResult.blocked('cosmetic_disabled');
    }
    if (!_config.isUsable(def)) {
      return const CanEquipResult.blocked('slot_disabled');
    }
    if (!state.unlocked.containsKey(cosmeticId)) {
      return const CanEquipResult.blocked('cosmetic_locked');
    }
    return const CanEquipResult.ok();
  }

  /// Verifies that every equipped slot points at an unlocked, enabled,
  /// type-correct cosmetic. Drift can happen if a cosmetic is removed from
  /// the catalog while a user has it equipped.
  List<String> validateState(UserCosmeticsState state) {
    final warnings = <String>[];
    for (final type in CosmeticType.values) {
      final id = state.equipped.slotId(type);
      if (id == null) continue;
      final def = _catalog.byId(id);
      if (def == null) {
        warnings.add('Equipped ${type.name} "$id" is not in the catalog');
        continue;
      }
      if (!def.isEnabled) {
        warnings.add('Equipped ${type.name} "$id" is disabled');
      }
      if (def.type != type) {
        warnings.add(
          'Equipped ${type.name} "$id" has wrong type ${def.type.name}',
        );
      }
      if (!state.unlocked.containsKey(id)) {
        warnings.add('Equipped ${type.name} "$id" is not in unlocked set');
      }
    }
    return warnings;
  }

  bool _isProgressionUnlockSource(String? sourceType) {
    return sourceType == CosmeticUnlockSource.progressionLevel.name ||
        sourceType == CosmeticUnlockSource.achievement.name ||
        sourceType == CosmeticUnlockSource.quest.name;
  }
}

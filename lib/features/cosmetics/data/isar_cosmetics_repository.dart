import 'package:isar/isar.dart';

import '../config/cosmetics_config.dart';
import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_unlock_rules.dart';
import 'cosmetics_repository.dart';
import 'local/cosmetics_database.dart';
import 'local/cosmetics_local_models.dart';

/// Isar-backed [CosmeticsRepository]. Mirrors the validation rules of the
/// in-memory implementation; persistence is the only behavioural difference.
///
/// Schema (see `cosmetics_local_models.dart`):
///   * `CosmeticsUserStateRecord` — one row per uid with the equipped slot
///     ids and `updatedAt`.
///   * `CosmeticsUnlockRecord` — one row per (uid, cosmeticId) pair with
///     audit fields (timestamp, sourceType, sourceId).
class IsarCosmeticsRepository implements CosmeticsRepository {
  IsarCosmeticsRepository({
    required CosmeticsDatabase database,
    CosmeticCatalog catalog = const CosmeticCatalog(),
    CosmeticsConfig? config,
    CosmeticUnlockRules unlockRules = const CosmeticUnlockRules(),
    DateTime Function()? clock,
  })  : _database = database,
        _catalog = catalog,
        _config = config ?? CosmeticsConfig.standard(),
        _unlockRules = unlockRules,
        _clock = clock ?? DateTime.now;

  final CosmeticsDatabase _database;
  final CosmeticCatalog _catalog;
  final CosmeticsConfig _config;
  final CosmeticUnlockRules _unlockRules;
  final DateTime Function() _clock;

  Isar get _isar => _database.isar;

  @override
  Future<UserCosmeticsState> loadForUser(String uid) async {
    final stateRecord = await _isar.cosmeticsUserStateRecords
        .filter()
        .uidEqualTo(uid)
        .findFirst();
    final unlockRecords = await _isar.cosmeticsUnlockRecords
        .filter()
        .uidEqualTo(uid)
        .findAll();

    if (stateRecord == null && unlockRecords.isEmpty) {
      // First-time user — seed defaults and persist them so subsequent loads
      // are deterministic.
      final fresh = _buildDefaultState(uid);
      await _persistFullState(fresh);
      return fresh;
    }

    final unlocked = <String, UnlockedCosmetic>{
      for (final r in unlockRecords)
        r.cosmeticId: UnlockedCosmetic(
          cosmeticId: r.cosmeticId,
          unlockedAt: r.unlockedAt,
          sourceType: r.sourceType,
          sourceId: r.sourceId,
        ),
    };

    return UserCosmeticsState(
      uid: uid,
      unlocked: unlocked,
      equipped: _equippedFromRecord(stateRecord),
      updatedAt: stateRecord?.updatedAt ?? _clock(),
    );
  }

  @override
  Future<void> saveState(UserCosmeticsState state) async {
    await _persistFullState(state);
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
    final now = _clock();
    await _isar.writeTxn(() async {
      // loadForUser seeds defaults on first access; calling it inside a write
      // transaction would deadlock, so seed eagerly here if the user is new.
      await _ensureSeededWithinTxn(uid, now);
      final existing = await _isar.cosmeticsUnlockRecords
          .filter()
          .uidEqualTo(uid)
          .cosmeticIdEqualTo(cosmeticId)
          .findFirst();
      if (existing != null) return;
      final record = CosmeticsUnlockRecord()
        ..uid = uid
        ..cosmeticId = cosmeticId
        ..unlockedAt = now
        ..sourceType = sourceType
        ..sourceId = sourceId;
      await _isar.cosmeticsUnlockRecords.put(record);
      await _bumpUpdatedAt(uid, now);
    });
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
    final now = _clock();
    await _isar.writeTxn(() async {
      await _ensureSeededWithinTxn(uid, now);
      final hasUnlock = await _isar.cosmeticsUnlockRecords
              .filter()
              .uidEqualTo(uid)
              .cosmeticIdEqualTo(cosmeticId)
              .count() >
          0;
      if (!hasUnlock) {
        throw CosmeticsException(
          'cosmetic_locked',
          'Cosmetic "$cosmeticId" is not unlocked for user "$uid"',
        );
      }
      await _writeSlot(uid, type, cosmeticId, now);
    });
  }

  @override
  Future<void> unequipCosmetic({
    required String uid,
    required CosmeticType type,
  }) async {
    final now = _clock();
    await _isar.writeTxn(() async {
      await _ensureSeededWithinTxn(uid, now);
      await _writeSlot(uid, type, null, now);
    });
  }

  @override
  Future<void> revokeCosmetic({
    required String uid,
    required String cosmeticId,
  }) async {
    final now = _clock();
    await _isar.writeTxn(() async {
      // Skip seeding entirely — revoke on a fresh user is a no-op and we
      // don't want to silently materialise default unlocks.
      final unlock = await _isar.cosmeticsUnlockRecords
          .filter()
          .uidEqualTo(uid)
          .cosmeticIdEqualTo(cosmeticId)
          .findFirst();
      if (unlock == null) return;
      await _isar.cosmeticsUnlockRecords.delete(unlock.id);

      // If the cosmetic is equipped in any slot, clear that slot.
      final stateRecord = await _isar.cosmeticsUserStateRecords
          .filter()
          .uidEqualTo(uid)
          .findFirst();
      if (stateRecord != null) {
        var dirty = false;
        if (stateRecord.frameId == cosmeticId) {
          stateRecord.frameId = null;
          dirty = true;
        }
        if (stateRecord.relicId == cosmeticId) {
          stateRecord.relicId = null;
          dirty = true;
        }
        if (stateRecord.backgroundId == cosmeticId) {
          stateRecord.backgroundId = null;
          dirty = true;
        }
        if (stateRecord.emblemId == cosmeticId) {
          stateRecord.emblemId = null;
          dirty = true;
        }
        if (stateRecord.companionId == cosmeticId) {
          stateRecord.companionId = null;
          dirty = true;
        }
        if (stateRecord.titleFlairId == cosmeticId) {
          stateRecord.titleFlairId = null;
          dirty = true;
        }
        if (stateRecord.mapEffectId == cosmeticId) {
          stateRecord.mapEffectId = null;
          dirty = true;
        }
        if (dirty) {
          stateRecord.updatedAt = now;
          await _isar.cosmeticsUserStateRecords.put(stateRecord);
        } else {
          await _bumpUpdatedAt(uid, now);
        }
      }
    });
  }

  @override
  Future<int> clearAllUnlocks(String uid) async {
    final now = _clock();
    var removed = 0;
    await _isar.writeTxn(() async {
      final unlocks = await _isar.cosmeticsUnlockRecords
          .filter()
          .uidEqualTo(uid)
          .findAll();
      removed = unlocks.length;
      if (unlocks.isNotEmpty) {
        await _isar.cosmeticsUnlockRecords
            .deleteAll(unlocks.map((r) => r.id).toList());
      }

      // Clear every equipped slot but keep the state row so loadForUser
      // does not re-seed defaults on the next read.
      final existing = await _isar.cosmeticsUserStateRecords
          .filter()
          .uidEqualTo(uid)
          .findFirst();
      final record = existing ?? CosmeticsUserStateRecord()
        ..uid = uid;
      record
        ..frameId = null
        ..relicId = null
        ..backgroundId = null
        ..emblemId = null
        ..companionId = null
        ..titleFlairId = null
        ..mapEffectId = null
        ..updatedAt = now;
      await _isar.cosmeticsUserStateRecords.put(record);
    });
    return removed;
  }

  // ---------- helpers ----------

  bool _isSlotAllowed(CosmeticType type) {
    if (_config.allowedSlots.contains(type)) return true;
    if (type == CosmeticType.mapEffect && _config.experimentalTypesEnabled) {
      return true;
    }
    return false;
  }

  Loadout _equippedFromRecord(CosmeticsUserStateRecord? r) {
    if (r == null) return _config.defaultEquipped;
    return Loadout(
      frameId: r.frameId,
      relicId: r.relicId,
      backgroundId: r.backgroundId,
      emblemId: r.emblemId,
      companionId: r.companionId,
      titleFlairId: r.titleFlairId,
      mapEffectId: r.mapEffectId,
    );
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

  /// Writes the entire state for [uid] in a single transaction. Used by
  /// initial seeding and `saveState`.
  Future<void> _persistFullState(UserCosmeticsState state) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cosmeticsUserStateRecords
          .filter()
          .uidEqualTo(state.uid)
          .findFirst();
      final record = existing ?? CosmeticsUserStateRecord()
        ..uid = state.uid;
      record
        ..frameId = state.equipped.frameId
        ..relicId = state.equipped.relicId
        ..backgroundId = state.equipped.backgroundId
        ..emblemId = state.equipped.emblemId
        ..companionId = state.equipped.companionId
        ..titleFlairId = state.equipped.titleFlairId
        ..mapEffectId = state.equipped.mapEffectId
        ..updatedAt = state.updatedAt;
      await _isar.cosmeticsUserStateRecords.put(record);

      final existingUnlocks = await _isar.cosmeticsUnlockRecords
          .filter()
          .uidEqualTo(state.uid)
          .findAll();
      final keep = state.unlocked.keys.toSet();
      final toDelete = <int>[
        for (final r in existingUnlocks)
          if (!keep.contains(r.cosmeticId)) r.id,
      ];
      if (toDelete.isNotEmpty) {
        await _isar.cosmeticsUnlockRecords.deleteAll(toDelete);
      }

      for (final unlock in state.unlocked.values) {
        final existingRow = await _isar.cosmeticsUnlockRecords
            .filter()
            .uidEqualTo(state.uid)
            .cosmeticIdEqualTo(unlock.cosmeticId)
            .findFirst();
        final row = existingRow ?? CosmeticsUnlockRecord()
          ..uid = state.uid
          ..cosmeticId = unlock.cosmeticId;
        row
          ..unlockedAt = unlock.unlockedAt
          ..sourceType = unlock.sourceType
          ..sourceId = unlock.sourceId;
        await _isar.cosmeticsUnlockRecords.put(row);
      }
    });
  }

  /// First-time-user seeding inside an already-open writeTxn. Idempotent: if
  /// a state row already exists for [uid] the call is a no-op.
  Future<void> _ensureSeededWithinTxn(String uid, DateTime now) async {
    final existing = await _isar.cosmeticsUserStateRecords
        .filter()
        .uidEqualTo(uid)
        .findFirst();
    final hasAnyUnlock = await _isar.cosmeticsUnlockRecords
            .filter()
            .uidEqualTo(uid)
            .count() >
        0;
    if (existing != null || hasAnyUnlock) return;

    final stateRecord = CosmeticsUserStateRecord()
      ..uid = uid
      ..frameId = _config.defaultEquipped.frameId
      ..relicId = _config.defaultEquipped.relicId
      ..backgroundId = _config.defaultEquipped.backgroundId
      ..emblemId = _config.defaultEquipped.emblemId
      ..companionId = _config.defaultEquipped.companionId
      ..titleFlairId = _config.defaultEquipped.titleFlairId
      ..mapEffectId = _config.defaultEquipped.mapEffectId
      ..updatedAt = now;
    await _isar.cosmeticsUserStateRecords.put(stateRecord);

    for (final def in _catalog.all) {
      if (!def.isEnabled) continue;
      if (!_unlockRules.isDefaultUnlocked(def.id)) continue;
      final row = CosmeticsUnlockRecord()
        ..uid = uid
        ..cosmeticId = def.id
        ..unlockedAt = now
        ..sourceType = CosmeticUnlockSource.defaultBaseline.name;
      await _isar.cosmeticsUnlockRecords.put(row);
    }
  }

  Future<void> _writeSlot(
    String uid,
    CosmeticType type,
    String? cosmeticId,
    DateTime now,
  ) async {
    final existing = await _isar.cosmeticsUserStateRecords
        .filter()
        .uidEqualTo(uid)
        .findFirst();
    final record = existing ?? CosmeticsUserStateRecord()
      ..uid = uid;
    switch (type) {
      case CosmeticType.frame:
        record.frameId = cosmeticId;
      case CosmeticType.relic:
        record.relicId = cosmeticId;
      case CosmeticType.background:
        record.backgroundId = cosmeticId;
      case CosmeticType.emblem:
        record.emblemId = cosmeticId;
      case CosmeticType.companion:
        record.companionId = cosmeticId;
      case CosmeticType.titleFlair:
        record.titleFlairId = cosmeticId;
      case CosmeticType.mapEffect:
        record.mapEffectId = cosmeticId;
    }
    record.updatedAt = now;
    await _isar.cosmeticsUserStateRecords.put(record);
  }

  Future<void> _bumpUpdatedAt(String uid, DateTime now) async {
    final existing = await _isar.cosmeticsUserStateRecords
        .filter()
        .uidEqualTo(uid)
        .findFirst();
    if (existing == null) return;
    existing.updatedAt = now;
    await _isar.cosmeticsUserStateRecords.put(existing);
  }
}

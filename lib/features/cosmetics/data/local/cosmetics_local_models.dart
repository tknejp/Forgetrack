import 'package:isar/isar.dart';

part 'cosmetics_local_models.g.dart';

/// Persisted equipped-slot snapshot — one row per uid. The unlocked set
/// lives in [CosmeticsUnlockRecord] so we don't have to rewrite the whole
/// list on every unlock.
@Collection()
class CosmeticsUserStateRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  String? frameId;
  String? relicId;
  String? backgroundId;
  String? emblemId;
  String? companionId;
  String? titleFlairId;
  String? mapEffectId;

  @Index()
  late DateTime updatedAt;
}

/// One row per (uid, cosmeticId) pair. Composite-unique so re-unlocking a
/// cosmetic with `replace: true` overwrites the existing record instead of
/// inserting a duplicate.
@Collection()
class CosmeticsUnlockRecord {
  Id id = Isar.autoIncrement;

  @Index(
    composite: [CompositeIndex('cosmeticId')],
    unique: true,
    replace: true,
  )
  late String uid;

  late String cosmeticId;

  @Index()
  late DateTime unlockedAt;

  String? sourceType;
  String? sourceId;
}

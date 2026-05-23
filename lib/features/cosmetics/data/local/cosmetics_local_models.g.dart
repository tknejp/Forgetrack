// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cosmetics_local_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCosmeticsUserStateRecordCollection on Isar {
  IsarCollection<CosmeticsUserStateRecord> get cosmeticsUserStateRecords =>
      this.collection();
}

const CosmeticsUserStateRecordSchema = CollectionSchema(
  name: r'CosmeticsUserStateRecord',
  id: 379226333959878565,
  properties: {
    r'backgroundId': PropertySchema(
      id: 0,
      name: r'backgroundId',
      type: IsarType.string,
    ),
    r'companionId': PropertySchema(
      id: 1,
      name: r'companionId',
      type: IsarType.string,
    ),
    r'emblemId': PropertySchema(
      id: 2,
      name: r'emblemId',
      type: IsarType.string,
    ),
    r'frameId': PropertySchema(
      id: 3,
      name: r'frameId',
      type: IsarType.string,
    ),
    r'mapEffectId': PropertySchema(
      id: 4,
      name: r'mapEffectId',
      type: IsarType.string,
    ),
    r'relicId': PropertySchema(
      id: 5,
      name: r'relicId',
      type: IsarType.string,
    ),
    r'selectedRaceId': PropertySchema(
      id: 6,
      name: r'selectedRaceId',
      type: IsarType.string,
    ),
    r'skinId': PropertySchema(
      id: 7,
      name: r'skinId',
      type: IsarType.string,
    ),
    r'titleFlairId': PropertySchema(
      id: 8,
      name: r'titleFlairId',
      type: IsarType.string,
    ),
    r'uid': PropertySchema(
      id: 9,
      name: r'uid',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cosmeticsUserStateRecordEstimateSize,
  serialize: _cosmeticsUserStateRecordSerialize,
  deserialize: _cosmeticsUserStateRecordDeserialize,
  deserializeProp: _cosmeticsUserStateRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid': IndexSchema(
      id: 8193695471701937315,
      name: r'uid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cosmeticsUserStateRecordGetId,
  getLinks: _cosmeticsUserStateRecordGetLinks,
  attach: _cosmeticsUserStateRecordAttach,
  version: '3.1.0+1',
);

int _cosmeticsUserStateRecordEstimateSize(
  CosmeticsUserStateRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.backgroundId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.companionId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.emblemId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.frameId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mapEffectId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.relicId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.selectedRaceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.skinId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.titleFlairId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _cosmeticsUserStateRecordSerialize(
  CosmeticsUserStateRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.backgroundId);
  writer.writeString(offsets[1], object.companionId);
  writer.writeString(offsets[2], object.emblemId);
  writer.writeString(offsets[3], object.frameId);
  writer.writeString(offsets[4], object.mapEffectId);
  writer.writeString(offsets[5], object.relicId);
  writer.writeString(offsets[6], object.selectedRaceId);
  writer.writeString(offsets[7], object.skinId);
  writer.writeString(offsets[8], object.titleFlairId);
  writer.writeString(offsets[9], object.uid);
  writer.writeDateTime(offsets[10], object.updatedAt);
}

CosmeticsUserStateRecord _cosmeticsUserStateRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CosmeticsUserStateRecord();
  object.backgroundId = reader.readStringOrNull(offsets[0]);
  object.companionId = reader.readStringOrNull(offsets[1]);
  object.emblemId = reader.readStringOrNull(offsets[2]);
  object.frameId = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.mapEffectId = reader.readStringOrNull(offsets[4]);
  object.relicId = reader.readStringOrNull(offsets[5]);
  object.selectedRaceId = reader.readStringOrNull(offsets[6]);
  object.skinId = reader.readStringOrNull(offsets[7]);
  object.titleFlairId = reader.readStringOrNull(offsets[8]);
  object.uid = reader.readString(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  return object;
}

P _cosmeticsUserStateRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cosmeticsUserStateRecordGetId(CosmeticsUserStateRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cosmeticsUserStateRecordGetLinks(
    CosmeticsUserStateRecord object) {
  return [];
}

void _cosmeticsUserStateRecordAttach(
    IsarCollection<dynamic> col, Id id, CosmeticsUserStateRecord object) {
  object.id = id;
}

extension CosmeticsUserStateRecordByIndex
    on IsarCollection<CosmeticsUserStateRecord> {
  Future<CosmeticsUserStateRecord?> getByUid(String uid) {
    return getByIndex(r'uid', [uid]);
  }

  CosmeticsUserStateRecord? getByUidSync(String uid) {
    return getByIndexSync(r'uid', [uid]);
  }

  Future<bool> deleteByUid(String uid) {
    return deleteByIndex(r'uid', [uid]);
  }

  bool deleteByUidSync(String uid) {
    return deleteByIndexSync(r'uid', [uid]);
  }

  Future<List<CosmeticsUserStateRecord?>> getAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uid', values);
  }

  List<CosmeticsUserStateRecord?> getAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uid', values);
  }

  Future<int> deleteAllByUid(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uid', values);
  }

  int deleteAllByUidSync(List<String> uidValues) {
    final values = uidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uid', values);
  }

  Future<Id> putByUid(CosmeticsUserStateRecord object) {
    return putByIndex(r'uid', object);
  }

  Id putByUidSync(CosmeticsUserStateRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUid(List<CosmeticsUserStateRecord> objects) {
    return putAllByIndex(r'uid', objects);
  }

  List<Id> putAllByUidSync(List<CosmeticsUserStateRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid', objects, saveLinks: saveLinks);
  }
}

extension CosmeticsUserStateRecordQueryWhereSort on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QWhere> {
  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterWhere>
      anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension CosmeticsUserStateRecordQueryWhere on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QWhereClause> {
  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> uidEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid',
        value: [uid],
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> uidNotEqualTo(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> updatedAtEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> updatedAtNotEqualTo(DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> updatedAtGreaterThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterWhereClause> updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CosmeticsUserStateRecordQueryFilter on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QFilterCondition> {
  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'backgroundId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'backgroundId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backgroundId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'backgroundId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'backgroundId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'backgroundId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'backgroundId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'backgroundId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      backgroundIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'backgroundId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      backgroundIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'backgroundId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backgroundId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> backgroundIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'backgroundId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'companionId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'companionId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'companionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'companionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'companionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'companionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'companionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'companionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      companionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'companionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      companionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'companionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'companionId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> companionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'companionId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emblemId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emblemId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emblemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emblemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emblemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emblemId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'emblemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'emblemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      emblemIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'emblemId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      emblemIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'emblemId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emblemId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> emblemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emblemId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'frameId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'frameId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frameId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'frameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'frameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      frameIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'frameId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      frameIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'frameId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frameId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> frameIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'frameId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mapEffectId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mapEffectId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mapEffectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mapEffectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mapEffectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mapEffectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mapEffectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mapEffectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      mapEffectIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mapEffectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      mapEffectIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mapEffectId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mapEffectId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> mapEffectIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mapEffectId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'relicId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'relicId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'relicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'relicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'relicId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'relicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'relicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      relicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'relicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      relicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'relicId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relicId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> relicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relicId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'selectedRaceId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'selectedRaceId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedRaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedRaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedRaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedRaceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedRaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedRaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      selectedRaceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedRaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      selectedRaceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedRaceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedRaceId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> selectedRaceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedRaceId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'skinId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'skinId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skinId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'skinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'skinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      skinIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'skinId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      skinIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'skinId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skinId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> skinIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'skinId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'titleFlairId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'titleFlairId',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titleFlairId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'titleFlairId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'titleFlairId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'titleFlairId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'titleFlairId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'titleFlairId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      titleFlairIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'titleFlairId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      titleFlairIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'titleFlairId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titleFlairId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> titleFlairIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'titleFlairId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
          QAfterFilterCondition>
      uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CosmeticsUserStateRecordQueryObject on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QFilterCondition> {}

extension CosmeticsUserStateRecordQueryLinks on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QFilterCondition> {}

extension CosmeticsUserStateRecordQuerySortBy on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QSortBy> {
  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByBackgroundId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByBackgroundIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByCompanionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByCompanionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByEmblemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByEmblemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByFrameId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frameId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByFrameIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frameId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByMapEffectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapEffectId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByMapEffectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapEffectId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByRelicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByRelicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortBySelectedRaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRaceId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortBySelectedRaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRaceId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortBySkinId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skinId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortBySkinIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skinId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByTitleFlairId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleFlairId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByTitleFlairIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleFlairId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CosmeticsUserStateRecordQuerySortThenBy on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QSortThenBy> {
  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByBackgroundId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByBackgroundIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backgroundId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByCompanionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByCompanionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByEmblemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByEmblemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByFrameId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frameId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByFrameIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frameId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByMapEffectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapEffectId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByMapEffectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapEffectId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByRelicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByRelicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenBySelectedRaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRaceId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenBySelectedRaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedRaceId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenBySkinId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skinId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenBySkinIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skinId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByTitleFlairId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleFlairId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByTitleFlairIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleFlairId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CosmeticsUserStateRecordQueryWhereDistinct on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct> {
  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByBackgroundId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backgroundId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByCompanionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByEmblemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emblemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByFrameId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frameId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByMapEffectId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mapEffectId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByRelicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctBySelectedRaceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedRaceId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctBySkinId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skinId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByTitleFlairId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'titleFlairId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, CosmeticsUserStateRecord, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CosmeticsUserStateRecordQueryProperty on QueryBuilder<
    CosmeticsUserStateRecord, CosmeticsUserStateRecord, QQueryProperty> {
  QueryBuilder<CosmeticsUserStateRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      backgroundIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backgroundId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      companionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companionId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      emblemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emblemId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      frameIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frameId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      mapEffectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mapEffectId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      relicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relicId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      selectedRaceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedRaceId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      skinIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skinId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String?, QQueryOperations>
      titleFlairIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'titleFlairId');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, String, QQueryOperations>
      uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<CosmeticsUserStateRecord, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCosmeticsUnlockRecordCollection on Isar {
  IsarCollection<CosmeticsUnlockRecord> get cosmeticsUnlockRecords =>
      this.collection();
}

const CosmeticsUnlockRecordSchema = CollectionSchema(
  name: r'CosmeticsUnlockRecord',
  id: -9078961256712466534,
  properties: {
    r'cosmeticId': PropertySchema(
      id: 0,
      name: r'cosmeticId',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 1,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'sourceType': PropertySchema(
      id: 2,
      name: r'sourceType',
      type: IsarType.string,
    ),
    r'uid': PropertySchema(
      id: 3,
      name: r'uid',
      type: IsarType.string,
    ),
    r'unlockedAt': PropertySchema(
      id: 4,
      name: r'unlockedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cosmeticsUnlockRecordEstimateSize,
  serialize: _cosmeticsUnlockRecordSerialize,
  deserialize: _cosmeticsUnlockRecordDeserialize,
  deserializeProp: _cosmeticsUnlockRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid_cosmeticId': IndexSchema(
      id: 6510909426817051885,
      name: r'uid_cosmeticId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'cosmeticId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'unlockedAt': IndexSchema(
      id: -2486051207984852976,
      name: r'unlockedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'unlockedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cosmeticsUnlockRecordGetId,
  getLinks: _cosmeticsUnlockRecordGetLinks,
  attach: _cosmeticsUnlockRecordAttach,
  version: '3.1.0+1',
);

int _cosmeticsUnlockRecordEstimateSize(
  CosmeticsUnlockRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cosmeticId.length * 3;
  {
    final value = object.sourceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _cosmeticsUnlockRecordSerialize(
  CosmeticsUnlockRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cosmeticId);
  writer.writeString(offsets[1], object.sourceId);
  writer.writeString(offsets[2], object.sourceType);
  writer.writeString(offsets[3], object.uid);
  writer.writeDateTime(offsets[4], object.unlockedAt);
}

CosmeticsUnlockRecord _cosmeticsUnlockRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CosmeticsUnlockRecord();
  object.cosmeticId = reader.readString(offsets[0]);
  object.id = id;
  object.sourceId = reader.readStringOrNull(offsets[1]);
  object.sourceType = reader.readStringOrNull(offsets[2]);
  object.uid = reader.readString(offsets[3]);
  object.unlockedAt = reader.readDateTime(offsets[4]);
  return object;
}

P _cosmeticsUnlockRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cosmeticsUnlockRecordGetId(CosmeticsUnlockRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cosmeticsUnlockRecordGetLinks(
    CosmeticsUnlockRecord object) {
  return [];
}

void _cosmeticsUnlockRecordAttach(
    IsarCollection<dynamic> col, Id id, CosmeticsUnlockRecord object) {
  object.id = id;
}

extension CosmeticsUnlockRecordByIndex
    on IsarCollection<CosmeticsUnlockRecord> {
  Future<CosmeticsUnlockRecord?> getByUidCosmeticId(
      String uid, String cosmeticId) {
    return getByIndex(r'uid_cosmeticId', [uid, cosmeticId]);
  }

  CosmeticsUnlockRecord? getByUidCosmeticIdSync(String uid, String cosmeticId) {
    return getByIndexSync(r'uid_cosmeticId', [uid, cosmeticId]);
  }

  Future<bool> deleteByUidCosmeticId(String uid, String cosmeticId) {
    return deleteByIndex(r'uid_cosmeticId', [uid, cosmeticId]);
  }

  bool deleteByUidCosmeticIdSync(String uid, String cosmeticId) {
    return deleteByIndexSync(r'uid_cosmeticId', [uid, cosmeticId]);
  }

  Future<List<CosmeticsUnlockRecord?>> getAllByUidCosmeticId(
      List<String> uidValues, List<String> cosmeticIdValues) {
    final len = uidValues.length;
    assert(cosmeticIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], cosmeticIdValues[i]]);
    }

    return getAllByIndex(r'uid_cosmeticId', values);
  }

  List<CosmeticsUnlockRecord?> getAllByUidCosmeticIdSync(
      List<String> uidValues, List<String> cosmeticIdValues) {
    final len = uidValues.length;
    assert(cosmeticIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], cosmeticIdValues[i]]);
    }

    return getAllByIndexSync(r'uid_cosmeticId', values);
  }

  Future<int> deleteAllByUidCosmeticId(
      List<String> uidValues, List<String> cosmeticIdValues) {
    final len = uidValues.length;
    assert(cosmeticIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], cosmeticIdValues[i]]);
    }

    return deleteAllByIndex(r'uid_cosmeticId', values);
  }

  int deleteAllByUidCosmeticIdSync(
      List<String> uidValues, List<String> cosmeticIdValues) {
    final len = uidValues.length;
    assert(cosmeticIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], cosmeticIdValues[i]]);
    }

    return deleteAllByIndexSync(r'uid_cosmeticId', values);
  }

  Future<Id> putByUidCosmeticId(CosmeticsUnlockRecord object) {
    return putByIndex(r'uid_cosmeticId', object);
  }

  Id putByUidCosmeticIdSync(CosmeticsUnlockRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'uid_cosmeticId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUidCosmeticId(List<CosmeticsUnlockRecord> objects) {
    return putAllByIndex(r'uid_cosmeticId', objects);
  }

  List<Id> putAllByUidCosmeticIdSync(List<CosmeticsUnlockRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid_cosmeticId', objects, saveLinks: saveLinks);
  }
}

extension CosmeticsUnlockRecordQueryWhereSort
    on QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QWhere> {
  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhere>
      anyUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'unlockedAt'),
      );
    });
  }
}

extension CosmeticsUnlockRecordQueryWhere on QueryBuilder<CosmeticsUnlockRecord,
    CosmeticsUnlockRecord, QWhereClause> {
  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      uidEqualToAnyCosmeticId(String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid_cosmeticId',
        value: [uid],
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      uidNotEqualToAnyCosmeticId(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      uidCosmeticIdEqualTo(String uid, String cosmeticId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid_cosmeticId',
        value: [uid, cosmeticId],
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      uidEqualToCosmeticIdNotEqualTo(String uid, String cosmeticId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [uid],
              upper: [uid, cosmeticId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [uid, cosmeticId],
              includeLower: false,
              upper: [uid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [uid, cosmeticId],
              includeLower: false,
              upper: [uid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_cosmeticId',
              lower: [uid],
              upper: [uid, cosmeticId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      unlockedAtEqualTo(DateTime unlockedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'unlockedAt',
        value: [unlockedAt],
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      unlockedAtNotEqualTo(DateTime unlockedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockedAt',
              lower: [],
              upper: [unlockedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockedAt',
              lower: [unlockedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockedAt',
              lower: [unlockedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockedAt',
              lower: [],
              upper: [unlockedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      unlockedAtGreaterThan(
    DateTime unlockedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unlockedAt',
        lower: [unlockedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      unlockedAtLessThan(
    DateTime unlockedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unlockedAt',
        lower: [],
        upper: [unlockedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterWhereClause>
      unlockedAtBetween(
    DateTime lowerUnlockedAt,
    DateTime upperUnlockedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'unlockedAt',
        lower: [lowerUnlockedAt],
        includeLower: includeLower,
        upper: [upperUnlockedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CosmeticsUnlockRecordQueryFilter on QueryBuilder<
    CosmeticsUnlockRecord, CosmeticsUnlockRecord, QFilterCondition> {
  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cosmeticId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cosmeticId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cosmeticId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cosmeticId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cosmeticId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cosmeticId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      cosmeticIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cosmeticId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      cosmeticIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cosmeticId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cosmeticId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> cosmeticIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cosmeticId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceId',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceId',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      sourceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      sourceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceId',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceType',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceType',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      sourceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      sourceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceType',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> sourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceType',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      uidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
          QAfterFilterCondition>
      uidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> unlockedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> unlockedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> unlockedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord,
      QAfterFilterCondition> unlockedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unlockedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CosmeticsUnlockRecordQueryObject on QueryBuilder<
    CosmeticsUnlockRecord, CosmeticsUnlockRecord, QFilterCondition> {}

extension CosmeticsUnlockRecordQueryLinks on QueryBuilder<CosmeticsUnlockRecord,
    CosmeticsUnlockRecord, QFilterCondition> {}

extension CosmeticsUnlockRecordQuerySortBy
    on QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QSortBy> {
  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortByCosmeticId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortByCosmeticIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      sortByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }
}

extension CosmeticsUnlockRecordQuerySortThenBy
    on QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QSortThenBy> {
  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenByCosmeticId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenByCosmeticIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QAfterSortBy>
      thenByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }
}

extension CosmeticsUnlockRecordQueryWhereDistinct
    on QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QDistinct> {
  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QDistinct>
      distinctByCosmeticId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cosmeticId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QDistinct>
      distinctBySourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QDistinct>
      distinctBySourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QDistinct>
      distinctByUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, CosmeticsUnlockRecord, QDistinct>
      distinctByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockedAt');
    });
  }
}

extension CosmeticsUnlockRecordQueryProperty on QueryBuilder<
    CosmeticsUnlockRecord, CosmeticsUnlockRecord, QQueryProperty> {
  QueryBuilder<CosmeticsUnlockRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, String, QQueryOperations>
      cosmeticIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cosmeticId');
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, String?, QQueryOperations>
      sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, String?, QQueryOperations>
      sourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceType');
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }

  QueryBuilder<CosmeticsUnlockRecord, DateTime, QQueryOperations>
      unlockedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockedAt');
    });
  }
}

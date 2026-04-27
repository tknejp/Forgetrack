// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_local_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressionEvaluationRecordCollection on Isar {
  IsarCollection<ProgressionEvaluationRecord>
      get progressionEvaluationRecords => this.collection();
}

const ProgressionEvaluationRecordSchema = CollectionSchema(
  name: r'ProgressionEvaluationRecord',
  id: -6215028836072412857,
  properties: {
    r'achieved': PropertySchema(
      id: 0,
      name: r'achieved',
      type: IsarType.bool,
    ),
    r'actualValue': PropertySchema(
      id: 1,
      name: r'actualValue',
      type: IsarType.double,
    ),
    r'comparatorName': PropertySchema(
      id: 2,
      name: r'comparatorName',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 3,
      name: r'description',
      type: IsarType.string,
    ),
    r'domainName': PropertySchema(
      id: 4,
      name: r'domainName',
      type: IsarType.string,
    ),
    r'evaluatedAt': PropertySchema(
      id: 5,
      name: r'evaluatedAt',
      type: IsarType.dateTime,
    ),
    r'evaluationKey': PropertySchema(
      id: 6,
      name: r'evaluationKey',
      type: IsarType.string,
    ),
    r'explanation': PropertySchema(
      id: 7,
      name: r'explanation',
      type: IsarType.string,
    ),
    r'missReasonName': PropertySchema(
      id: 8,
      name: r'missReasonName',
      type: IsarType.string,
    ),
    r'periodEnd': PropertySchema(
      id: 9,
      name: r'periodEnd',
      type: IsarType.dateTime,
    ),
    r'periodKindName': PropertySchema(
      id: 10,
      name: r'periodKindName',
      type: IsarType.string,
    ),
    r'periodStart': PropertySchema(
      id: 11,
      name: r'periodStart',
      type: IsarType.dateTime,
    ),
    r'progress': PropertySchema(
      id: 12,
      name: r'progress',
      type: IsarType.double,
    ),
    r'rewardKey': PropertySchema(
      id: 13,
      name: r'rewardKey',
      type: IsarType.string,
    ),
    r'rewardXp': PropertySchema(
      id: 14,
      name: r'rewardXp',
      type: IsarType.long,
    ),
    r'ruleId': PropertySchema(
      id: 15,
      name: r'ruleId',
      type: IsarType.string,
    ),
    r'ruleVersion': PropertySchema(
      id: 16,
      name: r'ruleVersion',
      type: IsarType.string,
    ),
    r'statusName': PropertySchema(
      id: 17,
      name: r'statusName',
      type: IsarType.string,
    ),
    r'targetValue': PropertySchema(
      id: 18,
      name: r'targetValue',
      type: IsarType.double,
    ),
    r'title': PropertySchema(
      id: 19,
      name: r'title',
      type: IsarType.string,
    ),
    r'toleranceRatio': PropertySchema(
      id: 20,
      name: r'toleranceRatio',
      type: IsarType.double,
    ),
    r'upperTargetValue': PropertySchema(
      id: 21,
      name: r'upperTargetValue',
      type: IsarType.double,
    )
  },
  estimateSize: _progressionEvaluationRecordEstimateSize,
  serialize: _progressionEvaluationRecordSerialize,
  deserialize: _progressionEvaluationRecordDeserialize,
  deserializeProp: _progressionEvaluationRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'evaluationKey': IndexSchema(
      id: 3852476082311557929,
      name: r'evaluationKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'evaluationKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'periodStart': IndexSchema(
      id: -7133903706047263368,
      name: r'periodStart',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'periodStart',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'evaluatedAt': IndexSchema(
      id: -8596707528798101232,
      name: r'evaluatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'evaluatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _progressionEvaluationRecordGetId,
  getLinks: _progressionEvaluationRecordGetLinks,
  attach: _progressionEvaluationRecordAttach,
  version: '3.1.0+1',
);

int _progressionEvaluationRecordEstimateSize(
  ProgressionEvaluationRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.comparatorName.length * 3;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.domainName.length * 3;
  bytesCount += 3 + object.evaluationKey.length * 3;
  bytesCount += 3 + object.explanation.length * 3;
  {
    final value = object.missReasonName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.periodKindName.length * 3;
  bytesCount += 3 + object.rewardKey.length * 3;
  bytesCount += 3 + object.ruleId.length * 3;
  bytesCount += 3 + object.ruleVersion.length * 3;
  {
    final value = object.statusName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _progressionEvaluationRecordSerialize(
  ProgressionEvaluationRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.achieved);
  writer.writeDouble(offsets[1], object.actualValue);
  writer.writeString(offsets[2], object.comparatorName);
  writer.writeString(offsets[3], object.description);
  writer.writeString(offsets[4], object.domainName);
  writer.writeDateTime(offsets[5], object.evaluatedAt);
  writer.writeString(offsets[6], object.evaluationKey);
  writer.writeString(offsets[7], object.explanation);
  writer.writeString(offsets[8], object.missReasonName);
  writer.writeDateTime(offsets[9], object.periodEnd);
  writer.writeString(offsets[10], object.periodKindName);
  writer.writeDateTime(offsets[11], object.periodStart);
  writer.writeDouble(offsets[12], object.progress);
  writer.writeString(offsets[13], object.rewardKey);
  writer.writeLong(offsets[14], object.rewardXp);
  writer.writeString(offsets[15], object.ruleId);
  writer.writeString(offsets[16], object.ruleVersion);
  writer.writeString(offsets[17], object.statusName);
  writer.writeDouble(offsets[18], object.targetValue);
  writer.writeString(offsets[19], object.title);
  writer.writeDouble(offsets[20], object.toleranceRatio);
  writer.writeDouble(offsets[21], object.upperTargetValue);
}

ProgressionEvaluationRecord _progressionEvaluationRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressionEvaluationRecord();
  object.achieved = reader.readBool(offsets[0]);
  object.actualValue = reader.readDouble(offsets[1]);
  object.comparatorName = reader.readString(offsets[2]);
  object.description = reader.readString(offsets[3]);
  object.domainName = reader.readString(offsets[4]);
  object.evaluatedAt = reader.readDateTime(offsets[5]);
  object.evaluationKey = reader.readString(offsets[6]);
  object.explanation = reader.readString(offsets[7]);
  object.id = id;
  object.missReasonName = reader.readStringOrNull(offsets[8]);
  object.periodEnd = reader.readDateTime(offsets[9]);
  object.periodKindName = reader.readString(offsets[10]);
  object.periodStart = reader.readDateTime(offsets[11]);
  object.progress = reader.readDouble(offsets[12]);
  object.rewardKey = reader.readString(offsets[13]);
  object.rewardXp = reader.readLong(offsets[14]);
  object.ruleId = reader.readString(offsets[15]);
  object.ruleVersion = reader.readString(offsets[16]);
  object.statusName = reader.readStringOrNull(offsets[17]);
  object.targetValue = reader.readDouble(offsets[18]);
  object.title = reader.readString(offsets[19]);
  object.toleranceRatio = reader.readDouble(offsets[20]);
  object.upperTargetValue = reader.readDoubleOrNull(offsets[21]);
  return object;
}

P _progressionEvaluationRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _progressionEvaluationRecordGetId(ProgressionEvaluationRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _progressionEvaluationRecordGetLinks(
    ProgressionEvaluationRecord object) {
  return [];
}

void _progressionEvaluationRecordAttach(
    IsarCollection<dynamic> col, Id id, ProgressionEvaluationRecord object) {
  object.id = id;
}

extension ProgressionEvaluationRecordByIndex
    on IsarCollection<ProgressionEvaluationRecord> {
  Future<ProgressionEvaluationRecord?> getByEvaluationKey(
      String evaluationKey) {
    return getByIndex(r'evaluationKey', [evaluationKey]);
  }

  ProgressionEvaluationRecord? getByEvaluationKeySync(String evaluationKey) {
    return getByIndexSync(r'evaluationKey', [evaluationKey]);
  }

  Future<bool> deleteByEvaluationKey(String evaluationKey) {
    return deleteByIndex(r'evaluationKey', [evaluationKey]);
  }

  bool deleteByEvaluationKeySync(String evaluationKey) {
    return deleteByIndexSync(r'evaluationKey', [evaluationKey]);
  }

  Future<List<ProgressionEvaluationRecord?>> getAllByEvaluationKey(
      List<String> evaluationKeyValues) {
    final values = evaluationKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'evaluationKey', values);
  }

  List<ProgressionEvaluationRecord?> getAllByEvaluationKeySync(
      List<String> evaluationKeyValues) {
    final values = evaluationKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'evaluationKey', values);
  }

  Future<int> deleteAllByEvaluationKey(List<String> evaluationKeyValues) {
    final values = evaluationKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'evaluationKey', values);
  }

  int deleteAllByEvaluationKeySync(List<String> evaluationKeyValues) {
    final values = evaluationKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'evaluationKey', values);
  }

  Future<Id> putByEvaluationKey(ProgressionEvaluationRecord object) {
    return putByIndex(r'evaluationKey', object);
  }

  Id putByEvaluationKeySync(ProgressionEvaluationRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'evaluationKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEvaluationKey(
      List<ProgressionEvaluationRecord> objects) {
    return putAllByIndex(r'evaluationKey', objects);
  }

  List<Id> putAllByEvaluationKeySync(List<ProgressionEvaluationRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'evaluationKey', objects, saveLinks: saveLinks);
  }
}

extension ProgressionEvaluationRecordQueryWhereSort on QueryBuilder<
    ProgressionEvaluationRecord, ProgressionEvaluationRecord, QWhere> {
  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhere> anyPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'periodStart'),
      );
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhere> anyEvaluatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'evaluatedAt'),
      );
    });
  }
}

extension ProgressionEvaluationRecordQueryWhere on QueryBuilder<
    ProgressionEvaluationRecord, ProgressionEvaluationRecord, QWhereClause> {
  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
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

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
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

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> evaluationKeyEqualTo(String evaluationKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'evaluationKey',
        value: [evaluationKey],
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> evaluationKeyNotEqualTo(String evaluationKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluationKey',
              lower: [],
              upper: [evaluationKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluationKey',
              lower: [evaluationKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluationKey',
              lower: [evaluationKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluationKey',
              lower: [],
              upper: [evaluationKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> periodStartEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'periodStart',
        value: [periodStart],
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> periodStartNotEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> periodStartGreaterThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [periodStart],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> periodStartLessThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [],
        upper: [periodStart],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> periodStartBetween(
    DateTime lowerPeriodStart,
    DateTime upperPeriodStart, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [lowerPeriodStart],
        includeLower: includeLower,
        upper: [upperPeriodStart],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> evaluatedAtEqualTo(DateTime evaluatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'evaluatedAt',
        value: [evaluatedAt],
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> evaluatedAtNotEqualTo(DateTime evaluatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluatedAt',
              lower: [],
              upper: [evaluatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluatedAt',
              lower: [evaluatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluatedAt',
              lower: [evaluatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'evaluatedAt',
              lower: [],
              upper: [evaluatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> evaluatedAtGreaterThan(
    DateTime evaluatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'evaluatedAt',
        lower: [evaluatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> evaluatedAtLessThan(
    DateTime evaluatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'evaluatedAt',
        lower: [],
        upper: [evaluatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterWhereClause> evaluatedAtBetween(
    DateTime lowerEvaluatedAt,
    DateTime upperEvaluatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'evaluatedAt',
        lower: [lowerEvaluatedAt],
        includeLower: includeLower,
        upper: [upperEvaluatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressionEvaluationRecordQueryFilter on QueryBuilder<
    ProgressionEvaluationRecord,
    ProgressionEvaluationRecord,
    QFilterCondition> {
  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> achievedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'achieved',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> actualValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> actualValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> actualValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> actualValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'comparatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'comparatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'comparatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'comparatorName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'comparatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'comparatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      comparatorNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'comparatorName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      comparatorNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'comparatorName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'comparatorName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> comparatorNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'comparatorName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'domainName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      domainNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      domainNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'domainName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> domainNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'domainName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'evaluatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'evaluatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'evaluatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'evaluatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'evaluationKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'evaluationKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'evaluationKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'evaluationKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'evaluationKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'evaluationKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      evaluationKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'evaluationKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      evaluationKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'evaluationKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'evaluationKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> evaluationKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'evaluationKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'explanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'explanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'explanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'explanation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'explanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'explanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      explanationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'explanation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      explanationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'explanation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'explanation',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> explanationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'explanation',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
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

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
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

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
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

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'missReasonName',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'missReasonName',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'missReasonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'missReasonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'missReasonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'missReasonName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'missReasonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'missReasonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      missReasonNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'missReasonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      missReasonNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'missReasonName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'missReasonName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> missReasonNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'missReasonName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodEndEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodEndGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodEndLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodEndBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodKindName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      periodKindNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      periodKindNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodKindName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKindName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodKindNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodKindName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodStartGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodStartLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> periodStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> progressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> progressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> progressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> progressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      rewardKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      rewardKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rewardKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rewardKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardXpEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardXp',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardXpGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardXp',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardXpLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardXp',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> rewardXpBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardXp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ruleId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      ruleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      ruleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ruleId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ruleId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ruleVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      ruleVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      ruleVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ruleVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> ruleVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ruleVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'statusName',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'statusName',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statusName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'statusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'statusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      statusNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'statusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      statusNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'statusName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statusName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> statusNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'statusName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> targetValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> targetValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> targetValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> targetValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
          QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> toleranceRatioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toleranceRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> toleranceRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toleranceRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> toleranceRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toleranceRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> toleranceRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toleranceRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> upperTargetValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'upperTargetValue',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> upperTargetValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'upperTargetValue',
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> upperTargetValueEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'upperTargetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> upperTargetValueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'upperTargetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> upperTargetValueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'upperTargetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterFilterCondition> upperTargetValueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'upperTargetValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ProgressionEvaluationRecordQueryObject on QueryBuilder<
    ProgressionEvaluationRecord,
    ProgressionEvaluationRecord,
    QFilterCondition> {}

extension ProgressionEvaluationRecordQueryLinks on QueryBuilder<
    ProgressionEvaluationRecord,
    ProgressionEvaluationRecord,
    QFilterCondition> {}

extension ProgressionEvaluationRecordQuerySortBy on QueryBuilder<
    ProgressionEvaluationRecord, ProgressionEvaluationRecord, QSortBy> {
  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByAchieved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achieved', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByAchievedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achieved', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByActualValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByComparatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comparatorName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByComparatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comparatorName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByDomainName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByDomainNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByEvaluatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluatedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByEvaluatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluatedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByEvaluationKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluationKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByEvaluationKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluationKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByExplanation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanation', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByExplanationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanation', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByMissReasonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missReasonName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByMissReasonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missReasonName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByPeriodKindName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByPeriodKindNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRewardKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRewardKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRewardXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardXp', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRewardXpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardXp', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRuleVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByRuleVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByToleranceRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByToleranceRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByUpperTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> sortByUpperTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.desc);
    });
  }
}

extension ProgressionEvaluationRecordQuerySortThenBy on QueryBuilder<
    ProgressionEvaluationRecord, ProgressionEvaluationRecord, QSortThenBy> {
  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByAchieved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achieved', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByAchievedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achieved', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByActualValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByComparatorName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comparatorName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByComparatorNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'comparatorName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByDomainName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByDomainNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByEvaluatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluatedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByEvaluatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluatedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByEvaluationKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluationKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByEvaluationKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evaluationKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByExplanation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanation', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByExplanationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'explanation', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByMissReasonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missReasonName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByMissReasonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missReasonName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByPeriodKindName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByPeriodKindNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRewardKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRewardKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRewardXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardXp', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRewardXpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardXp', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRuleVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByRuleVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statusName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByToleranceRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByToleranceRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.desc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByUpperTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QAfterSortBy> thenByUpperTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.desc);
    });
  }
}

extension ProgressionEvaluationRecordQueryWhereDistinct on QueryBuilder<
    ProgressionEvaluationRecord, ProgressionEvaluationRecord, QDistinct> {
  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByAchieved() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'achieved');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualValue');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByComparatorName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'comparatorName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByDomainName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'domainName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByEvaluatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'evaluatedAt');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByEvaluationKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'evaluationKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByExplanation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'explanation', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByMissReasonName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'missReasonName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodEnd');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByPeriodKindName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKindName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodStart');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByRewardKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByRewardXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardXp');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByRuleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ruleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByRuleVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ruleVersion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByStatusName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statusName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetValue');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByToleranceRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toleranceRatio');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, ProgressionEvaluationRecord,
      QDistinct> distinctByUpperTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'upperTargetValue');
    });
  }
}

extension ProgressionEvaluationRecordQueryProperty on QueryBuilder<
    ProgressionEvaluationRecord, ProgressionEvaluationRecord, QQueryProperty> {
  QueryBuilder<ProgressionEvaluationRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, bool, QQueryOperations>
      achievedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'achieved');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, double, QQueryOperations>
      actualValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualValue');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      comparatorNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'comparatorName');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      domainNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'domainName');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, DateTime, QQueryOperations>
      evaluatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'evaluatedAt');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      evaluationKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'evaluationKey');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      explanationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'explanation');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String?, QQueryOperations>
      missReasonNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'missReasonName');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, DateTime, QQueryOperations>
      periodEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodEnd');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      periodKindNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKindName');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, DateTime, QQueryOperations>
      periodStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodStart');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, double, QQueryOperations>
      progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      rewardKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardKey');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, int, QQueryOperations>
      rewardXpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardXp');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      ruleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ruleId');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      ruleVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ruleVersion');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String?, QQueryOperations>
      statusNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statusName');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, double, QQueryOperations>
      targetValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetValue');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, String, QQueryOperations>
      titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, double, QQueryOperations>
      toleranceRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toleranceRatio');
    });
  }

  QueryBuilder<ProgressionEvaluationRecord, double?, QQueryOperations>
      upperTargetValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'upperTargetValue');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressionRewardGrantRecordCollection on Isar {
  IsarCollection<ProgressionRewardGrantRecord>
      get progressionRewardGrantRecords => this.collection();
}

const ProgressionRewardGrantRecordSchema = CollectionSchema(
  name: r'ProgressionRewardGrantRecord',
  id: -2648322457543841473,
  properties: {
    r'actualValue': PropertySchema(
      id: 0,
      name: r'actualValue',
      type: IsarType.double,
    ),
    r'claimedAt': PropertySchema(
      id: 1,
      name: r'claimedAt',
      type: IsarType.dateTime,
    ),
    r'domainName': PropertySchema(
      id: 2,
      name: r'domainName',
      type: IsarType.string,
    ),
    r'periodEnd': PropertySchema(
      id: 3,
      name: r'periodEnd',
      type: IsarType.dateTime,
    ),
    r'periodKindName': PropertySchema(
      id: 4,
      name: r'periodKindName',
      type: IsarType.string,
    ),
    r'periodStart': PropertySchema(
      id: 5,
      name: r'periodStart',
      type: IsarType.dateTime,
    ),
    r'rewardKey': PropertySchema(
      id: 6,
      name: r'rewardKey',
      type: IsarType.string,
    ),
    r'rewardStatusName': PropertySchema(
      id: 7,
      name: r'rewardStatusName',
      type: IsarType.string,
    ),
    r'ruleId': PropertySchema(
      id: 8,
      name: r'ruleId',
      type: IsarType.string,
    ),
    r'ruleVersion': PropertySchema(
      id: 9,
      name: r'ruleVersion',
      type: IsarType.string,
    ),
    r'targetValue': PropertySchema(
      id: 10,
      name: r'targetValue',
      type: IsarType.double,
    ),
    r'toleranceRatio': PropertySchema(
      id: 11,
      name: r'toleranceRatio',
      type: IsarType.double,
    ),
    r'unlockedAt': PropertySchema(
      id: 12,
      name: r'unlockedAt',
      type: IsarType.dateTime,
    ),
    r'upperTargetValue': PropertySchema(
      id: 13,
      name: r'upperTargetValue',
      type: IsarType.double,
    ),
    r'xpGranted': PropertySchema(
      id: 14,
      name: r'xpGranted',
      type: IsarType.long,
    )
  },
  estimateSize: _progressionRewardGrantRecordEstimateSize,
  serialize: _progressionRewardGrantRecordSerialize,
  deserialize: _progressionRewardGrantRecordDeserialize,
  deserializeProp: _progressionRewardGrantRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'rewardKey': IndexSchema(
      id: -8530480136332084194,
      name: r'rewardKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'rewardKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'periodStart': IndexSchema(
      id: -7133903706047263368,
      name: r'periodStart',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'periodStart',
          type: IndexType.value,
          caseSensitive: false,
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
    ),
    r'claimedAt': IndexSchema(
      id: 3602182620203233795,
      name: r'claimedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'claimedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _progressionRewardGrantRecordGetId,
  getLinks: _progressionRewardGrantRecordGetLinks,
  attach: _progressionRewardGrantRecordAttach,
  version: '3.1.0+1',
);

int _progressionRewardGrantRecordEstimateSize(
  ProgressionRewardGrantRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.domainName.length * 3;
  bytesCount += 3 + object.periodKindName.length * 3;
  bytesCount += 3 + object.rewardKey.length * 3;
  bytesCount += 3 + object.rewardStatusName.length * 3;
  bytesCount += 3 + object.ruleId.length * 3;
  bytesCount += 3 + object.ruleVersion.length * 3;
  return bytesCount;
}

void _progressionRewardGrantRecordSerialize(
  ProgressionRewardGrantRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.actualValue);
  writer.writeDateTime(offsets[1], object.claimedAt);
  writer.writeString(offsets[2], object.domainName);
  writer.writeDateTime(offsets[3], object.periodEnd);
  writer.writeString(offsets[4], object.periodKindName);
  writer.writeDateTime(offsets[5], object.periodStart);
  writer.writeString(offsets[6], object.rewardKey);
  writer.writeString(offsets[7], object.rewardStatusName);
  writer.writeString(offsets[8], object.ruleId);
  writer.writeString(offsets[9], object.ruleVersion);
  writer.writeDouble(offsets[10], object.targetValue);
  writer.writeDouble(offsets[11], object.toleranceRatio);
  writer.writeDateTime(offsets[12], object.unlockedAt);
  writer.writeDouble(offsets[13], object.upperTargetValue);
  writer.writeLong(offsets[14], object.xpGranted);
}

ProgressionRewardGrantRecord _progressionRewardGrantRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressionRewardGrantRecord();
  object.actualValue = reader.readDouble(offsets[0]);
  object.claimedAt = reader.readDateTimeOrNull(offsets[1]);
  object.domainName = reader.readString(offsets[2]);
  object.id = id;
  object.periodEnd = reader.readDateTime(offsets[3]);
  object.periodKindName = reader.readString(offsets[4]);
  object.periodStart = reader.readDateTime(offsets[5]);
  object.rewardKey = reader.readString(offsets[6]);
  object.rewardStatusName = reader.readString(offsets[7]);
  object.ruleId = reader.readString(offsets[8]);
  object.ruleVersion = reader.readString(offsets[9]);
  object.targetValue = reader.readDouble(offsets[10]);
  object.toleranceRatio = reader.readDouble(offsets[11]);
  object.unlockedAt = reader.readDateTime(offsets[12]);
  object.upperTargetValue = reader.readDoubleOrNull(offsets[13]);
  object.xpGranted = reader.readLong(offsets[14]);
  return object;
}

P _progressionRewardGrantRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _progressionRewardGrantRecordGetId(ProgressionRewardGrantRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _progressionRewardGrantRecordGetLinks(
    ProgressionRewardGrantRecord object) {
  return [];
}

void _progressionRewardGrantRecordAttach(
    IsarCollection<dynamic> col, Id id, ProgressionRewardGrantRecord object) {
  object.id = id;
}

extension ProgressionRewardGrantRecordByIndex
    on IsarCollection<ProgressionRewardGrantRecord> {
  Future<ProgressionRewardGrantRecord?> getByRewardKey(String rewardKey) {
    return getByIndex(r'rewardKey', [rewardKey]);
  }

  ProgressionRewardGrantRecord? getByRewardKeySync(String rewardKey) {
    return getByIndexSync(r'rewardKey', [rewardKey]);
  }

  Future<bool> deleteByRewardKey(String rewardKey) {
    return deleteByIndex(r'rewardKey', [rewardKey]);
  }

  bool deleteByRewardKeySync(String rewardKey) {
    return deleteByIndexSync(r'rewardKey', [rewardKey]);
  }

  Future<List<ProgressionRewardGrantRecord?>> getAllByRewardKey(
      List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'rewardKey', values);
  }

  List<ProgressionRewardGrantRecord?> getAllByRewardKeySync(
      List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'rewardKey', values);
  }

  Future<int> deleteAllByRewardKey(List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'rewardKey', values);
  }

  int deleteAllByRewardKeySync(List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'rewardKey', values);
  }

  Future<Id> putByRewardKey(ProgressionRewardGrantRecord object) {
    return putByIndex(r'rewardKey', object);
  }

  Id putByRewardKeySync(ProgressionRewardGrantRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'rewardKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRewardKey(
      List<ProgressionRewardGrantRecord> objects) {
    return putAllByIndex(r'rewardKey', objects);
  }

  List<Id> putAllByRewardKeySync(List<ProgressionRewardGrantRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'rewardKey', objects, saveLinks: saveLinks);
  }
}

extension ProgressionRewardGrantRecordQueryWhereSort on QueryBuilder<
    ProgressionRewardGrantRecord, ProgressionRewardGrantRecord, QWhere> {
  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhere> anyPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'periodStart'),
      );
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhere> anyUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'unlockedAt'),
      );
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhere> anyClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'claimedAt'),
      );
    });
  }
}

extension ProgressionRewardGrantRecordQueryWhere on QueryBuilder<
    ProgressionRewardGrantRecord, ProgressionRewardGrantRecord, QWhereClause> {
  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> rewardKeyEqualTo(String rewardKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'rewardKey',
        value: [rewardKey],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> rewardKeyNotEqualTo(String rewardKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [],
              upper: [rewardKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [rewardKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [rewardKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [],
              upper: [rewardKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> periodStartEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'periodStart',
        value: [periodStart],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> periodStartNotEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> periodStartGreaterThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [periodStart],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> periodStartLessThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [],
        upper: [periodStart],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> periodStartBetween(
    DateTime lowerPeriodStart,
    DateTime upperPeriodStart, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [lowerPeriodStart],
        includeLower: includeLower,
        upper: [upperPeriodStart],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> unlockedAtEqualTo(DateTime unlockedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'unlockedAt',
        value: [unlockedAt],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> unlockedAtNotEqualTo(DateTime unlockedAt) {
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> unlockedAtGreaterThan(
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> unlockedAtLessThan(
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> unlockedAtBetween(
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> claimedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'claimedAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> claimedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> claimedAtEqualTo(DateTime? claimedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'claimedAt',
        value: [claimedAt],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> claimedAtNotEqualTo(DateTime? claimedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [],
              upper: [claimedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [claimedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [claimedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [],
              upper: [claimedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> claimedAtGreaterThan(
    DateTime? claimedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [claimedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> claimedAtLessThan(
    DateTime? claimedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [],
        upper: [claimedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterWhereClause> claimedAtBetween(
    DateTime? lowerClaimedAt,
    DateTime? upperClaimedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [lowerClaimedAt],
        includeLower: includeLower,
        upper: [upperClaimedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressionRewardGrantRecordQueryFilter on QueryBuilder<
    ProgressionRewardGrantRecord,
    ProgressionRewardGrantRecord,
    QFilterCondition> {
  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> actualValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actualValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> actualValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actualValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> actualValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actualValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> actualValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actualValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> claimedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'claimedAt',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> claimedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'claimedAt',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> claimedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'claimedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> claimedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'claimedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> claimedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'claimedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> claimedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'claimedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'domainName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      domainNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'domainName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      domainNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'domainName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> domainNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'domainName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodEndEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodEndGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodEndLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodEndBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodKindName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      periodKindNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      periodKindNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodKindName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKindName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodKindNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodKindName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodStartGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodStartLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> periodStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      rewardKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      rewardKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rewardKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rewardKey',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardStatusName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      rewardStatusNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      rewardStatusNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rewardStatusName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardStatusName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rewardStatusName',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ruleId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      ruleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ruleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      ruleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ruleId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ruleId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ruleVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      ruleVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ruleVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
          QAfterFilterCondition>
      ruleVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ruleVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ruleVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> ruleVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ruleVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> targetValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> targetValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> targetValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> targetValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> toleranceRatioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toleranceRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> toleranceRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toleranceRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> toleranceRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toleranceRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> toleranceRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toleranceRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> unlockedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
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

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> upperTargetValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'upperTargetValue',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> upperTargetValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'upperTargetValue',
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> upperTargetValueEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'upperTargetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> upperTargetValueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'upperTargetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> upperTargetValueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'upperTargetValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> upperTargetValueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'upperTargetValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> xpGrantedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'xpGranted',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> xpGrantedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'xpGranted',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> xpGrantedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'xpGranted',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterFilterCondition> xpGrantedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'xpGranted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressionRewardGrantRecordQueryObject on QueryBuilder<
    ProgressionRewardGrantRecord,
    ProgressionRewardGrantRecord,
    QFilterCondition> {}

extension ProgressionRewardGrantRecordQueryLinks on QueryBuilder<
    ProgressionRewardGrantRecord,
    ProgressionRewardGrantRecord,
    QFilterCondition> {}

extension ProgressionRewardGrantRecordQuerySortBy on QueryBuilder<
    ProgressionRewardGrantRecord, ProgressionRewardGrantRecord, QSortBy> {
  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByActualValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByClaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByDomainName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByDomainNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByPeriodKindName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByPeriodKindNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRewardKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRewardKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRewardStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRewardStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRuleVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByRuleVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByToleranceRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByToleranceRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByUpperTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByUpperTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByXpGranted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> sortByXpGrantedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.desc);
    });
  }
}

extension ProgressionRewardGrantRecordQuerySortThenBy on QueryBuilder<
    ProgressionRewardGrantRecord, ProgressionRewardGrantRecord, QSortThenBy> {
  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByActualValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByClaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByDomainName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByDomainNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByPeriodKindName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByPeriodKindNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKindName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRewardKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRewardKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRewardStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRewardStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRuleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRuleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRuleVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByRuleVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ruleVersion', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByToleranceRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByToleranceRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toleranceRatio', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByUpperTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByUpperTargetValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upperTargetValue', Sort.desc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByXpGranted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.asc);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QAfterSortBy> thenByXpGrantedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.desc);
    });
  }
}

extension ProgressionRewardGrantRecordQueryWhereDistinct on QueryBuilder<
    ProgressionRewardGrantRecord, ProgressionRewardGrantRecord, QDistinct> {
  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualValue');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'claimedAt');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByDomainName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'domainName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodEnd');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByPeriodKindName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKindName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodStart');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByRewardKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByRewardStatusName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardStatusName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByRuleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ruleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByRuleVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ruleVersion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetValue');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByToleranceRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toleranceRatio');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockedAt');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByUpperTargetValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'upperTargetValue');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, ProgressionRewardGrantRecord,
      QDistinct> distinctByXpGranted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'xpGranted');
    });
  }
}

extension ProgressionRewardGrantRecordQueryProperty on QueryBuilder<
    ProgressionRewardGrantRecord,
    ProgressionRewardGrantRecord,
    QQueryProperty> {
  QueryBuilder<ProgressionRewardGrantRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, double, QQueryOperations>
      actualValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualValue');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, DateTime?, QQueryOperations>
      claimedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'claimedAt');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, String, QQueryOperations>
      domainNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'domainName');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, DateTime, QQueryOperations>
      periodEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodEnd');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, String, QQueryOperations>
      periodKindNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKindName');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, DateTime, QQueryOperations>
      periodStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodStart');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, String, QQueryOperations>
      rewardKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardKey');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, String, QQueryOperations>
      rewardStatusNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardStatusName');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, String, QQueryOperations>
      ruleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ruleId');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, String, QQueryOperations>
      ruleVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ruleVersion');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, double, QQueryOperations>
      targetValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetValue');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, double, QQueryOperations>
      toleranceRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toleranceRatio');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, DateTime, QQueryOperations>
      unlockedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockedAt');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, double?, QQueryOperations>
      upperTargetValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'upperTargetValue');
    });
  }

  QueryBuilder<ProgressionRewardGrantRecord, int, QQueryOperations>
      xpGrantedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'xpGranted');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressionQuestRewardGrantRecordCollection on Isar {
  IsarCollection<ProgressionQuestRewardGrantRecord>
      get progressionQuestRewardGrantRecords => this.collection();
}

const ProgressionQuestRewardGrantRecordSchema = CollectionSchema(
  name: r'ProgressionQuestRewardGrantRecord',
  id: -6982180433604569691,
  properties: {
    r'claimedAt': PropertySchema(
      id: 0,
      name: r'claimedAt',
      type: IsarType.dateTime,
    ),
    r'completedAt': PropertySchema(
      id: 1,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'questId': PropertySchema(
      id: 2,
      name: r'questId',
      type: IsarType.string,
    ),
    r'rewardKey': PropertySchema(
      id: 3,
      name: r'rewardKey',
      type: IsarType.string,
    ),
    r'rewardStatusName': PropertySchema(
      id: 4,
      name: r'rewardStatusName',
      type: IsarType.string,
    ),
    r'unlockedAt': PropertySchema(
      id: 5,
      name: r'unlockedAt',
      type: IsarType.dateTime,
    ),
    r'xpGranted': PropertySchema(
      id: 6,
      name: r'xpGranted',
      type: IsarType.long,
    )
  },
  estimateSize: _progressionQuestRewardGrantRecordEstimateSize,
  serialize: _progressionQuestRewardGrantRecordSerialize,
  deserialize: _progressionQuestRewardGrantRecordDeserialize,
  deserializeProp: _progressionQuestRewardGrantRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'rewardKey': IndexSchema(
      id: -8530480136332084194,
      name: r'rewardKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'rewardKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'questId': IndexSchema(
      id: -312090079606683354,
      name: r'questId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'questId',
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
    ),
    r'completedAt': IndexSchema(
      id: -3156591011457686752,
      name: r'completedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'completedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'claimedAt': IndexSchema(
      id: 3602182620203233795,
      name: r'claimedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'claimedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _progressionQuestRewardGrantRecordGetId,
  getLinks: _progressionQuestRewardGrantRecordGetLinks,
  attach: _progressionQuestRewardGrantRecordAttach,
  version: '3.1.0+1',
);

int _progressionQuestRewardGrantRecordEstimateSize(
  ProgressionQuestRewardGrantRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.questId.length * 3;
  bytesCount += 3 + object.rewardKey.length * 3;
  bytesCount += 3 + object.rewardStatusName.length * 3;
  return bytesCount;
}

void _progressionQuestRewardGrantRecordSerialize(
  ProgressionQuestRewardGrantRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.claimedAt);
  writer.writeDateTime(offsets[1], object.completedAt);
  writer.writeString(offsets[2], object.questId);
  writer.writeString(offsets[3], object.rewardKey);
  writer.writeString(offsets[4], object.rewardStatusName);
  writer.writeDateTime(offsets[5], object.unlockedAt);
  writer.writeLong(offsets[6], object.xpGranted);
}

ProgressionQuestRewardGrantRecord _progressionQuestRewardGrantRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressionQuestRewardGrantRecord();
  object.claimedAt = reader.readDateTimeOrNull(offsets[0]);
  object.completedAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.questId = reader.readString(offsets[2]);
  object.rewardKey = reader.readString(offsets[3]);
  object.rewardStatusName = reader.readString(offsets[4]);
  object.unlockedAt = reader.readDateTime(offsets[5]);
  object.xpGranted = reader.readLong(offsets[6]);
  return object;
}

P _progressionQuestRewardGrantRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _progressionQuestRewardGrantRecordGetId(
    ProgressionQuestRewardGrantRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _progressionQuestRewardGrantRecordGetLinks(
    ProgressionQuestRewardGrantRecord object) {
  return [];
}

void _progressionQuestRewardGrantRecordAttach(IsarCollection<dynamic> col,
    Id id, ProgressionQuestRewardGrantRecord object) {
  object.id = id;
}

extension ProgressionQuestRewardGrantRecordByIndex
    on IsarCollection<ProgressionQuestRewardGrantRecord> {
  Future<ProgressionQuestRewardGrantRecord?> getByRewardKey(String rewardKey) {
    return getByIndex(r'rewardKey', [rewardKey]);
  }

  ProgressionQuestRewardGrantRecord? getByRewardKeySync(String rewardKey) {
    return getByIndexSync(r'rewardKey', [rewardKey]);
  }

  Future<bool> deleteByRewardKey(String rewardKey) {
    return deleteByIndex(r'rewardKey', [rewardKey]);
  }

  bool deleteByRewardKeySync(String rewardKey) {
    return deleteByIndexSync(r'rewardKey', [rewardKey]);
  }

  Future<List<ProgressionQuestRewardGrantRecord?>> getAllByRewardKey(
      List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'rewardKey', values);
  }

  List<ProgressionQuestRewardGrantRecord?> getAllByRewardKeySync(
      List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'rewardKey', values);
  }

  Future<int> deleteAllByRewardKey(List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'rewardKey', values);
  }

  int deleteAllByRewardKeySync(List<String> rewardKeyValues) {
    final values = rewardKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'rewardKey', values);
  }

  Future<Id> putByRewardKey(ProgressionQuestRewardGrantRecord object) {
    return putByIndex(r'rewardKey', object);
  }

  Id putByRewardKeySync(ProgressionQuestRewardGrantRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'rewardKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRewardKey(
      List<ProgressionQuestRewardGrantRecord> objects) {
    return putAllByIndex(r'rewardKey', objects);
  }

  List<Id> putAllByRewardKeySync(
      List<ProgressionQuestRewardGrantRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'rewardKey', objects, saveLinks: saveLinks);
  }
}

extension ProgressionQuestRewardGrantRecordQueryWhereSort on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QWhere> {
  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhere> anyUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'unlockedAt'),
      );
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhere> anyCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'completedAt'),
      );
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhere> anyClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'claimedAt'),
      );
    });
  }
}

extension ProgressionQuestRewardGrantRecordQueryWhere on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QWhereClause> {
  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
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

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> rewardKeyEqualTo(String rewardKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'rewardKey',
        value: [rewardKey],
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> rewardKeyNotEqualTo(String rewardKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [],
              upper: [rewardKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [rewardKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [rewardKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'rewardKey',
              lower: [],
              upper: [rewardKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> questIdEqualTo(String questId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'questId',
        value: [questId],
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> questIdNotEqualTo(String questId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [],
              upper: [questId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [questId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [questId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [],
              upper: [questId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> unlockedAtEqualTo(DateTime unlockedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'unlockedAt',
        value: [unlockedAt],
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> unlockedAtNotEqualTo(DateTime unlockedAt) {
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

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> unlockedAtGreaterThan(
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

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> unlockedAtLessThan(
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

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> unlockedAtBetween(
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

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> completedAtEqualTo(DateTime completedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'completedAt',
        value: [completedAt],
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> completedAtNotEqualTo(DateTime completedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completedAt',
              lower: [],
              upper: [completedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completedAt',
              lower: [completedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completedAt',
              lower: [completedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completedAt',
              lower: [],
              upper: [completedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> completedAtGreaterThan(
    DateTime completedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'completedAt',
        lower: [completedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> completedAtLessThan(
    DateTime completedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'completedAt',
        lower: [],
        upper: [completedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> completedAtBetween(
    DateTime lowerCompletedAt,
    DateTime upperCompletedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'completedAt',
        lower: [lowerCompletedAt],
        includeLower: includeLower,
        upper: [upperCompletedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> claimedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'claimedAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> claimedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> claimedAtEqualTo(DateTime? claimedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'claimedAt',
        value: [claimedAt],
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> claimedAtNotEqualTo(DateTime? claimedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [],
              upper: [claimedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [claimedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [claimedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'claimedAt',
              lower: [],
              upper: [claimedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterWhereClause> claimedAtGreaterThan(
    DateTime? claimedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [claimedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> claimedAtLessThan(
    DateTime? claimedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [],
        upper: [claimedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterWhereClause> claimedAtBetween(
    DateTime? lowerClaimedAt,
    DateTime? upperClaimedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'claimedAt',
        lower: [lowerClaimedAt],
        includeLower: includeLower,
        upper: [upperClaimedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressionQuestRewardGrantRecordQueryFilter on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QFilterCondition> {
  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> claimedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'claimedAt',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> claimedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'claimedAt',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> claimedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'claimedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> claimedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'claimedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> claimedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'claimedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> claimedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'claimedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> completedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> completedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> completedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> completedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterFilterCondition> questIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> questIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterFilterCondition> questIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterFilterCondition> questIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'questId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> questIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterFilterCondition> questIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
          ProgressionQuestRewardGrantRecord, QAfterFilterCondition>
      questIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
          ProgressionQuestRewardGrantRecord, QAfterFilterCondition>
      questIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'questId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> questIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questId',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> questIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'questId',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
          ProgressionQuestRewardGrantRecord, QAfterFilterCondition>
      rewardKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rewardKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
          ProgressionQuestRewardGrantRecord, QAfterFilterCondition>
      rewardKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rewardKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKey',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rewardKey',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardStatusName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
          ProgressionQuestRewardGrantRecord, QAfterFilterCondition>
      rewardStatusNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rewardStatusName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
          ProgressionQuestRewardGrantRecord, QAfterFilterCondition>
      rewardStatusNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rewardStatusName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardStatusName',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> rewardStatusNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rewardStatusName',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> unlockedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
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

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
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

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
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

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> xpGrantedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'xpGranted',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> xpGrantedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'xpGranted',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> xpGrantedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'xpGranted',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterFilterCondition> xpGrantedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'xpGranted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressionQuestRewardGrantRecordQueryObject on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QFilterCondition> {}

extension ProgressionQuestRewardGrantRecordQueryLinks on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QFilterCondition> {}

extension ProgressionQuestRewardGrantRecordQuerySortBy on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QSortBy> {
  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByClaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByQuestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByQuestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByRewardKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByRewardKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.desc);
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterSortBy> sortByRewardStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.asc);
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterSortBy> sortByRewardStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByXpGranted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> sortByXpGrantedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.desc);
    });
  }
}

extension ProgressionQuestRewardGrantRecordQuerySortThenBy on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QSortThenBy> {
  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByClaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByQuestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByQuestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByRewardKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByRewardKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKey', Sort.desc);
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterSortBy> thenByRewardStatusName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.asc);
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QAfterSortBy> thenByRewardStatusNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardStatusName', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByXpGranted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.asc);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QAfterSortBy> thenByXpGrantedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpGranted', Sort.desc);
    });
  }
}

extension ProgressionQuestRewardGrantRecordQueryWhereDistinct on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QDistinct> {
  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QDistinct> distinctByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'claimedAt');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QDistinct> distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QDistinct> distinctByQuestId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QDistinct> distinctByRewardKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
      ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord,
      QDistinct> distinctByRewardStatusName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardStatusName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QDistinct> distinctByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockedAt');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord,
      ProgressionQuestRewardGrantRecord, QDistinct> distinctByXpGranted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'xpGranted');
    });
  }
}

extension ProgressionQuestRewardGrantRecordQueryProperty on QueryBuilder<
    ProgressionQuestRewardGrantRecord,
    ProgressionQuestRewardGrantRecord,
    QQueryProperty> {
  QueryBuilder<ProgressionQuestRewardGrantRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord, DateTime?, QQueryOperations>
      claimedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'claimedAt');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord, DateTime, QQueryOperations>
      completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord, String, QQueryOperations>
      questIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questId');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord, String, QQueryOperations>
      rewardKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardKey');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord, String, QQueryOperations>
      rewardStatusNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardStatusName');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord, DateTime, QQueryOperations>
      unlockedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockedAt');
    });
  }

  QueryBuilder<ProgressionQuestRewardGrantRecord, int, QQueryOperations>
      xpGrantedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'xpGranted');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressionActiveQuestRecordCollection on Isar {
  IsarCollection<ProgressionActiveQuestRecord>
      get progressionActiveQuestRecords => this.collection();
}

const ProgressionActiveQuestRecordSchema = CollectionSchema(
  name: r'ProgressionActiveQuestRecord',
  id: -776041102200277811,
  properties: {
    r'assignedAt': PropertySchema(
      id: 0,
      name: r'assignedAt',
      type: IsarType.dateTime,
    ),
    r'questId': PropertySchema(
      id: 1,
      name: r'questId',
      type: IsarType.string,
    )
  },
  estimateSize: _progressionActiveQuestRecordEstimateSize,
  serialize: _progressionActiveQuestRecordSerialize,
  deserialize: _progressionActiveQuestRecordDeserialize,
  deserializeProp: _progressionActiveQuestRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'questId': IndexSchema(
      id: -312090079606683354,
      name: r'questId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'questId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'assignedAt': IndexSchema(
      id: -6202192226478979906,
      name: r'assignedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'assignedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _progressionActiveQuestRecordGetId,
  getLinks: _progressionActiveQuestRecordGetLinks,
  attach: _progressionActiveQuestRecordAttach,
  version: '3.1.0+1',
);

int _progressionActiveQuestRecordEstimateSize(
  ProgressionActiveQuestRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.questId.length * 3;
  return bytesCount;
}

void _progressionActiveQuestRecordSerialize(
  ProgressionActiveQuestRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.assignedAt);
  writer.writeString(offsets[1], object.questId);
}

ProgressionActiveQuestRecord _progressionActiveQuestRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressionActiveQuestRecord();
  object.assignedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.questId = reader.readString(offsets[1]);
  return object;
}

P _progressionActiveQuestRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _progressionActiveQuestRecordGetId(ProgressionActiveQuestRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _progressionActiveQuestRecordGetLinks(
    ProgressionActiveQuestRecord object) {
  return [];
}

void _progressionActiveQuestRecordAttach(
    IsarCollection<dynamic> col, Id id, ProgressionActiveQuestRecord object) {
  object.id = id;
}

extension ProgressionActiveQuestRecordByIndex
    on IsarCollection<ProgressionActiveQuestRecord> {
  Future<ProgressionActiveQuestRecord?> getByQuestId(String questId) {
    return getByIndex(r'questId', [questId]);
  }

  ProgressionActiveQuestRecord? getByQuestIdSync(String questId) {
    return getByIndexSync(r'questId', [questId]);
  }

  Future<bool> deleteByQuestId(String questId) {
    return deleteByIndex(r'questId', [questId]);
  }

  bool deleteByQuestIdSync(String questId) {
    return deleteByIndexSync(r'questId', [questId]);
  }

  Future<List<ProgressionActiveQuestRecord?>> getAllByQuestId(
      List<String> questIdValues) {
    final values = questIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'questId', values);
  }

  List<ProgressionActiveQuestRecord?> getAllByQuestIdSync(
      List<String> questIdValues) {
    final values = questIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'questId', values);
  }

  Future<int> deleteAllByQuestId(List<String> questIdValues) {
    final values = questIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'questId', values);
  }

  int deleteAllByQuestIdSync(List<String> questIdValues) {
    final values = questIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'questId', values);
  }

  Future<Id> putByQuestId(ProgressionActiveQuestRecord object) {
    return putByIndex(r'questId', object);
  }

  Id putByQuestIdSync(ProgressionActiveQuestRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'questId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByQuestId(List<ProgressionActiveQuestRecord> objects) {
    return putAllByIndex(r'questId', objects);
  }

  List<Id> putAllByQuestIdSync(List<ProgressionActiveQuestRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'questId', objects, saveLinks: saveLinks);
  }
}

extension ProgressionActiveQuestRecordQueryWhereSort on QueryBuilder<
    ProgressionActiveQuestRecord, ProgressionActiveQuestRecord, QWhere> {
  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhere> anyAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'assignedAt'),
      );
    });
  }
}

extension ProgressionActiveQuestRecordQueryWhere on QueryBuilder<
    ProgressionActiveQuestRecord, ProgressionActiveQuestRecord, QWhereClause> {
  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
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

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
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

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> questIdEqualTo(String questId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'questId',
        value: [questId],
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> questIdNotEqualTo(String questId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [],
              upper: [questId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [questId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [questId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'questId',
              lower: [],
              upper: [questId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> assignedAtEqualTo(DateTime assignedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'assignedAt',
        value: [assignedAt],
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> assignedAtNotEqualTo(DateTime assignedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assignedAt',
              lower: [],
              upper: [assignedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assignedAt',
              lower: [assignedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assignedAt',
              lower: [assignedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'assignedAt',
              lower: [],
              upper: [assignedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> assignedAtGreaterThan(
    DateTime assignedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'assignedAt',
        lower: [assignedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> assignedAtLessThan(
    DateTime assignedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'assignedAt',
        lower: [],
        upper: [assignedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterWhereClause> assignedAtBetween(
    DateTime lowerAssignedAt,
    DateTime upperAssignedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'assignedAt',
        lower: [lowerAssignedAt],
        includeLower: includeLower,
        upper: [upperAssignedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProgressionActiveQuestRecordQueryFilter on QueryBuilder<
    ProgressionActiveQuestRecord,
    ProgressionActiveQuestRecord,
    QFilterCondition> {
  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> assignedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> assignedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assignedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> assignedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assignedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> assignedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assignedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
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

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
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

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
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

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'questId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
          QAfterFilterCondition>
      questIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'questId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
          QAfterFilterCondition>
      questIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'questId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterFilterCondition> questIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'questId',
        value: '',
      ));
    });
  }
}

extension ProgressionActiveQuestRecordQueryObject on QueryBuilder<
    ProgressionActiveQuestRecord,
    ProgressionActiveQuestRecord,
    QFilterCondition> {}

extension ProgressionActiveQuestRecordQueryLinks on QueryBuilder<
    ProgressionActiveQuestRecord,
    ProgressionActiveQuestRecord,
    QFilterCondition> {}

extension ProgressionActiveQuestRecordQuerySortBy on QueryBuilder<
    ProgressionActiveQuestRecord, ProgressionActiveQuestRecord, QSortBy> {
  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> sortByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> sortByAssignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> sortByQuestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> sortByQuestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.desc);
    });
  }
}

extension ProgressionActiveQuestRecordQuerySortThenBy on QueryBuilder<
    ProgressionActiveQuestRecord, ProgressionActiveQuestRecord, QSortThenBy> {
  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> thenByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> thenByAssignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.desc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> thenByQuestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.asc);
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QAfterSortBy> thenByQuestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questId', Sort.desc);
    });
  }
}

extension ProgressionActiveQuestRecordQueryWhereDistinct on QueryBuilder<
    ProgressionActiveQuestRecord, ProgressionActiveQuestRecord, QDistinct> {
  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QDistinct> distinctByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedAt');
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, ProgressionActiveQuestRecord,
      QDistinct> distinctByQuestId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questId', caseSensitive: caseSensitive);
    });
  }
}

extension ProgressionActiveQuestRecordQueryProperty on QueryBuilder<
    ProgressionActiveQuestRecord,
    ProgressionActiveQuestRecord,
    QQueryProperty> {
  QueryBuilder<ProgressionActiveQuestRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, DateTime, QQueryOperations>
      assignedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedAt');
    });
  }

  QueryBuilder<ProgressionActiveQuestRecord, String, QQueryOperations>
      questIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProgressionAchievementUnlockRecordCollection on Isar {
  IsarCollection<ProgressionAchievementUnlockRecord>
      get progressionAchievementUnlockRecords => this.collection();
}

const ProgressionAchievementUnlockRecordSchema = CollectionSchema(
  name: r'ProgressionAchievementUnlockRecord',
  id: -7533353973035278816,
  properties: {
    r'achievementId': PropertySchema(
      id: 0,
      name: r'achievementId',
      type: IsarType.string,
    ),
    r'unlockKey': PropertySchema(
      id: 1,
      name: r'unlockKey',
      type: IsarType.string,
    ),
    r'unlockedAt': PropertySchema(
      id: 2,
      name: r'unlockedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _progressionAchievementUnlockRecordEstimateSize,
  serialize: _progressionAchievementUnlockRecordSerialize,
  deserialize: _progressionAchievementUnlockRecordDeserialize,
  deserializeProp: _progressionAchievementUnlockRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'unlockKey': IndexSchema(
      id: -2036961389800305509,
      name: r'unlockKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'unlockKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'achievementId': IndexSchema(
      id: 547487615361511857,
      name: r'achievementId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'achievementId',
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
  getId: _progressionAchievementUnlockRecordGetId,
  getLinks: _progressionAchievementUnlockRecordGetLinks,
  attach: _progressionAchievementUnlockRecordAttach,
  version: '3.1.0+1',
);

int _progressionAchievementUnlockRecordEstimateSize(
  ProgressionAchievementUnlockRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.achievementId.length * 3;
  bytesCount += 3 + object.unlockKey.length * 3;
  return bytesCount;
}

void _progressionAchievementUnlockRecordSerialize(
  ProgressionAchievementUnlockRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.achievementId);
  writer.writeString(offsets[1], object.unlockKey);
  writer.writeDateTime(offsets[2], object.unlockedAt);
}

ProgressionAchievementUnlockRecord
    _progressionAchievementUnlockRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProgressionAchievementUnlockRecord();
  object.achievementId = reader.readString(offsets[0]);
  object.id = id;
  object.unlockKey = reader.readString(offsets[1]);
  object.unlockedAt = reader.readDateTime(offsets[2]);
  return object;
}

P _progressionAchievementUnlockRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _progressionAchievementUnlockRecordGetId(
    ProgressionAchievementUnlockRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _progressionAchievementUnlockRecordGetLinks(
    ProgressionAchievementUnlockRecord object) {
  return [];
}

void _progressionAchievementUnlockRecordAttach(IsarCollection<dynamic> col,
    Id id, ProgressionAchievementUnlockRecord object) {
  object.id = id;
}

extension ProgressionAchievementUnlockRecordByIndex
    on IsarCollection<ProgressionAchievementUnlockRecord> {
  Future<ProgressionAchievementUnlockRecord?> getByUnlockKey(String unlockKey) {
    return getByIndex(r'unlockKey', [unlockKey]);
  }

  ProgressionAchievementUnlockRecord? getByUnlockKeySync(String unlockKey) {
    return getByIndexSync(r'unlockKey', [unlockKey]);
  }

  Future<bool> deleteByUnlockKey(String unlockKey) {
    return deleteByIndex(r'unlockKey', [unlockKey]);
  }

  bool deleteByUnlockKeySync(String unlockKey) {
    return deleteByIndexSync(r'unlockKey', [unlockKey]);
  }

  Future<List<ProgressionAchievementUnlockRecord?>> getAllByUnlockKey(
      List<String> unlockKeyValues) {
    final values = unlockKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'unlockKey', values);
  }

  List<ProgressionAchievementUnlockRecord?> getAllByUnlockKeySync(
      List<String> unlockKeyValues) {
    final values = unlockKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'unlockKey', values);
  }

  Future<int> deleteAllByUnlockKey(List<String> unlockKeyValues) {
    final values = unlockKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'unlockKey', values);
  }

  int deleteAllByUnlockKeySync(List<String> unlockKeyValues) {
    final values = unlockKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'unlockKey', values);
  }

  Future<Id> putByUnlockKey(ProgressionAchievementUnlockRecord object) {
    return putByIndex(r'unlockKey', object);
  }

  Id putByUnlockKeySync(ProgressionAchievementUnlockRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'unlockKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUnlockKey(
      List<ProgressionAchievementUnlockRecord> objects) {
    return putAllByIndex(r'unlockKey', objects);
  }

  List<Id> putAllByUnlockKeySync(
      List<ProgressionAchievementUnlockRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'unlockKey', objects, saveLinks: saveLinks);
  }
}

extension ProgressionAchievementUnlockRecordQueryWhereSort on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QWhere> {
  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterWhere> anyUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'unlockedAt'),
      );
    });
  }
}

extension ProgressionAchievementUnlockRecordQueryWhere on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QWhereClause> {
  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
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

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> unlockKeyEqualTo(String unlockKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'unlockKey',
        value: [unlockKey],
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> unlockKeyNotEqualTo(String unlockKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockKey',
              lower: [],
              upper: [unlockKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockKey',
              lower: [unlockKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockKey',
              lower: [unlockKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'unlockKey',
              lower: [],
              upper: [unlockKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> achievementIdEqualTo(String achievementId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'achievementId',
        value: [achievementId],
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> achievementIdNotEqualTo(String achievementId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'achievementId',
              lower: [],
              upper: [achievementId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'achievementId',
              lower: [achievementId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'achievementId',
              lower: [achievementId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'achievementId',
              lower: [],
              upper: [achievementId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> unlockedAtEqualTo(DateTime unlockedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'unlockedAt',
        value: [unlockedAt],
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> unlockedAtNotEqualTo(DateTime unlockedAt) {
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

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterWhereClause> unlockedAtGreaterThan(
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

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterWhereClause> unlockedAtLessThan(
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

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterWhereClause> unlockedAtBetween(
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

extension ProgressionAchievementUnlockRecordQueryFilter on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QFilterCondition> {
  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'achievementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'achievementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'achievementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'achievementId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'achievementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'achievementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
          ProgressionAchievementUnlockRecord, QAfterFilterCondition>
      achievementIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'achievementId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
          ProgressionAchievementUnlockRecord, QAfterFilterCondition>
      achievementIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'achievementId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'achievementId',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> achievementIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'achievementId',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unlockKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unlockKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unlockKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'unlockKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'unlockKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
          ProgressionAchievementUnlockRecord, QAfterFilterCondition>
      unlockKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'unlockKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
          ProgressionAchievementUnlockRecord, QAfterFilterCondition>
      unlockKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'unlockKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockKey',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'unlockKey',
        value: '',
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterFilterCondition> unlockedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
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

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
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

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
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

extension ProgressionAchievementUnlockRecordQueryObject on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QFilterCondition> {}

extension ProgressionAchievementUnlockRecordQueryLinks on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QFilterCondition> {}

extension ProgressionAchievementUnlockRecordQuerySortBy on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QSortBy> {
  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> sortByAchievementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementId', Sort.asc);
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterSortBy> sortByAchievementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> sortByUnlockKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> sortByUnlockKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> sortByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> sortByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }
}

extension ProgressionAchievementUnlockRecordQuerySortThenBy on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QSortThenBy> {
  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> thenByAchievementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementId', Sort.asc);
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QAfterSortBy> thenByAchievementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievementId', Sort.desc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> thenByUnlockKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockKey', Sort.asc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> thenByUnlockKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockKey', Sort.desc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> thenByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QAfterSortBy> thenByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }
}

extension ProgressionAchievementUnlockRecordQueryWhereDistinct on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QDistinct> {
  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QDistinct> distinctByAchievementId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'achievementId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
      ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord,
      QDistinct> distinctByUnlockKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord,
      ProgressionAchievementUnlockRecord, QDistinct> distinctByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockedAt');
    });
  }
}

extension ProgressionAchievementUnlockRecordQueryProperty on QueryBuilder<
    ProgressionAchievementUnlockRecord,
    ProgressionAchievementUnlockRecord,
    QQueryProperty> {
  QueryBuilder<ProgressionAchievementUnlockRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord, String, QQueryOperations>
      achievementIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'achievementId');
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord, String, QQueryOperations>
      unlockKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockKey');
    });
  }

  QueryBuilder<ProgressionAchievementUnlockRecord, DateTime, QQueryOperations>
      unlockedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockedAt');
    });
  }
}

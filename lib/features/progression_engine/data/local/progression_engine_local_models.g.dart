// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_engine_local_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEngineObjectiveCompletionRecordCollection on Isar {
  IsarCollection<EngineObjectiveCompletionRecord>
      get engineObjectiveCompletionRecords => this.collection();
}

const EngineObjectiveCompletionRecordSchema = CollectionSchema(
  name: r'EngineObjectiveCompletionRecord',
  id: 2210930234838230268,
  properties: {
    r'actualValue': PropertySchema(
      id: 0,
      name: r'actualValue',
      type: IsarType.double,
    ),
    r'eventKey': PropertySchema(
      id: 1,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'objectiveId': PropertySchema(
      id: 2,
      name: r'objectiveId',
      type: IsarType.string,
    ),
    r'periodKey': PropertySchema(
      id: 3,
      name: r'periodKey',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 4,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _engineObjectiveCompletionRecordEstimateSize,
  serialize: _engineObjectiveCompletionRecordSerialize,
  deserialize: _engineObjectiveCompletionRecordDeserialize,
  deserializeProp: _engineObjectiveCompletionRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey': IndexSchema(
      id: -6167434590247707527,
      name: r'eventKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'objectiveId': IndexSchema(
      id: 4544467843646747176,
      name: r'objectiveId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'objectiveId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _engineObjectiveCompletionRecordGetId,
  getLinks: _engineObjectiveCompletionRecordGetLinks,
  attach: _engineObjectiveCompletionRecordAttach,
  version: '3.1.0+1',
);

int _engineObjectiveCompletionRecordEstimateSize(
  EngineObjectiveCompletionRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.objectiveId.length * 3;
  {
    final value = object.periodKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _engineObjectiveCompletionRecordSerialize(
  EngineObjectiveCompletionRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.actualValue);
  writer.writeString(offsets[1], object.eventKey);
  writer.writeString(offsets[2], object.objectiveId);
  writer.writeString(offsets[3], object.periodKey);
  writer.writeDateTime(offsets[4], object.timestamp);
}

EngineObjectiveCompletionRecord _engineObjectiveCompletionRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EngineObjectiveCompletionRecord();
  object.actualValue = reader.readDouble(offsets[0]);
  object.eventKey = reader.readString(offsets[1]);
  object.id = id;
  object.objectiveId = reader.readString(offsets[2]);
  object.periodKey = reader.readStringOrNull(offsets[3]);
  object.timestamp = reader.readDateTime(offsets[4]);
  return object;
}

P _engineObjectiveCompletionRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _engineObjectiveCompletionRecordGetId(
    EngineObjectiveCompletionRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _engineObjectiveCompletionRecordGetLinks(
    EngineObjectiveCompletionRecord object) {
  return [];
}

void _engineObjectiveCompletionRecordAttach(IsarCollection<dynamic> col, Id id,
    EngineObjectiveCompletionRecord object) {
  object.id = id;
}

extension EngineObjectiveCompletionRecordByIndex
    on IsarCollection<EngineObjectiveCompletionRecord> {
  Future<EngineObjectiveCompletionRecord?> getByEventKey(String eventKey) {
    return getByIndex(r'eventKey', [eventKey]);
  }

  EngineObjectiveCompletionRecord? getByEventKeySync(String eventKey) {
    return getByIndexSync(r'eventKey', [eventKey]);
  }

  Future<bool> deleteByEventKey(String eventKey) {
    return deleteByIndex(r'eventKey', [eventKey]);
  }

  bool deleteByEventKeySync(String eventKey) {
    return deleteByIndexSync(r'eventKey', [eventKey]);
  }

  Future<List<EngineObjectiveCompletionRecord?>> getAllByEventKey(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventKey', values);
  }

  List<EngineObjectiveCompletionRecord?> getAllByEventKeySync(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventKey', values);
  }

  Future<int> deleteAllByEventKey(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventKey', values);
  }

  int deleteAllByEventKeySync(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventKey', values);
  }

  Future<Id> putByEventKey(EngineObjectiveCompletionRecord object) {
    return putByIndex(r'eventKey', object);
  }

  Id putByEventKeySync(EngineObjectiveCompletionRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'eventKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventKey(
      List<EngineObjectiveCompletionRecord> objects) {
    return putAllByIndex(r'eventKey', objects);
  }

  List<Id> putAllByEventKeySync(List<EngineObjectiveCompletionRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventKey', objects, saveLinks: saveLinks);
  }
}

extension EngineObjectiveCompletionRecordQueryWhereSort on QueryBuilder<
    EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord, QWhere> {
  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension EngineObjectiveCompletionRecordQueryWhere on QueryBuilder<
    EngineObjectiveCompletionRecord,
    EngineObjectiveCompletionRecord,
    QWhereClause> {
  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> eventKeyEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventKey',
        value: [eventKey],
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> eventKeyNotEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> objectiveIdEqualTo(String objectiveId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'objectiveId',
        value: [objectiveId],
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> objectiveIdNotEqualTo(String objectiveId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'objectiveId',
              lower: [],
              upper: [objectiveId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'objectiveId',
              lower: [objectiveId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'objectiveId',
              lower: [objectiveId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'objectiveId',
              lower: [],
              upper: [objectiveId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterWhereClause> timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineObjectiveCompletionRecordQueryFilter on QueryBuilder<
    EngineObjectiveCompletionRecord,
    EngineObjectiveCompletionRecord,
    QFilterCondition> {
  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
          QAfterFilterCondition>
      eventKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
          QAfterFilterCondition>
      eventKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
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

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'objectiveId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'objectiveId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'objectiveId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'objectiveId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'objectiveId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'objectiveId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
          QAfterFilterCondition>
      objectiveIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'objectiveId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
          QAfterFilterCondition>
      objectiveIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'objectiveId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'objectiveId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> objectiveIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'objectiveId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
          QAfterFilterCondition>
      periodKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
          QAfterFilterCondition>
      periodKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> periodKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineObjectiveCompletionRecordQueryObject on QueryBuilder<
    EngineObjectiveCompletionRecord,
    EngineObjectiveCompletionRecord,
    QFilterCondition> {}

extension EngineObjectiveCompletionRecordQueryLinks on QueryBuilder<
    EngineObjectiveCompletionRecord,
    EngineObjectiveCompletionRecord,
    QFilterCondition> {}

extension EngineObjectiveCompletionRecordQuerySortBy on QueryBuilder<
    EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord, QSortBy> {
  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByActualValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByObjectiveId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'objectiveId', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByObjectiveIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'objectiveId', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineObjectiveCompletionRecordQuerySortThenBy on QueryBuilder<
    EngineObjectiveCompletionRecord,
    EngineObjectiveCompletionRecord,
    QSortThenBy> {
  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByActualValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualValue', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByObjectiveId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'objectiveId', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByObjectiveIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'objectiveId', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineObjectiveCompletionRecordQueryWhereDistinct on QueryBuilder<
    EngineObjectiveCompletionRecord,
    EngineObjectiveCompletionRecord,
    QDistinct> {
  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QDistinct> distinctByActualValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualValue');
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QDistinct> distinctByEventKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QDistinct> distinctByObjectiveId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'objectiveId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QDistinct> distinctByPeriodKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, EngineObjectiveCompletionRecord,
      QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension EngineObjectiveCompletionRecordQueryProperty on QueryBuilder<
    EngineObjectiveCompletionRecord,
    EngineObjectiveCompletionRecord,
    QQueryProperty> {
  QueryBuilder<EngineObjectiveCompletionRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, double, QQueryOperations>
      actualValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualValue');
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, String, QQueryOperations>
      eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, String, QQueryOperations>
      objectiveIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'objectiveId');
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, String?, QQueryOperations>
      periodKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKey');
    });
  }

  QueryBuilder<EngineObjectiveCompletionRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEngineNodeCompletionRecordCollection on Isar {
  IsarCollection<EngineNodeCompletionRecord> get engineNodeCompletionRecords =>
      this.collection();
}

const EngineNodeCompletionRecordSchema = CollectionSchema(
  name: r'EngineNodeCompletionRecord',
  id: -7924054928218853407,
  properties: {
    r'eventKey': PropertySchema(
      id: 0,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'nodeId': PropertySchema(
      id: 1,
      name: r'nodeId',
      type: IsarType.string,
    ),
    r'periodKey': PropertySchema(
      id: 2,
      name: r'periodKey',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _engineNodeCompletionRecordEstimateSize,
  serialize: _engineNodeCompletionRecordSerialize,
  deserialize: _engineNodeCompletionRecordDeserialize,
  deserializeProp: _engineNodeCompletionRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey': IndexSchema(
      id: -6167434590247707527,
      name: r'eventKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'nodeId': IndexSchema(
      id: -6491850230428693976,
      name: r'nodeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nodeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _engineNodeCompletionRecordGetId,
  getLinks: _engineNodeCompletionRecordGetLinks,
  attach: _engineNodeCompletionRecordAttach,
  version: '3.1.0+1',
);

int _engineNodeCompletionRecordEstimateSize(
  EngineNodeCompletionRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.nodeId.length * 3;
  {
    final value = object.periodKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _engineNodeCompletionRecordSerialize(
  EngineNodeCompletionRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.eventKey);
  writer.writeString(offsets[1], object.nodeId);
  writer.writeString(offsets[2], object.periodKey);
  writer.writeDateTime(offsets[3], object.timestamp);
}

EngineNodeCompletionRecord _engineNodeCompletionRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EngineNodeCompletionRecord();
  object.eventKey = reader.readString(offsets[0]);
  object.id = id;
  object.nodeId = reader.readString(offsets[1]);
  object.periodKey = reader.readStringOrNull(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  return object;
}

P _engineNodeCompletionRecordDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _engineNodeCompletionRecordGetId(EngineNodeCompletionRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _engineNodeCompletionRecordGetLinks(
    EngineNodeCompletionRecord object) {
  return [];
}

void _engineNodeCompletionRecordAttach(
    IsarCollection<dynamic> col, Id id, EngineNodeCompletionRecord object) {
  object.id = id;
}

extension EngineNodeCompletionRecordByIndex
    on IsarCollection<EngineNodeCompletionRecord> {
  Future<EngineNodeCompletionRecord?> getByEventKey(String eventKey) {
    return getByIndex(r'eventKey', [eventKey]);
  }

  EngineNodeCompletionRecord? getByEventKeySync(String eventKey) {
    return getByIndexSync(r'eventKey', [eventKey]);
  }

  Future<bool> deleteByEventKey(String eventKey) {
    return deleteByIndex(r'eventKey', [eventKey]);
  }

  bool deleteByEventKeySync(String eventKey) {
    return deleteByIndexSync(r'eventKey', [eventKey]);
  }

  Future<List<EngineNodeCompletionRecord?>> getAllByEventKey(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventKey', values);
  }

  List<EngineNodeCompletionRecord?> getAllByEventKeySync(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventKey', values);
  }

  Future<int> deleteAllByEventKey(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventKey', values);
  }

  int deleteAllByEventKeySync(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventKey', values);
  }

  Future<Id> putByEventKey(EngineNodeCompletionRecord object) {
    return putByIndex(r'eventKey', object);
  }

  Id putByEventKeySync(EngineNodeCompletionRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'eventKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventKey(List<EngineNodeCompletionRecord> objects) {
    return putAllByIndex(r'eventKey', objects);
  }

  List<Id> putAllByEventKeySync(List<EngineNodeCompletionRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventKey', objects, saveLinks: saveLinks);
  }
}

extension EngineNodeCompletionRecordQueryWhereSort on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QWhere> {
  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension EngineNodeCompletionRecordQueryWhere on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QWhereClause> {
  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
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

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
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

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> eventKeyEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventKey',
        value: [eventKey],
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> eventKeyNotEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> nodeIdEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nodeId',
        value: [nodeId],
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> nodeIdNotEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterWhereClause> timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineNodeCompletionRecordQueryFilter on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QFilterCondition> {
  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
          QAfterFilterCondition>
      eventKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
          QAfterFilterCondition>
      eventKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
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

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
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

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
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

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
          QAfterFilterCondition>
      nodeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
          QAfterFilterCondition>
      nodeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nodeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> nodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
          QAfterFilterCondition>
      periodKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
          QAfterFilterCondition>
      periodKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> periodKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineNodeCompletionRecordQueryObject on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QFilterCondition> {}

extension EngineNodeCompletionRecordQueryLinks on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QFilterCondition> {}

extension EngineNodeCompletionRecordQuerySortBy on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QSortBy> {
  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineNodeCompletionRecordQuerySortThenBy on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QSortThenBy> {
  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineNodeCompletionRecordQueryWhereDistinct on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QDistinct> {
  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QDistinct> distinctByEventKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QDistinct> distinctByNodeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nodeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QDistinct> distinctByPeriodKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, EngineNodeCompletionRecord,
      QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension EngineNodeCompletionRecordQueryProperty on QueryBuilder<
    EngineNodeCompletionRecord, EngineNodeCompletionRecord, QQueryProperty> {
  QueryBuilder<EngineNodeCompletionRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, String, QQueryOperations>
      eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, String, QQueryOperations>
      nodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nodeId');
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, String?, QQueryOperations>
      periodKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKey');
    });
  }

  QueryBuilder<EngineNodeCompletionRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEngineNodeAnnouncementRecordCollection on Isar {
  IsarCollection<EngineNodeAnnouncementRecord>
      get engineNodeAnnouncementRecords => this.collection();
}

const EngineNodeAnnouncementRecordSchema = CollectionSchema(
  name: r'EngineNodeAnnouncementRecord',
  id: 6702663895460222141,
  properties: {
    r'eventKey': PropertySchema(
      id: 0,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'nodeId': PropertySchema(
      id: 1,
      name: r'nodeId',
      type: IsarType.string,
    ),
    r'periodKey': PropertySchema(
      id: 2,
      name: r'periodKey',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _engineNodeAnnouncementRecordEstimateSize,
  serialize: _engineNodeAnnouncementRecordSerialize,
  deserialize: _engineNodeAnnouncementRecordDeserialize,
  deserializeProp: _engineNodeAnnouncementRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey': IndexSchema(
      id: -6167434590247707527,
      name: r'eventKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'nodeId': IndexSchema(
      id: -6491850230428693976,
      name: r'nodeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nodeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _engineNodeAnnouncementRecordGetId,
  getLinks: _engineNodeAnnouncementRecordGetLinks,
  attach: _engineNodeAnnouncementRecordAttach,
  version: '3.1.0+1',
);

int _engineNodeAnnouncementRecordEstimateSize(
  EngineNodeAnnouncementRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.nodeId.length * 3;
  {
    final value = object.periodKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _engineNodeAnnouncementRecordSerialize(
  EngineNodeAnnouncementRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.eventKey);
  writer.writeString(offsets[1], object.nodeId);
  writer.writeString(offsets[2], object.periodKey);
  writer.writeDateTime(offsets[3], object.timestamp);
}

EngineNodeAnnouncementRecord _engineNodeAnnouncementRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EngineNodeAnnouncementRecord();
  object.eventKey = reader.readString(offsets[0]);
  object.id = id;
  object.nodeId = reader.readString(offsets[1]);
  object.periodKey = reader.readStringOrNull(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  return object;
}

P _engineNodeAnnouncementRecordDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _engineNodeAnnouncementRecordGetId(EngineNodeAnnouncementRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _engineNodeAnnouncementRecordGetLinks(
    EngineNodeAnnouncementRecord object) {
  return [];
}

void _engineNodeAnnouncementRecordAttach(
    IsarCollection<dynamic> col, Id id, EngineNodeAnnouncementRecord object) {
  object.id = id;
}

extension EngineNodeAnnouncementRecordByIndex
    on IsarCollection<EngineNodeAnnouncementRecord> {
  Future<EngineNodeAnnouncementRecord?> getByEventKey(String eventKey) {
    return getByIndex(r'eventKey', [eventKey]);
  }

  EngineNodeAnnouncementRecord? getByEventKeySync(String eventKey) {
    return getByIndexSync(r'eventKey', [eventKey]);
  }

  Future<bool> deleteByEventKey(String eventKey) {
    return deleteByIndex(r'eventKey', [eventKey]);
  }

  bool deleteByEventKeySync(String eventKey) {
    return deleteByIndexSync(r'eventKey', [eventKey]);
  }

  Future<List<EngineNodeAnnouncementRecord?>> getAllByEventKey(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventKey', values);
  }

  List<EngineNodeAnnouncementRecord?> getAllByEventKeySync(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventKey', values);
  }

  Future<int> deleteAllByEventKey(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventKey', values);
  }

  int deleteAllByEventKeySync(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventKey', values);
  }

  Future<Id> putByEventKey(EngineNodeAnnouncementRecord object) {
    return putByIndex(r'eventKey', object);
  }

  Id putByEventKeySync(EngineNodeAnnouncementRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'eventKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventKey(
      List<EngineNodeAnnouncementRecord> objects) {
    return putAllByIndex(r'eventKey', objects);
  }

  List<Id> putAllByEventKeySync(List<EngineNodeAnnouncementRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventKey', objects, saveLinks: saveLinks);
  }
}

extension EngineNodeAnnouncementRecordQueryWhereSort on QueryBuilder<
    EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord, QWhere> {
  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension EngineNodeAnnouncementRecordQueryWhere on QueryBuilder<
    EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord, QWhereClause> {
  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
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

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
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

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> eventKeyEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventKey',
        value: [eventKey],
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> eventKeyNotEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> nodeIdEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nodeId',
        value: [nodeId],
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> nodeIdNotEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterWhereClause> timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineNodeAnnouncementRecordQueryFilter on QueryBuilder<
    EngineNodeAnnouncementRecord,
    EngineNodeAnnouncementRecord,
    QFilterCondition> {
  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
          QAfterFilterCondition>
      eventKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
          QAfterFilterCondition>
      eventKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
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

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
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

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
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

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
          QAfterFilterCondition>
      nodeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
          QAfterFilterCondition>
      nodeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nodeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> nodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
          QAfterFilterCondition>
      periodKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
          QAfterFilterCondition>
      periodKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> periodKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineNodeAnnouncementRecordQueryObject on QueryBuilder<
    EngineNodeAnnouncementRecord,
    EngineNodeAnnouncementRecord,
    QFilterCondition> {}

extension EngineNodeAnnouncementRecordQueryLinks on QueryBuilder<
    EngineNodeAnnouncementRecord,
    EngineNodeAnnouncementRecord,
    QFilterCondition> {}

extension EngineNodeAnnouncementRecordQuerySortBy on QueryBuilder<
    EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord, QSortBy> {
  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineNodeAnnouncementRecordQuerySortThenBy on QueryBuilder<
    EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord, QSortThenBy> {
  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineNodeAnnouncementRecordQueryWhereDistinct on QueryBuilder<
    EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord, QDistinct> {
  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QDistinct> distinctByEventKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QDistinct> distinctByNodeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nodeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QDistinct> distinctByPeriodKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, EngineNodeAnnouncementRecord,
      QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension EngineNodeAnnouncementRecordQueryProperty on QueryBuilder<
    EngineNodeAnnouncementRecord,
    EngineNodeAnnouncementRecord,
    QQueryProperty> {
  QueryBuilder<EngineNodeAnnouncementRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, String, QQueryOperations>
      eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, String, QQueryOperations>
      nodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nodeId');
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, String?, QQueryOperations>
      periodKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKey');
    });
  }

  QueryBuilder<EngineNodeAnnouncementRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEngineNodeClaimRecordCollection on Isar {
  IsarCollection<EngineNodeClaimRecord> get engineNodeClaimRecords =>
      this.collection();
}

const EngineNodeClaimRecordSchema = CollectionSchema(
  name: r'EngineNodeClaimRecord',
  id: 6163138345227884940,
  properties: {
    r'eventKey': PropertySchema(
      id: 0,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'nodeId': PropertySchema(
      id: 1,
      name: r'nodeId',
      type: IsarType.string,
    ),
    r'periodKey': PropertySchema(
      id: 2,
      name: r'periodKey',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _engineNodeClaimRecordEstimateSize,
  serialize: _engineNodeClaimRecordSerialize,
  deserialize: _engineNodeClaimRecordDeserialize,
  deserializeProp: _engineNodeClaimRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey': IndexSchema(
      id: -6167434590247707527,
      name: r'eventKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'nodeId': IndexSchema(
      id: -6491850230428693976,
      name: r'nodeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nodeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _engineNodeClaimRecordGetId,
  getLinks: _engineNodeClaimRecordGetLinks,
  attach: _engineNodeClaimRecordAttach,
  version: '3.1.0+1',
);

int _engineNodeClaimRecordEstimateSize(
  EngineNodeClaimRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.nodeId.length * 3;
  {
    final value = object.periodKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _engineNodeClaimRecordSerialize(
  EngineNodeClaimRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.eventKey);
  writer.writeString(offsets[1], object.nodeId);
  writer.writeString(offsets[2], object.periodKey);
  writer.writeDateTime(offsets[3], object.timestamp);
}

EngineNodeClaimRecord _engineNodeClaimRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EngineNodeClaimRecord();
  object.eventKey = reader.readString(offsets[0]);
  object.id = id;
  object.nodeId = reader.readString(offsets[1]);
  object.periodKey = reader.readStringOrNull(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  return object;
}

P _engineNodeClaimRecordDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _engineNodeClaimRecordGetId(EngineNodeClaimRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _engineNodeClaimRecordGetLinks(
    EngineNodeClaimRecord object) {
  return [];
}

void _engineNodeClaimRecordAttach(
    IsarCollection<dynamic> col, Id id, EngineNodeClaimRecord object) {
  object.id = id;
}

extension EngineNodeClaimRecordByIndex
    on IsarCollection<EngineNodeClaimRecord> {
  Future<EngineNodeClaimRecord?> getByEventKey(String eventKey) {
    return getByIndex(r'eventKey', [eventKey]);
  }

  EngineNodeClaimRecord? getByEventKeySync(String eventKey) {
    return getByIndexSync(r'eventKey', [eventKey]);
  }

  Future<bool> deleteByEventKey(String eventKey) {
    return deleteByIndex(r'eventKey', [eventKey]);
  }

  bool deleteByEventKeySync(String eventKey) {
    return deleteByIndexSync(r'eventKey', [eventKey]);
  }

  Future<List<EngineNodeClaimRecord?>> getAllByEventKey(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventKey', values);
  }

  List<EngineNodeClaimRecord?> getAllByEventKeySync(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventKey', values);
  }

  Future<int> deleteAllByEventKey(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventKey', values);
  }

  int deleteAllByEventKeySync(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventKey', values);
  }

  Future<Id> putByEventKey(EngineNodeClaimRecord object) {
    return putByIndex(r'eventKey', object);
  }

  Id putByEventKeySync(EngineNodeClaimRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventKey(List<EngineNodeClaimRecord> objects) {
    return putAllByIndex(r'eventKey', objects);
  }

  List<Id> putAllByEventKeySync(List<EngineNodeClaimRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventKey', objects, saveLinks: saveLinks);
  }
}

extension EngineNodeClaimRecordQueryWhereSort
    on QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QWhere> {
  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhere>
      anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension EngineNodeClaimRecordQueryWhere on QueryBuilder<EngineNodeClaimRecord,
    EngineNodeClaimRecord, QWhereClause> {
  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
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

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
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

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      eventKeyEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventKey',
        value: [eventKey],
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      eventKeyNotEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      nodeIdEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nodeId',
        value: [nodeId],
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      nodeIdNotEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineNodeClaimRecordQueryFilter on QueryBuilder<
    EngineNodeClaimRecord, EngineNodeClaimRecord, QFilterCondition> {
  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
          QAfterFilterCondition>
      eventKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
          QAfterFilterCondition>
      eventKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
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

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
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

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
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

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
          QAfterFilterCondition>
      nodeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
          QAfterFilterCondition>
      nodeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nodeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> nodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
          QAfterFilterCondition>
      periodKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
          QAfterFilterCondition>
      periodKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> periodKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineNodeClaimRecordQueryObject on QueryBuilder<
    EngineNodeClaimRecord, EngineNodeClaimRecord, QFilterCondition> {}

extension EngineNodeClaimRecordQueryLinks on QueryBuilder<EngineNodeClaimRecord,
    EngineNodeClaimRecord, QFilterCondition> {}

extension EngineNodeClaimRecordQuerySortBy
    on QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QSortBy> {
  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineNodeClaimRecordQuerySortThenBy
    on QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QSortThenBy> {
  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineNodeClaimRecordQueryWhereDistinct
    on QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QDistinct> {
  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QDistinct>
      distinctByEventKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QDistinct>
      distinctByNodeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nodeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QDistinct>
      distinctByPeriodKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineNodeClaimRecord, EngineNodeClaimRecord, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension EngineNodeClaimRecordQueryProperty on QueryBuilder<
    EngineNodeClaimRecord, EngineNodeClaimRecord, QQueryProperty> {
  QueryBuilder<EngineNodeClaimRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EngineNodeClaimRecord, String, QQueryOperations>
      eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<EngineNodeClaimRecord, String, QQueryOperations>
      nodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nodeId');
    });
  }

  QueryBuilder<EngineNodeClaimRecord, String?, QQueryOperations>
      periodKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKey');
    });
  }

  QueryBuilder<EngineNodeClaimRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEngineRewardGrantRecordCollection on Isar {
  IsarCollection<EngineRewardGrantRecord> get engineRewardGrantRecords =>
      this.collection();
}

const EngineRewardGrantRecordSchema = CollectionSchema(
  name: r'EngineRewardGrantRecord',
  id: -4820250280849035034,
  properties: {
    r'chapterId': PropertySchema(
      id: 0,
      name: r'chapterId',
      type: IsarType.string,
    ),
    r'companionId': PropertySchema(
      id: 1,
      name: r'companionId',
      type: IsarType.string,
    ),
    r'cosmeticId': PropertySchema(
      id: 2,
      name: r'cosmeticId',
      type: IsarType.string,
    ),
    r'emblemId': PropertySchema(
      id: 3,
      name: r'emblemId',
      type: IsarType.string,
    ),
    r'eventKey': PropertySchema(
      id: 4,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'levelAtGrant': PropertySchema(
      id: 5,
      name: r'levelAtGrant',
      type: IsarType.long,
    ),
    r'multiplierAtGrant': PropertySchema(
      id: 6,
      name: r'multiplierAtGrant',
      type: IsarType.double,
    ),
    r'nodeId': PropertySchema(
      id: 7,
      name: r'nodeId',
      type: IsarType.string,
    ),
    r'periodKey': PropertySchema(
      id: 8,
      name: r'periodKey',
      type: IsarType.string,
    ),
    r'relicId': PropertySchema(
      id: 9,
      name: r'relicId',
      type: IsarType.string,
    ),
    r'rewardKindName': PropertySchema(
      id: 10,
      name: r'rewardKindName',
      type: IsarType.string,
    ),
    r'rewardOrdinal': PropertySchema(
      id: 11,
      name: r'rewardOrdinal',
      type: IsarType.long,
    ),
    r'timestamp': PropertySchema(
      id: 12,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'titleId': PropertySchema(
      id: 13,
      name: r'titleId',
      type: IsarType.string,
    ),
    r'xpAmount': PropertySchema(
      id: 14,
      name: r'xpAmount',
      type: IsarType.long,
    )
  },
  estimateSize: _engineRewardGrantRecordEstimateSize,
  serialize: _engineRewardGrantRecordSerialize,
  deserialize: _engineRewardGrantRecordDeserialize,
  deserializeProp: _engineRewardGrantRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey': IndexSchema(
      id: -6167434590247707527,
      name: r'eventKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'nodeId': IndexSchema(
      id: -6491850230428693976,
      name: r'nodeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nodeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _engineRewardGrantRecordGetId,
  getLinks: _engineRewardGrantRecordGetLinks,
  attach: _engineRewardGrantRecordAttach,
  version: '3.1.0+1',
);

int _engineRewardGrantRecordEstimateSize(
  EngineRewardGrantRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.chapterId;
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
    final value = object.cosmeticId;
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
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.nodeId.length * 3;
  {
    final value = object.periodKey;
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
  bytesCount += 3 + object.rewardKindName.length * 3;
  {
    final value = object.titleId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _engineRewardGrantRecordSerialize(
  EngineRewardGrantRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.chapterId);
  writer.writeString(offsets[1], object.companionId);
  writer.writeString(offsets[2], object.cosmeticId);
  writer.writeString(offsets[3], object.emblemId);
  writer.writeString(offsets[4], object.eventKey);
  writer.writeLong(offsets[5], object.levelAtGrant);
  writer.writeDouble(offsets[6], object.multiplierAtGrant);
  writer.writeString(offsets[7], object.nodeId);
  writer.writeString(offsets[8], object.periodKey);
  writer.writeString(offsets[9], object.relicId);
  writer.writeString(offsets[10], object.rewardKindName);
  writer.writeLong(offsets[11], object.rewardOrdinal);
  writer.writeDateTime(offsets[12], object.timestamp);
  writer.writeString(offsets[13], object.titleId);
  writer.writeLong(offsets[14], object.xpAmount);
}

EngineRewardGrantRecord _engineRewardGrantRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EngineRewardGrantRecord();
  object.chapterId = reader.readStringOrNull(offsets[0]);
  object.companionId = reader.readStringOrNull(offsets[1]);
  object.cosmeticId = reader.readStringOrNull(offsets[2]);
  object.emblemId = reader.readStringOrNull(offsets[3]);
  object.eventKey = reader.readString(offsets[4]);
  object.id = id;
  object.levelAtGrant = reader.readLongOrNull(offsets[5]);
  object.multiplierAtGrant = reader.readDoubleOrNull(offsets[6]);
  object.nodeId = reader.readString(offsets[7]);
  object.periodKey = reader.readStringOrNull(offsets[8]);
  object.relicId = reader.readStringOrNull(offsets[9]);
  object.rewardKindName = reader.readString(offsets[10]);
  object.rewardOrdinal = reader.readLong(offsets[11]);
  object.timestamp = reader.readDateTime(offsets[12]);
  object.titleId = reader.readStringOrNull(offsets[13]);
  object.xpAmount = reader.readLongOrNull(offsets[14]);
  return object;
}

P _engineRewardGrantRecordDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _engineRewardGrantRecordGetId(EngineRewardGrantRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _engineRewardGrantRecordGetLinks(
    EngineRewardGrantRecord object) {
  return [];
}

void _engineRewardGrantRecordAttach(
    IsarCollection<dynamic> col, Id id, EngineRewardGrantRecord object) {
  object.id = id;
}

extension EngineRewardGrantRecordByIndex
    on IsarCollection<EngineRewardGrantRecord> {
  Future<EngineRewardGrantRecord?> getByEventKey(String eventKey) {
    return getByIndex(r'eventKey', [eventKey]);
  }

  EngineRewardGrantRecord? getByEventKeySync(String eventKey) {
    return getByIndexSync(r'eventKey', [eventKey]);
  }

  Future<bool> deleteByEventKey(String eventKey) {
    return deleteByIndex(r'eventKey', [eventKey]);
  }

  bool deleteByEventKeySync(String eventKey) {
    return deleteByIndexSync(r'eventKey', [eventKey]);
  }

  Future<List<EngineRewardGrantRecord?>> getAllByEventKey(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventKey', values);
  }

  List<EngineRewardGrantRecord?> getAllByEventKeySync(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventKey', values);
  }

  Future<int> deleteAllByEventKey(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventKey', values);
  }

  int deleteAllByEventKeySync(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventKey', values);
  }

  Future<Id> putByEventKey(EngineRewardGrantRecord object) {
    return putByIndex(r'eventKey', object);
  }

  Id putByEventKeySync(EngineRewardGrantRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'eventKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventKey(List<EngineRewardGrantRecord> objects) {
    return putAllByIndex(r'eventKey', objects);
  }

  List<Id> putAllByEventKeySync(List<EngineRewardGrantRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventKey', objects, saveLinks: saveLinks);
  }
}

extension EngineRewardGrantRecordQueryWhereSort
    on QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QWhere> {
  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterWhere>
      anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension EngineRewardGrantRecordQueryWhere on QueryBuilder<
    EngineRewardGrantRecord, EngineRewardGrantRecord, QWhereClause> {
  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> eventKeyEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventKey',
        value: [eventKey],
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> eventKeyNotEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> nodeIdEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nodeId',
        value: [nodeId],
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> nodeIdNotEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterWhereClause> timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineRewardGrantRecordQueryFilter on QueryBuilder<
    EngineRewardGrantRecord, EngineRewardGrantRecord, QFilterCondition> {
  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chapterId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chapterId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chapterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chapterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chapterId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chapterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chapterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      chapterIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chapterId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      chapterIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chapterId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapterId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> chapterIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chapterId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> companionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'companionId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> companionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'companionId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> companionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'companionId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> companionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'companionId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cosmeticId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cosmeticId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdEqualTo(
    String? value, {
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdGreaterThan(
    String? value, {
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdLessThan(
    String? value, {
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cosmeticId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> cosmeticIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cosmeticId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> emblemIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emblemId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> emblemIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emblemId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> emblemIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emblemId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> emblemIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emblemId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      eventKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      eventKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> levelAtGrantIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'levelAtGrant',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> levelAtGrantIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'levelAtGrant',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> levelAtGrantEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'levelAtGrant',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> levelAtGrantGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'levelAtGrant',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> levelAtGrantLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'levelAtGrant',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> levelAtGrantBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'levelAtGrant',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> multiplierAtGrantIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'multiplierAtGrant',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> multiplierAtGrantIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'multiplierAtGrant',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> multiplierAtGrantEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'multiplierAtGrant',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> multiplierAtGrantGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'multiplierAtGrant',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> multiplierAtGrantLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'multiplierAtGrant',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> multiplierAtGrantBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'multiplierAtGrant',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      nodeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      nodeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nodeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> nodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'periodKey',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      periodKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      periodKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> periodKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> relicIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'relicId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> relicIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'relicId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
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

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> relicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'relicId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> relicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'relicId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardKindName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rewardKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rewardKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      rewardKindNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rewardKindName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      rewardKindNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rewardKindName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardKindName',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardKindNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rewardKindName',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardOrdinalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardOrdinal',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardOrdinalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardOrdinal',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardOrdinalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardOrdinal',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> rewardOrdinalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardOrdinal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'titleId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'titleId',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'titleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'titleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'titleId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'titleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'titleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      titleIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'titleId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
          QAfterFilterCondition>
      titleIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'titleId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'titleId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> titleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'titleId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> xpAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'xpAmount',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> xpAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'xpAmount',
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> xpAmountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'xpAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> xpAmountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'xpAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> xpAmountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'xpAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord,
      QAfterFilterCondition> xpAmountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'xpAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineRewardGrantRecordQueryObject on QueryBuilder<
    EngineRewardGrantRecord, EngineRewardGrantRecord, QFilterCondition> {}

extension EngineRewardGrantRecordQueryLinks on QueryBuilder<
    EngineRewardGrantRecord, EngineRewardGrantRecord, QFilterCondition> {}

extension EngineRewardGrantRecordQuerySortBy
    on QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QSortBy> {
  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByChapterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByChapterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByCompanionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByCompanionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByCosmeticId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByCosmeticIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByEmblemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByEmblemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByLevelAtGrant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'levelAtGrant', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByLevelAtGrantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'levelAtGrant', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByMultiplierAtGrant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multiplierAtGrant', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByMultiplierAtGrantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multiplierAtGrant', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByRelicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByRelicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByRewardKindName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKindName', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByRewardKindNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKindName', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByRewardOrdinal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardOrdinal', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByRewardOrdinalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardOrdinal', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByTitleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByTitleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByXpAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpAmount', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      sortByXpAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpAmount', Sort.desc);
    });
  }
}

extension EngineRewardGrantRecordQuerySortThenBy on QueryBuilder<
    EngineRewardGrantRecord, EngineRewardGrantRecord, QSortThenBy> {
  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByChapterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByChapterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByCompanionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByCompanionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'companionId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByCosmeticId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByCosmeticIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cosmeticId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByEmblemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByEmblemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emblemId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByLevelAtGrant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'levelAtGrant', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByLevelAtGrantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'levelAtGrant', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByMultiplierAtGrant() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multiplierAtGrant', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByMultiplierAtGrantDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'multiplierAtGrant', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByPeriodKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByPeriodKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodKey', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByRelicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByRelicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'relicId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByRewardKindName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKindName', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByRewardKindNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardKindName', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByRewardOrdinal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardOrdinal', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByRewardOrdinalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardOrdinal', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByTitleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleId', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByTitleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleId', Sort.desc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByXpAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpAmount', Sort.asc);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QAfterSortBy>
      thenByXpAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'xpAmount', Sort.desc);
    });
  }
}

extension EngineRewardGrantRecordQueryWhereDistinct on QueryBuilder<
    EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct> {
  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByChapterId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapterId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByCompanionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'companionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByCosmeticId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cosmeticId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByEmblemId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emblemId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByEventKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByLevelAtGrant() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'levelAtGrant');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByMultiplierAtGrant() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'multiplierAtGrant');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByNodeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nodeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByPeriodKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByRelicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relicId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByRewardKindName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardKindName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByRewardOrdinal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardOrdinal');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByTitleId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'titleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineRewardGrantRecord, EngineRewardGrantRecord, QDistinct>
      distinctByXpAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'xpAmount');
    });
  }
}

extension EngineRewardGrantRecordQueryProperty on QueryBuilder<
    EngineRewardGrantRecord, EngineRewardGrantRecord, QQueryProperty> {
  QueryBuilder<EngineRewardGrantRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String?, QQueryOperations>
      chapterIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapterId');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String?, QQueryOperations>
      companionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'companionId');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String?, QQueryOperations>
      cosmeticIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cosmeticId');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String?, QQueryOperations>
      emblemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emblemId');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String, QQueryOperations>
      eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, int?, QQueryOperations>
      levelAtGrantProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'levelAtGrant');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, double?, QQueryOperations>
      multiplierAtGrantProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'multiplierAtGrant');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String, QQueryOperations>
      nodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nodeId');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String?, QQueryOperations>
      periodKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodKey');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String?, QQueryOperations>
      relicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relicId');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String, QQueryOperations>
      rewardKindNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardKindName');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, int, QQueryOperations>
      rewardOrdinalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardOrdinal');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, String?, QQueryOperations>
      titleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'titleId');
    });
  }

  QueryBuilder<EngineRewardGrantRecord, int?, QQueryOperations>
      xpAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'xpAmount');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEngineQuestOfferingRecordCollection on Isar {
  IsarCollection<EngineQuestOfferingRecord> get engineQuestOfferingRecords =>
      this.collection();
}

const EngineQuestOfferingRecordSchema = CollectionSchema(
  name: r'EngineQuestOfferingRecord',
  id: -1443708876413458834,
  properties: {
    r'dayKey': PropertySchema(
      id: 0,
      name: r'dayKey',
      type: IsarType.string,
    ),
    r'eventKey': PropertySchema(
      id: 1,
      name: r'eventKey',
      type: IsarType.string,
    ),
    r'nodeId': PropertySchema(
      id: 2,
      name: r'nodeId',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _engineQuestOfferingRecordEstimateSize,
  serialize: _engineQuestOfferingRecordSerialize,
  deserialize: _engineQuestOfferingRecordDeserialize,
  deserializeProp: _engineQuestOfferingRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventKey': IndexSchema(
      id: -6167434590247707527,
      name: r'eventKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'nodeId': IndexSchema(
      id: -6491850230428693976,
      name: r'nodeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nodeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'dayKey': IndexSchema(
      id: -3264092797330672150,
      name: r'dayKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dayKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _engineQuestOfferingRecordGetId,
  getLinks: _engineQuestOfferingRecordGetLinks,
  attach: _engineQuestOfferingRecordAttach,
  version: '3.1.0+1',
);

int _engineQuestOfferingRecordEstimateSize(
  EngineQuestOfferingRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dayKey.length * 3;
  bytesCount += 3 + object.eventKey.length * 3;
  bytesCount += 3 + object.nodeId.length * 3;
  return bytesCount;
}

void _engineQuestOfferingRecordSerialize(
  EngineQuestOfferingRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dayKey);
  writer.writeString(offsets[1], object.eventKey);
  writer.writeString(offsets[2], object.nodeId);
  writer.writeDateTime(offsets[3], object.timestamp);
}

EngineQuestOfferingRecord _engineQuestOfferingRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EngineQuestOfferingRecord();
  object.dayKey = reader.readString(offsets[0]);
  object.eventKey = reader.readString(offsets[1]);
  object.id = id;
  object.nodeId = reader.readString(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  return object;
}

P _engineQuestOfferingRecordDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _engineQuestOfferingRecordGetId(EngineQuestOfferingRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _engineQuestOfferingRecordGetLinks(
    EngineQuestOfferingRecord object) {
  return [];
}

void _engineQuestOfferingRecordAttach(
    IsarCollection<dynamic> col, Id id, EngineQuestOfferingRecord object) {
  object.id = id;
}

extension EngineQuestOfferingRecordByIndex
    on IsarCollection<EngineQuestOfferingRecord> {
  Future<EngineQuestOfferingRecord?> getByEventKey(String eventKey) {
    return getByIndex(r'eventKey', [eventKey]);
  }

  EngineQuestOfferingRecord? getByEventKeySync(String eventKey) {
    return getByIndexSync(r'eventKey', [eventKey]);
  }

  Future<bool> deleteByEventKey(String eventKey) {
    return deleteByIndex(r'eventKey', [eventKey]);
  }

  bool deleteByEventKeySync(String eventKey) {
    return deleteByIndexSync(r'eventKey', [eventKey]);
  }

  Future<List<EngineQuestOfferingRecord?>> getAllByEventKey(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventKey', values);
  }

  List<EngineQuestOfferingRecord?> getAllByEventKeySync(
      List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventKey', values);
  }

  Future<int> deleteAllByEventKey(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventKey', values);
  }

  int deleteAllByEventKeySync(List<String> eventKeyValues) {
    final values = eventKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventKey', values);
  }

  Future<Id> putByEventKey(EngineQuestOfferingRecord object) {
    return putByIndex(r'eventKey', object);
  }

  Id putByEventKeySync(EngineQuestOfferingRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'eventKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventKey(List<EngineQuestOfferingRecord> objects) {
    return putAllByIndex(r'eventKey', objects);
  }

  List<Id> putAllByEventKeySync(List<EngineQuestOfferingRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'eventKey', objects, saveLinks: saveLinks);
  }
}

extension EngineQuestOfferingRecordQueryWhereSort on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QWhere> {
  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension EngineQuestOfferingRecordQueryWhere on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QWhereClause> {
  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
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

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
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

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> eventKeyEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'eventKey',
        value: [eventKey],
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> eventKeyNotEqualTo(String eventKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [eventKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'eventKey',
              lower: [],
              upper: [eventKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> nodeIdEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nodeId',
        value: [nodeId],
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> nodeIdNotEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> dayKeyEqualTo(String dayKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dayKey',
        value: [dayKey],
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> dayKeyNotEqualTo(String dayKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [],
              upper: [dayKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [dayKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [dayKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dayKey',
              lower: [],
              upper: [dayKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterWhereClause> timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineQuestOfferingRecordQueryFilter on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QFilterCondition> {
  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
          QAfterFilterCondition>
      dayKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dayKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
          QAfterFilterCondition>
      dayKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dayKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> dayKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dayKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eventKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
          QAfterFilterCondition>
      eventKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eventKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
          QAfterFilterCondition>
      eventKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eventKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> eventKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eventKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
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

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
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

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
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

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
          QAfterFilterCondition>
      nodeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
          QAfterFilterCondition>
      nodeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nodeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> nodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EngineQuestOfferingRecordQueryObject on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QFilterCondition> {}

extension EngineQuestOfferingRecordQueryLinks on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QFilterCondition> {}

extension EngineQuestOfferingRecordQuerySortBy on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QSortBy> {
  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.desc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineQuestOfferingRecordQuerySortThenBy on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QSortThenBy> {
  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByDayKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByDayKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayKey', Sort.desc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByEventKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByEventKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventKey', Sort.desc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord,
      QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension EngineQuestOfferingRecordQueryWhereDistinct on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QDistinct> {
  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord, QDistinct>
      distinctByDayKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord, QDistinct>
      distinctByEventKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord, QDistinct>
      distinctByNodeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nodeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, EngineQuestOfferingRecord, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension EngineQuestOfferingRecordQueryProperty on QueryBuilder<
    EngineQuestOfferingRecord, EngineQuestOfferingRecord, QQueryProperty> {
  QueryBuilder<EngineQuestOfferingRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, String, QQueryOperations>
      dayKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayKey');
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, String, QQueryOperations>
      eventKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventKey');
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, String, QQueryOperations>
      nodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nodeId');
    });
  }

  QueryBuilder<EngineQuestOfferingRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEngineActiveSelectionRecordCollection on Isar {
  IsarCollection<EngineActiveSelectionRecord>
      get engineActiveSelectionRecords => this.collection();
}

const EngineActiveSelectionRecordSchema = CollectionSchema(
  name: r'EngineActiveSelectionRecord',
  id: -5213651450363054517,
  properties: {
    r'assignedAt': PropertySchema(
      id: 0,
      name: r'assignedAt',
      type: IsarType.dateTime,
    ),
    r'expiresAt': PropertySchema(
      id: 1,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'selectedValue': PropertySchema(
      id: 2,
      name: r'selectedValue',
      type: IsarType.string,
    ),
    r'selectionKey': PropertySchema(
      id: 3,
      name: r'selectionKey',
      type: IsarType.string,
    )
  },
  estimateSize: _engineActiveSelectionRecordEstimateSize,
  serialize: _engineActiveSelectionRecordSerialize,
  deserialize: _engineActiveSelectionRecordDeserialize,
  deserializeProp: _engineActiveSelectionRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'selectionKey': IndexSchema(
      id: -151919774423745360,
      name: r'selectionKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'selectionKey',
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
  getId: _engineActiveSelectionRecordGetId,
  getLinks: _engineActiveSelectionRecordGetLinks,
  attach: _engineActiveSelectionRecordAttach,
  version: '3.1.0+1',
);

int _engineActiveSelectionRecordEstimateSize(
  EngineActiveSelectionRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.selectedValue.length * 3;
  bytesCount += 3 + object.selectionKey.length * 3;
  return bytesCount;
}

void _engineActiveSelectionRecordSerialize(
  EngineActiveSelectionRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.assignedAt);
  writer.writeDateTime(offsets[1], object.expiresAt);
  writer.writeString(offsets[2], object.selectedValue);
  writer.writeString(offsets[3], object.selectionKey);
}

EngineActiveSelectionRecord _engineActiveSelectionRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EngineActiveSelectionRecord();
  object.assignedAt = reader.readDateTime(offsets[0]);
  object.expiresAt = reader.readDateTimeOrNull(offsets[1]);
  object.id = id;
  object.selectedValue = reader.readString(offsets[2]);
  object.selectionKey = reader.readString(offsets[3]);
  return object;
}

P _engineActiveSelectionRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _engineActiveSelectionRecordGetId(EngineActiveSelectionRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _engineActiveSelectionRecordGetLinks(
    EngineActiveSelectionRecord object) {
  return [];
}

void _engineActiveSelectionRecordAttach(
    IsarCollection<dynamic> col, Id id, EngineActiveSelectionRecord object) {
  object.id = id;
}

extension EngineActiveSelectionRecordByIndex
    on IsarCollection<EngineActiveSelectionRecord> {
  Future<EngineActiveSelectionRecord?> getBySelectionKey(String selectionKey) {
    return getByIndex(r'selectionKey', [selectionKey]);
  }

  EngineActiveSelectionRecord? getBySelectionKeySync(String selectionKey) {
    return getByIndexSync(r'selectionKey', [selectionKey]);
  }

  Future<bool> deleteBySelectionKey(String selectionKey) {
    return deleteByIndex(r'selectionKey', [selectionKey]);
  }

  bool deleteBySelectionKeySync(String selectionKey) {
    return deleteByIndexSync(r'selectionKey', [selectionKey]);
  }

  Future<List<EngineActiveSelectionRecord?>> getAllBySelectionKey(
      List<String> selectionKeyValues) {
    final values = selectionKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'selectionKey', values);
  }

  List<EngineActiveSelectionRecord?> getAllBySelectionKeySync(
      List<String> selectionKeyValues) {
    final values = selectionKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'selectionKey', values);
  }

  Future<int> deleteAllBySelectionKey(List<String> selectionKeyValues) {
    final values = selectionKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'selectionKey', values);
  }

  int deleteAllBySelectionKeySync(List<String> selectionKeyValues) {
    final values = selectionKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'selectionKey', values);
  }

  Future<Id> putBySelectionKey(EngineActiveSelectionRecord object) {
    return putByIndex(r'selectionKey', object);
  }

  Id putBySelectionKeySync(EngineActiveSelectionRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'selectionKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySelectionKey(
      List<EngineActiveSelectionRecord> objects) {
    return putAllByIndex(r'selectionKey', objects);
  }

  List<Id> putAllBySelectionKeySync(List<EngineActiveSelectionRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'selectionKey', objects, saveLinks: saveLinks);
  }
}

extension EngineActiveSelectionRecordQueryWhereSort on QueryBuilder<
    EngineActiveSelectionRecord, EngineActiveSelectionRecord, QWhere> {
  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhere> anyAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'assignedAt'),
      );
    });
  }
}

extension EngineActiveSelectionRecordQueryWhere on QueryBuilder<
    EngineActiveSelectionRecord, EngineActiveSelectionRecord, QWhereClause> {
  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhereClause> selectionKeyEqualTo(String selectionKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'selectionKey',
        value: [selectionKey],
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhereClause> selectionKeyNotEqualTo(String selectionKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'selectionKey',
              lower: [],
              upper: [selectionKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'selectionKey',
              lower: [selectionKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'selectionKey',
              lower: [selectionKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'selectionKey',
              lower: [],
              upper: [selectionKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterWhereClause> assignedAtEqualTo(DateTime assignedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'assignedAt',
        value: [assignedAt],
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

extension EngineActiveSelectionRecordQueryFilter on QueryBuilder<
    EngineActiveSelectionRecord,
    EngineActiveSelectionRecord,
    QFilterCondition> {
  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> assignedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> expiresAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> expiresAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expiresAt',
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> expiresAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> expiresAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> expiresAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> expiresAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
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

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
          QAfterFilterCondition>
      selectedValueContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedValue',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
          QAfterFilterCondition>
      selectedValueMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedValue',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedValue',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectedValueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedValue',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectionKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
          QAfterFilterCondition>
      selectionKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectionKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
          QAfterFilterCondition>
      selectionKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectionKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectionKey',
        value: '',
      ));
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterFilterCondition> selectionKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectionKey',
        value: '',
      ));
    });
  }
}

extension EngineActiveSelectionRecordQueryObject on QueryBuilder<
    EngineActiveSelectionRecord,
    EngineActiveSelectionRecord,
    QFilterCondition> {}

extension EngineActiveSelectionRecordQueryLinks on QueryBuilder<
    EngineActiveSelectionRecord,
    EngineActiveSelectionRecord,
    QFilterCondition> {}

extension EngineActiveSelectionRecordQuerySortBy on QueryBuilder<
    EngineActiveSelectionRecord, EngineActiveSelectionRecord, QSortBy> {
  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortByAssignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.desc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortBySelectedValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedValue', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortBySelectedValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedValue', Sort.desc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortBySelectionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionKey', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> sortBySelectionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionKey', Sort.desc);
    });
  }
}

extension EngineActiveSelectionRecordQuerySortThenBy on QueryBuilder<
    EngineActiveSelectionRecord, EngineActiveSelectionRecord, QSortThenBy> {
  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenByAssignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.desc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenBySelectedValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedValue', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenBySelectedValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedValue', Sort.desc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenBySelectionKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionKey', Sort.asc);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QAfterSortBy> thenBySelectionKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectionKey', Sort.desc);
    });
  }
}

extension EngineActiveSelectionRecordQueryWhereDistinct on QueryBuilder<
    EngineActiveSelectionRecord, EngineActiveSelectionRecord, QDistinct> {
  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QDistinct> distinctByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedAt');
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QDistinct> distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QDistinct> distinctBySelectedValue({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedValue',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, EngineActiveSelectionRecord,
      QDistinct> distinctBySelectionKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectionKey', caseSensitive: caseSensitive);
    });
  }
}

extension EngineActiveSelectionRecordQueryProperty on QueryBuilder<
    EngineActiveSelectionRecord, EngineActiveSelectionRecord, QQueryProperty> {
  QueryBuilder<EngineActiveSelectionRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, DateTime, QQueryOperations>
      assignedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedAt');
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, DateTime?, QQueryOperations>
      expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, String, QQueryOperations>
      selectedValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedValue');
    });
  }

  QueryBuilder<EngineActiveSelectionRecord, String, QQueryOperations>
      selectionKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectionKey');
    });
  }
}

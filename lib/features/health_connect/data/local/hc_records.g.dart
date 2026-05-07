// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hc_records.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHcStepsDayRecordCollection on Isar {
  IsarCollection<HcStepsDayRecord> get hcStepsDayRecords => this.collection();
}

const HcStepsDayRecordSchema = CollectionSchema(
  name: r'HcStepsDayRecord',
  id: 1503980974178722339,
  properties: {
    r'dateKey': PropertySchema(
      id: 0,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'steps': PropertySchema(
      id: 1,
      name: r'steps',
      type: IsarType.long,
    )
  },
  estimateSize: _hcStepsDayRecordEstimateSize,
  serialize: _hcStepsDayRecordSerialize,
  deserialize: _hcStepsDayRecordDeserialize,
  deserializeProp: _hcStepsDayRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _hcStepsDayRecordGetId,
  getLinks: _hcStepsDayRecordGetLinks,
  attach: _hcStepsDayRecordAttach,
  version: '3.1.0+1',
);

int _hcStepsDayRecordEstimateSize(
  HcStepsDayRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  return bytesCount;
}

void _hcStepsDayRecordSerialize(
  HcStepsDayRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dateKey);
  writer.writeLong(offsets[1], object.steps);
}

HcStepsDayRecord _hcStepsDayRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HcStepsDayRecord();
  object.dateKey = reader.readString(offsets[0]);
  object.id = id;
  object.steps = reader.readLong(offsets[1]);
  return object;
}

P _hcStepsDayRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hcStepsDayRecordGetId(HcStepsDayRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hcStepsDayRecordGetLinks(HcStepsDayRecord object) {
  return [];
}

void _hcStepsDayRecordAttach(
    IsarCollection<dynamic> col, Id id, HcStepsDayRecord object) {
  object.id = id;
}

extension HcStepsDayRecordByIndex on IsarCollection<HcStepsDayRecord> {
  Future<HcStepsDayRecord?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  HcStepsDayRecord? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<HcStepsDayRecord?>> getAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<HcStepsDayRecord?> getAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(HcStepsDayRecord object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(HcStepsDayRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<HcStepsDayRecord> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<HcStepsDayRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension HcStepsDayRecordQueryWhereSort
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QWhere> {
  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HcStepsDayRecordQueryWhere
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QWhereClause> {
  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhereClause>
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

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhereClause>
      dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterWhereClause>
      dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension HcStepsDayRecordQueryFilter
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QFilterCondition> {
  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      stepsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      stepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      stepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterFilterCondition>
      stepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'steps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HcStepsDayRecordQueryObject
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QFilterCondition> {}

extension HcStepsDayRecordQueryLinks
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QFilterCondition> {}

extension HcStepsDayRecordQuerySortBy
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QSortBy> {
  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy>
      sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy>
      sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy> sortBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy>
      sortByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }
}

extension HcStepsDayRecordQuerySortThenBy
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QSortThenBy> {
  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy>
      thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy>
      thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy> thenBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QAfterSortBy>
      thenByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }
}

extension HcStepsDayRecordQueryWhereDistinct
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QDistinct> {
  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QDistinct> distinctByDateKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QDistinct>
      distinctBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'steps');
    });
  }
}

extension HcStepsDayRecordQueryProperty
    on QueryBuilder<HcStepsDayRecord, HcStepsDayRecord, QQueryProperty> {
  QueryBuilder<HcStepsDayRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HcStepsDayRecord, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<HcStepsDayRecord, int, QQueryOperations> stepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'steps');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHcCalorieDayRecordCollection on Isar {
  IsarCollection<HcCalorieDayRecord> get hcCalorieDayRecords =>
      this.collection();
}

const HcCalorieDayRecordSchema = CollectionSchema(
  name: r'HcCalorieDayRecord',
  id: -3003807817574361106,
  properties: {
    r'dateKey': PropertySchema(
      id: 0,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'kcal': PropertySchema(
      id: 1,
      name: r'kcal',
      type: IsarType.double,
    )
  },
  estimateSize: _hcCalorieDayRecordEstimateSize,
  serialize: _hcCalorieDayRecordSerialize,
  deserialize: _hcCalorieDayRecordDeserialize,
  deserializeProp: _hcCalorieDayRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _hcCalorieDayRecordGetId,
  getLinks: _hcCalorieDayRecordGetLinks,
  attach: _hcCalorieDayRecordAttach,
  version: '3.1.0+1',
);

int _hcCalorieDayRecordEstimateSize(
  HcCalorieDayRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  return bytesCount;
}

void _hcCalorieDayRecordSerialize(
  HcCalorieDayRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dateKey);
  writer.writeDouble(offsets[1], object.kcal);
}

HcCalorieDayRecord _hcCalorieDayRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HcCalorieDayRecord();
  object.dateKey = reader.readString(offsets[0]);
  object.id = id;
  object.kcal = reader.readDouble(offsets[1]);
  return object;
}

P _hcCalorieDayRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hcCalorieDayRecordGetId(HcCalorieDayRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hcCalorieDayRecordGetLinks(
    HcCalorieDayRecord object) {
  return [];
}

void _hcCalorieDayRecordAttach(
    IsarCollection<dynamic> col, Id id, HcCalorieDayRecord object) {
  object.id = id;
}

extension HcCalorieDayRecordByIndex on IsarCollection<HcCalorieDayRecord> {
  Future<HcCalorieDayRecord?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  HcCalorieDayRecord? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<HcCalorieDayRecord?>> getAllByDateKey(
      List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<HcCalorieDayRecord?> getAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(HcCalorieDayRecord object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(HcCalorieDayRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<HcCalorieDayRecord> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<HcCalorieDayRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension HcCalorieDayRecordQueryWhereSort
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QWhere> {
  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HcCalorieDayRecordQueryWhere
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QWhereClause> {
  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhereClause>
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

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhereClause>
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

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhereClause>
      dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterWhereClause>
      dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension HcCalorieDayRecordQueryFilter
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QFilterCondition> {
  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      kcalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kcal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      kcalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kcal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      kcalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kcal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterFilterCondition>
      kcalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kcal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension HcCalorieDayRecordQueryObject
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QFilterCondition> {}

extension HcCalorieDayRecordQueryLinks
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QFilterCondition> {}

extension HcCalorieDayRecordQuerySortBy
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QSortBy> {
  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      sortByKcal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kcal', Sort.asc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      sortByKcalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kcal', Sort.desc);
    });
  }
}

extension HcCalorieDayRecordQuerySortThenBy
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QSortThenBy> {
  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      thenByKcal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kcal', Sort.asc);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QAfterSortBy>
      thenByKcalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kcal', Sort.desc);
    });
  }
}

extension HcCalorieDayRecordQueryWhereDistinct
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QDistinct> {
  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QDistinct>
      distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QDistinct>
      distinctByKcal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kcal');
    });
  }
}

extension HcCalorieDayRecordQueryProperty
    on QueryBuilder<HcCalorieDayRecord, HcCalorieDayRecord, QQueryProperty> {
  QueryBuilder<HcCalorieDayRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HcCalorieDayRecord, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<HcCalorieDayRecord, double, QQueryOperations> kcalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kcal');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHcWeightRecordCollection on Isar {
  IsarCollection<HcWeightRecord> get hcWeightRecords => this.collection();
}

const HcWeightRecordSchema = CollectionSchema(
  name: r'HcWeightRecord',
  id: -8805548766354613258,
  properties: {
    r'bodyFat': PropertySchema(
      id: 0,
      name: r'bodyFat',
      type: IsarType.double,
    ),
    r'bodyWater': PropertySchema(
      id: 1,
      name: r'bodyWater',
      type: IsarType.double,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'weight': PropertySchema(
      id: 3,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _hcWeightRecordEstimateSize,
  serialize: _hcWeightRecordSerialize,
  deserialize: _hcWeightRecordDeserialize,
  deserializeProp: _hcWeightRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _hcWeightRecordGetId,
  getLinks: _hcWeightRecordGetLinks,
  attach: _hcWeightRecordAttach,
  version: '3.1.0+1',
);

int _hcWeightRecordEstimateSize(
  HcWeightRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _hcWeightRecordSerialize(
  HcWeightRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.bodyFat);
  writer.writeDouble(offsets[1], object.bodyWater);
  writer.writeDateTime(offsets[2], object.date);
  writer.writeDouble(offsets[3], object.weight);
}

HcWeightRecord _hcWeightRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HcWeightRecord();
  object.bodyFat = reader.readDoubleOrNull(offsets[0]);
  object.bodyWater = reader.readDoubleOrNull(offsets[1]);
  object.date = reader.readDateTime(offsets[2]);
  object.id = id;
  object.weight = reader.readDouble(offsets[3]);
  return object;
}

P _hcWeightRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hcWeightRecordGetId(HcWeightRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hcWeightRecordGetLinks(HcWeightRecord object) {
  return [];
}

void _hcWeightRecordAttach(
    IsarCollection<dynamic> col, Id id, HcWeightRecord object) {
  object.id = id;
}

extension HcWeightRecordQueryWhereSort
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QWhere> {
  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension HcWeightRecordQueryWhere
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QWhereClause> {
  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HcWeightRecordQueryFilter
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QFilterCondition> {
  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyFatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyFat',
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyFatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyFat',
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyFatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyFatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyFatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyFatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyFat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyWaterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyWater',
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyWaterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyWater',
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyWaterEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyWater',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyWaterGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyWater',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyWaterLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyWater',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      bodyWaterBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyWater',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      weightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      weightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      weightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterFilterCondition>
      weightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension HcWeightRecordQueryObject
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QFilterCondition> {}

extension HcWeightRecordQueryLinks
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QFilterCondition> {}

extension HcWeightRecordQuerySortBy
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QSortBy> {
  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> sortByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy>
      sortByBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.desc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> sortByBodyWater() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWater', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy>
      sortByBodyWaterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWater', Sort.desc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy>
      sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension HcWeightRecordQuerySortThenBy
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QSortThenBy> {
  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> thenByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy>
      thenByBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFat', Sort.desc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> thenByBodyWater() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWater', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy>
      thenByBodyWaterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWater', Sort.desc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QAfterSortBy>
      thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension HcWeightRecordQueryWhereDistinct
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QDistinct> {
  QueryBuilder<HcWeightRecord, HcWeightRecord, QDistinct> distinctByBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFat');
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QDistinct>
      distinctByBodyWater() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyWater');
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<HcWeightRecord, HcWeightRecord, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension HcWeightRecordQueryProperty
    on QueryBuilder<HcWeightRecord, HcWeightRecord, QQueryProperty> {
  QueryBuilder<HcWeightRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HcWeightRecord, double?, QQueryOperations> bodyFatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFat');
    });
  }

  QueryBuilder<HcWeightRecord, double?, QQueryOperations> bodyWaterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyWater');
    });
  }

  QueryBuilder<HcWeightRecord, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<HcWeightRecord, double, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHcSleepRecordCollection on Isar {
  IsarCollection<HcSleepRecord> get hcSleepRecords => this.collection();
}

const HcSleepRecordSchema = CollectionSchema(
  name: r'HcSleepRecord',
  id: 7929985905465638414,
  properties: {
    r'awakeDurationSeconds': PropertySchema(
      id: 0,
      name: r'awakeDurationSeconds',
      type: IsarType.long,
    ),
    r'dateKey': PropertySchema(
      id: 1,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'deepDurationSeconds': PropertySchema(
      id: 2,
      name: r'deepDurationSeconds',
      type: IsarType.long,
    ),
    r'lightDurationSeconds': PropertySchema(
      id: 3,
      name: r'lightDurationSeconds',
      type: IsarType.long,
    ),
    r'remDurationSeconds': PropertySchema(
      id: 4,
      name: r'remDurationSeconds',
      type: IsarType.long,
    ),
    r'segmentsEncoded': PropertySchema(
      id: 5,
      name: r'segmentsEncoded',
      type: IsarType.string,
    ),
    r'sleepStart': PropertySchema(
      id: 6,
      name: r'sleepStart',
      type: IsarType.dateTime,
    ),
    r'totalDurationSeconds': PropertySchema(
      id: 7,
      name: r'totalDurationSeconds',
      type: IsarType.long,
    ),
    r'wakeTime': PropertySchema(
      id: 8,
      name: r'wakeTime',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _hcSleepRecordEstimateSize,
  serialize: _hcSleepRecordSerialize,
  deserialize: _hcSleepRecordDeserialize,
  deserializeProp: _hcSleepRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _hcSleepRecordGetId,
  getLinks: _hcSleepRecordGetLinks,
  attach: _hcSleepRecordAttach,
  version: '3.1.0+1',
);

int _hcSleepRecordEstimateSize(
  HcSleepRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.segmentsEncoded.length * 3;
  return bytesCount;
}

void _hcSleepRecordSerialize(
  HcSleepRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.awakeDurationSeconds);
  writer.writeString(offsets[1], object.dateKey);
  writer.writeLong(offsets[2], object.deepDurationSeconds);
  writer.writeLong(offsets[3], object.lightDurationSeconds);
  writer.writeLong(offsets[4], object.remDurationSeconds);
  writer.writeString(offsets[5], object.segmentsEncoded);
  writer.writeDateTime(offsets[6], object.sleepStart);
  writer.writeLong(offsets[7], object.totalDurationSeconds);
  writer.writeDateTime(offsets[8], object.wakeTime);
}

HcSleepRecord _hcSleepRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HcSleepRecord();
  object.awakeDurationSeconds = reader.readLong(offsets[0]);
  object.dateKey = reader.readString(offsets[1]);
  object.deepDurationSeconds = reader.readLong(offsets[2]);
  object.id = id;
  object.lightDurationSeconds = reader.readLong(offsets[3]);
  object.remDurationSeconds = reader.readLong(offsets[4]);
  object.segmentsEncoded = reader.readString(offsets[5]);
  object.sleepStart = reader.readDateTime(offsets[6]);
  object.totalDurationSeconds = reader.readLong(offsets[7]);
  object.wakeTime = reader.readDateTime(offsets[8]);
  return object;
}

P _hcSleepRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hcSleepRecordGetId(HcSleepRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hcSleepRecordGetLinks(HcSleepRecord object) {
  return [];
}

void _hcSleepRecordAttach(
    IsarCollection<dynamic> col, Id id, HcSleepRecord object) {
  object.id = id;
}

extension HcSleepRecordByIndex on IsarCollection<HcSleepRecord> {
  Future<HcSleepRecord?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  HcSleepRecord? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<HcSleepRecord?>> getAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<HcSleepRecord?> getAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(HcSleepRecord object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(HcSleepRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<HcSleepRecord> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<HcSleepRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension HcSleepRecordQueryWhereSort
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QWhere> {
  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HcSleepRecordQueryWhere
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QWhereClause> {
  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhereClause> dateKeyEqualTo(
      String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterWhereClause>
      dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension HcSleepRecordQueryFilter
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QFilterCondition> {
  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      awakeDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'awakeDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      awakeDurationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'awakeDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      awakeDurationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'awakeDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      awakeDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'awakeDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      deepDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deepDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      deepDurationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deepDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      deepDurationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deepDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      deepDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deepDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      lightDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lightDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      lightDurationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lightDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      lightDurationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lightDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      lightDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lightDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      remDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      remDurationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      remDurationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      remDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'segmentsEncoded',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'segmentsEncoded',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'segmentsEncoded',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'segmentsEncoded',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'segmentsEncoded',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'segmentsEncoded',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'segmentsEncoded',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'segmentsEncoded',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'segmentsEncoded',
        value: '',
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      segmentsEncodedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'segmentsEncoded',
        value: '',
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      sleepStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepStart',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      sleepStartGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepStart',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      sleepStartLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepStart',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      sleepStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      totalDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      totalDurationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      totalDurationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      totalDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      wakeTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wakeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      wakeTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wakeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      wakeTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wakeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterFilterCondition>
      wakeTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wakeTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HcSleepRecordQueryObject
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QFilterCondition> {}

extension HcSleepRecordQueryLinks
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QFilterCondition> {}

extension HcSleepRecordQuerySortBy
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QSortBy> {
  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByAwakeDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awakeDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByAwakeDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awakeDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByDeepDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByDeepDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByLightDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lightDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByLightDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lightDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByRemDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByRemDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortBySegmentsEncoded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentsEncoded', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortBySegmentsEncodedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentsEncoded', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> sortBySleepStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepStart', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortBySleepStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepStart', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByTotalDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByTotalDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> sortByWakeTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTime', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      sortByWakeTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTime', Sort.desc);
    });
  }
}

extension HcSleepRecordQuerySortThenBy
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QSortThenBy> {
  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByAwakeDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awakeDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByAwakeDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awakeDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByDeepDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByDeepDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deepDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByLightDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lightDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByLightDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lightDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByRemDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByRemDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenBySegmentsEncoded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentsEncoded', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenBySegmentsEncodedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'segmentsEncoded', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> thenBySleepStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepStart', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenBySleepStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepStart', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByTotalDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByTotalDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy> thenByWakeTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTime', Sort.asc);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QAfterSortBy>
      thenByWakeTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wakeTime', Sort.desc);
    });
  }
}

extension HcSleepRecordQueryWhereDistinct
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct> {
  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct>
      distinctByAwakeDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'awakeDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct> distinctByDateKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct>
      distinctByDeepDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deepDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct>
      distinctByLightDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lightDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct>
      distinctByRemDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct>
      distinctBySegmentsEncoded({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'segmentsEncoded',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct> distinctBySleepStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepStart');
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct>
      distinctByTotalDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, HcSleepRecord, QDistinct> distinctByWakeTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wakeTime');
    });
  }
}

extension HcSleepRecordQueryProperty
    on QueryBuilder<HcSleepRecord, HcSleepRecord, QQueryProperty> {
  QueryBuilder<HcSleepRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HcSleepRecord, int, QQueryOperations>
      awakeDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'awakeDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<HcSleepRecord, int, QQueryOperations>
      deepDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deepDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, int, QQueryOperations>
      lightDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lightDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, int, QQueryOperations>
      remDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, String, QQueryOperations>
      segmentsEncodedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'segmentsEncoded');
    });
  }

  QueryBuilder<HcSleepRecord, DateTime, QQueryOperations> sleepStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepStart');
    });
  }

  QueryBuilder<HcSleepRecord, int, QQueryOperations>
      totalDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDurationSeconds');
    });
  }

  QueryBuilder<HcSleepRecord, DateTime, QQueryOperations> wakeTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wakeTime');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHcActivityRecordCollection on Isar {
  IsarCollection<HcActivityRecord> get hcActivityRecords => this.collection();
}

const HcActivityRecordSchema = CollectionSchema(
  name: r'HcActivityRecord',
  id: -4261883586011966202,
  properties: {
    r'caloriesBurned': PropertySchema(
      id: 0,
      name: r'caloriesBurned',
      type: IsarType.long,
    ),
    r'distanceKm': PropertySchema(
      id: 1,
      name: r'distanceKm',
      type: IsarType.double,
    ),
    r'endTime': PropertySchema(
      id: 2,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'startTime': PropertySchema(
      id: 3,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 4,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _hcActivityRecordEstimateSize,
  serialize: _hcActivityRecordSerialize,
  deserialize: _hcActivityRecordDeserialize,
  deserializeProp: _hcActivityRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'startTime': IndexSchema(
      id: -3870335341264752872,
      name: r'startTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startTime',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _hcActivityRecordGetId,
  getLinks: _hcActivityRecordGetLinks,
  attach: _hcActivityRecordAttach,
  version: '3.1.0+1',
);

int _hcActivityRecordEstimateSize(
  HcActivityRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _hcActivityRecordSerialize(
  HcActivityRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.caloriesBurned);
  writer.writeDouble(offsets[1], object.distanceKm);
  writer.writeDateTime(offsets[2], object.endTime);
  writer.writeDateTime(offsets[3], object.startTime);
  writer.writeString(offsets[4], object.type);
}

HcActivityRecord _hcActivityRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HcActivityRecord();
  object.caloriesBurned = reader.readLongOrNull(offsets[0]);
  object.distanceKm = reader.readDoubleOrNull(offsets[1]);
  object.endTime = reader.readDateTime(offsets[2]);
  object.id = id;
  object.startTime = reader.readDateTime(offsets[3]);
  object.type = reader.readString(offsets[4]);
  return object;
}

P _hcActivityRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hcActivityRecordGetId(HcActivityRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hcActivityRecordGetLinks(HcActivityRecord object) {
  return [];
}

void _hcActivityRecordAttach(
    IsarCollection<dynamic> col, Id id, HcActivityRecord object) {
  object.id = id;
}

extension HcActivityRecordQueryWhereSort
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QWhere> {
  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhere> anyStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startTime'),
      );
    });
  }
}

extension HcActivityRecordQueryWhere
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QWhereClause> {
  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
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

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
      startTimeEqualTo(DateTime startTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startTime',
        value: [startTime],
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
      startTimeNotEqualTo(DateTime startTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
      startTimeGreaterThan(
    DateTime startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [startTime],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
      startTimeLessThan(
    DateTime startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [],
        upper: [startTime],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterWhereClause>
      startTimeBetween(
    DateTime lowerStartTime,
    DateTime upperStartTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [lowerStartTime],
        includeLower: includeLower,
        upper: [upperStartTime],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HcActivityRecordQueryFilter
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QFilterCondition> {
  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      caloriesBurnedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'caloriesBurned',
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      caloriesBurnedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'caloriesBurned',
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      caloriesBurnedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesBurned',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      caloriesBurnedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caloriesBurned',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      caloriesBurnedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caloriesBurned',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      caloriesBurnedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caloriesBurned',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      distanceKmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'distanceKm',
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      distanceKmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'distanceKm',
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      distanceKmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'distanceKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      distanceKmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'distanceKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      distanceKmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'distanceKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      distanceKmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'distanceKm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      endTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      endTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      endTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      endTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      startTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      startTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      startTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      startTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension HcActivityRecordQueryObject
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QFilterCondition> {}

extension HcActivityRecordQueryLinks
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QFilterCondition> {}

extension HcActivityRecordQuerySortBy
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QSortBy> {
  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByCaloriesBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByCaloriesBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByDistanceKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension HcActivityRecordQuerySortThenBy
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QSortThenBy> {
  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByCaloriesBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByCaloriesBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByDistanceKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension HcActivityRecordQueryWhereDistinct
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QDistinct> {
  QueryBuilder<HcActivityRecord, HcActivityRecord, QDistinct>
      distinctByCaloriesBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caloriesBurned');
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QDistinct>
      distinctByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanceKm');
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QDistinct>
      distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QDistinct>
      distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<HcActivityRecord, HcActivityRecord, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension HcActivityRecordQueryProperty
    on QueryBuilder<HcActivityRecord, HcActivityRecord, QQueryProperty> {
  QueryBuilder<HcActivityRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HcActivityRecord, int?, QQueryOperations>
      caloriesBurnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caloriesBurned');
    });
  }

  QueryBuilder<HcActivityRecord, double?, QQueryOperations>
      distanceKmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanceKm');
    });
  }

  QueryBuilder<HcActivityRecord, DateTime, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<HcActivityRecord, DateTime, QQueryOperations>
      startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<HcActivityRecord, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHcMetaRecordCollection on Isar {
  IsarCollection<HcMetaRecord> get hcMetaRecords => this.collection();
}

const HcMetaRecordSchema = CollectionSchema(
  name: r'HcMetaRecord',
  id: 19789516353062519,
  properties: {
    r'lastSyncedAt': PropertySchema(
      id: 0,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'latestBodyFat': PropertySchema(
      id: 1,
      name: r'latestBodyFat',
      type: IsarType.double,
    ),
    r'workoutPermission': PropertySchema(
      id: 2,
      name: r'workoutPermission',
      type: IsarType.bool,
    )
  },
  estimateSize: _hcMetaRecordEstimateSize,
  serialize: _hcMetaRecordSerialize,
  deserialize: _hcMetaRecordDeserialize,
  deserializeProp: _hcMetaRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _hcMetaRecordGetId,
  getLinks: _hcMetaRecordGetLinks,
  attach: _hcMetaRecordAttach,
  version: '3.1.0+1',
);

int _hcMetaRecordEstimateSize(
  HcMetaRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _hcMetaRecordSerialize(
  HcMetaRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.lastSyncedAt);
  writer.writeDouble(offsets[1], object.latestBodyFat);
  writer.writeBool(offsets[2], object.workoutPermission);
}

HcMetaRecord _hcMetaRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HcMetaRecord();
  object.id = id;
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[0]);
  object.latestBodyFat = reader.readDoubleOrNull(offsets[1]);
  object.workoutPermission = reader.readBool(offsets[2]);
  return object;
}

P _hcMetaRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hcMetaRecordGetId(HcMetaRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hcMetaRecordGetLinks(HcMetaRecord object) {
  return [];
}

void _hcMetaRecordAttach(
    IsarCollection<dynamic> col, Id id, HcMetaRecord object) {
  object.id = id;
}

extension HcMetaRecordQueryWhereSort
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QWhere> {
  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HcMetaRecordQueryWhere
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QWhereClause> {
  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterWhereClause> idBetween(
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
}

extension HcMetaRecordQueryFilter
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QFilterCondition> {
  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      lastSyncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      lastSyncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      latestBodyFatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latestBodyFat',
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      latestBodyFatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latestBodyFat',
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      latestBodyFatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latestBodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      latestBodyFatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latestBodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      latestBodyFatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latestBodyFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      latestBodyFatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latestBodyFat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterFilterCondition>
      workoutPermissionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutPermission',
        value: value,
      ));
    });
  }
}

extension HcMetaRecordQueryObject
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QFilterCondition> {}

extension HcMetaRecordQueryLinks
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QFilterCondition> {}

extension HcMetaRecordQuerySortBy
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QSortBy> {
  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy> sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy> sortByLatestBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestBodyFat', Sort.asc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      sortByLatestBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestBodyFat', Sort.desc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      sortByWorkoutPermission() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutPermission', Sort.asc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      sortByWorkoutPermissionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutPermission', Sort.desc);
    });
  }
}

extension HcMetaRecordQuerySortThenBy
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QSortThenBy> {
  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy> thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy> thenByLatestBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestBodyFat', Sort.asc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      thenByLatestBodyFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latestBodyFat', Sort.desc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      thenByWorkoutPermission() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutPermission', Sort.asc);
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QAfterSortBy>
      thenByWorkoutPermissionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutPermission', Sort.desc);
    });
  }
}

extension HcMetaRecordQueryWhereDistinct
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QDistinct> {
  QueryBuilder<HcMetaRecord, HcMetaRecord, QDistinct> distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QDistinct>
      distinctByLatestBodyFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latestBodyFat');
    });
  }

  QueryBuilder<HcMetaRecord, HcMetaRecord, QDistinct>
      distinctByWorkoutPermission() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutPermission');
    });
  }
}

extension HcMetaRecordQueryProperty
    on QueryBuilder<HcMetaRecord, HcMetaRecord, QQueryProperty> {
  QueryBuilder<HcMetaRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HcMetaRecord, DateTime?, QQueryOperations>
      lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<HcMetaRecord, double?, QQueryOperations>
      latestBodyFatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latestBodyFat');
    });
  }

  QueryBuilder<HcMetaRecord, bool, QQueryOperations>
      workoutPermissionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutPermission');
    });
  }
}

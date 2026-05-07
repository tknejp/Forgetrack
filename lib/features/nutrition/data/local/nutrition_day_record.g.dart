// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_day_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNutritionDayRecordCollection on Isar {
  IsarCollection<NutritionDayRecord> get nutritionDayRecords =>
      this.collection();
}

const NutritionDayRecordSchema = CollectionSchema(
  name: r'NutritionDayRecord',
  id: -1327205271083915521,
  properties: {
    r'basal': PropertySchema(
      id: 0,
      name: r'basal',
      type: IsarType.double,
    ),
    r'calories': PropertySchema(
      id: 1,
      name: r'calories',
      type: IsarType.double,
    ),
    r'carbs': PropertySchema(
      id: 2,
      name: r'carbs',
      type: IsarType.double,
    ),
    r'dateKey': PropertySchema(
      id: 3,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'fat': PropertySchema(
      id: 4,
      name: r'fat',
      type: IsarType.double,
    ),
    r'fiber': PropertySchema(
      id: 5,
      name: r'fiber',
      type: IsarType.double,
    ),
    r'foodCount': PropertySchema(
      id: 6,
      name: r'foodCount',
      type: IsarType.long,
    ),
    r'hydration': PropertySchema(
      id: 7,
      name: r'hydration',
      type: IsarType.double,
    ),
    r'inferredComplete': PropertySchema(
      id: 8,
      name: r'inferredComplete',
      type: IsarType.bool,
    ),
    r'mealsJson': PropertySchema(
      id: 9,
      name: r'mealsJson',
      type: IsarType.string,
    ),
    r'protein': PropertySchema(
      id: 10,
      name: r'protein',
      type: IsarType.double,
    ),
    r'salt': PropertySchema(
      id: 11,
      name: r'salt',
      type: IsarType.double,
    ),
    r'saturatedFat': PropertySchema(
      id: 12,
      name: r'saturatedFat',
      type: IsarType.double,
    ),
    r'sugar': PropertySchema(
      id: 13,
      name: r'sugar',
      type: IsarType.double,
    ),
    r'syncedAt': PropertySchema(
      id: 14,
      name: r'syncedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _nutritionDayRecordEstimateSize,
  serialize: _nutritionDayRecordSerialize,
  deserialize: _nutritionDayRecordDeserialize,
  deserializeProp: _nutritionDayRecordDeserializeProp,
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
    ),
    r'syncedAt': IndexSchema(
      id: -9141336850758009100,
      name: r'syncedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _nutritionDayRecordGetId,
  getLinks: _nutritionDayRecordGetLinks,
  attach: _nutritionDayRecordAttach,
  version: '3.1.0+1',
);

int _nutritionDayRecordEstimateSize(
  NutritionDayRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.mealsJson.length * 3;
  return bytesCount;
}

void _nutritionDayRecordSerialize(
  NutritionDayRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.basal);
  writer.writeDouble(offsets[1], object.calories);
  writer.writeDouble(offsets[2], object.carbs);
  writer.writeString(offsets[3], object.dateKey);
  writer.writeDouble(offsets[4], object.fat);
  writer.writeDouble(offsets[5], object.fiber);
  writer.writeLong(offsets[6], object.foodCount);
  writer.writeDouble(offsets[7], object.hydration);
  writer.writeBool(offsets[8], object.inferredComplete);
  writer.writeString(offsets[9], object.mealsJson);
  writer.writeDouble(offsets[10], object.protein);
  writer.writeDouble(offsets[11], object.salt);
  writer.writeDouble(offsets[12], object.saturatedFat);
  writer.writeDouble(offsets[13], object.sugar);
  writer.writeDateTime(offsets[14], object.syncedAt);
}

NutritionDayRecord _nutritionDayRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NutritionDayRecord();
  object.basal = reader.readDouble(offsets[0]);
  object.calories = reader.readDouble(offsets[1]);
  object.carbs = reader.readDouble(offsets[2]);
  object.dateKey = reader.readString(offsets[3]);
  object.fat = reader.readDouble(offsets[4]);
  object.fiber = reader.readDouble(offsets[5]);
  object.foodCount = reader.readLong(offsets[6]);
  object.hydration = reader.readDouble(offsets[7]);
  object.id = id;
  object.inferredComplete = reader.readBool(offsets[8]);
  object.mealsJson = reader.readString(offsets[9]);
  object.protein = reader.readDouble(offsets[10]);
  object.salt = reader.readDouble(offsets[11]);
  object.saturatedFat = reader.readDouble(offsets[12]);
  object.sugar = reader.readDouble(offsets[13]);
  object.syncedAt = reader.readDateTime(offsets[14]);
  return object;
}

P _nutritionDayRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _nutritionDayRecordGetId(NutritionDayRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _nutritionDayRecordGetLinks(
    NutritionDayRecord object) {
  return [];
}

void _nutritionDayRecordAttach(
    IsarCollection<dynamic> col, Id id, NutritionDayRecord object) {
  object.id = id;
}

extension NutritionDayRecordByIndex on IsarCollection<NutritionDayRecord> {
  Future<NutritionDayRecord?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  NutritionDayRecord? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<NutritionDayRecord?>> getAllByDateKey(
      List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<NutritionDayRecord?> getAllByDateKeySync(List<String> dateKeyValues) {
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

  Future<Id> putByDateKey(NutritionDayRecord object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(NutritionDayRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<NutritionDayRecord> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<NutritionDayRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension NutritionDayRecordQueryWhereSort
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QWhere> {
  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhere>
      anySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncedAt'),
      );
    });
  }
}

extension NutritionDayRecordQueryWhere
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QWhereClause> {
  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      syncedAtEqualTo(DateTime syncedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncedAt',
        value: [syncedAt],
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      syncedAtNotEqualTo(DateTime syncedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedAt',
              lower: [],
              upper: [syncedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedAt',
              lower: [syncedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedAt',
              lower: [syncedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncedAt',
              lower: [],
              upper: [syncedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      syncedAtGreaterThan(
    DateTime syncedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncedAt',
        lower: [syncedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      syncedAtLessThan(
    DateTime syncedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncedAt',
        lower: [],
        upper: [syncedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterWhereClause>
      syncedAtBetween(
    DateTime lowerSyncedAt,
    DateTime upperSyncedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncedAt',
        lower: [lowerSyncedAt],
        includeLower: includeLower,
        upper: [upperSyncedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension NutritionDayRecordQueryFilter
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QFilterCondition> {
  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      basalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      basalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'basal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      basalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'basal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      basalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'basal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      caloriesEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      caloriesGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      caloriesLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      caloriesBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      carbsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      carbsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      carbsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      carbsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fiberEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiber',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fiberGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fiber',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fiberLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fiber',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      fiberBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fiber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      foodCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'foodCount',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      foodCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'foodCount',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      foodCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'foodCount',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      foodCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'foodCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      hydrationEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hydration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      hydrationGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hydration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      hydrationLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hydration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      hydrationBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hydration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
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

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      inferredCompleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inferredComplete',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mealsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mealsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mealsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mealsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mealsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mealsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mealsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      mealsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mealsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      proteinEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      proteinGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      proteinLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      proteinBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protein',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saltEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'salt',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saltGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'salt',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saltLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'salt',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saltBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'salt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saturatedFatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saturatedFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saturatedFatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'saturatedFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saturatedFatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'saturatedFat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      saturatedFatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'saturatedFat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      sugarEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sugar',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      sugarGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sugar',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      sugarLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sugar',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      sugarBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sugar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      syncedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      syncedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      syncedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterFilterCondition>
      syncedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension NutritionDayRecordQueryObject
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QFilterCondition> {}

extension NutritionDayRecordQueryLinks
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QFilterCondition> {}

extension NutritionDayRecordQuerySortBy
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QSortBy> {
  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByBasal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basal', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByBasalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basal', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByFiber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByFiberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByFoodCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodCount', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByFoodCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodCount', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByHydration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hydration', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByHydrationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hydration', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByInferredComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredComplete', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByInferredCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredComplete', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByMealsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealsJson', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByMealsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealsJson', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySalt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySaltDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySaturatedFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saturatedFat', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySaturatedFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saturatedFat', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }
}

extension NutritionDayRecordQuerySortThenBy
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QSortThenBy> {
  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByBasal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basal', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByBasalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basal', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByFiber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByFiberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByFoodCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodCount', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByFoodCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodCount', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByHydration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hydration', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByHydrationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hydration', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByInferredComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredComplete', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByInferredCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inferredComplete', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByMealsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealsJson', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByMealsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealsJson', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySalt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySaltDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'salt', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySaturatedFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saturatedFat', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySaturatedFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saturatedFat', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QAfterSortBy>
      thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }
}

extension NutritionDayRecordQueryWhereDistinct
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct> {
  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByBasal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'basal');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calories');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbs');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fat');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByFiber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fiber');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByFoodCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'foodCount');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByHydration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hydration');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByInferredComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inferredComplete');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByMealsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mealsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protein');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctBySalt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'salt');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctBySaturatedFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'saturatedFat');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sugar');
    });
  }

  QueryBuilder<NutritionDayRecord, NutritionDayRecord, QDistinct>
      distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }
}

extension NutritionDayRecordQueryProperty
    on QueryBuilder<NutritionDayRecord, NutritionDayRecord, QQueryProperty> {
  QueryBuilder<NutritionDayRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations> basalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'basal');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations>
      caloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calories');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations> carbsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbs');
    });
  }

  QueryBuilder<NutritionDayRecord, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations> fatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fat');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations> fiberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fiber');
    });
  }

  QueryBuilder<NutritionDayRecord, int, QQueryOperations> foodCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'foodCount');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations>
      hydrationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hydration');
    });
  }

  QueryBuilder<NutritionDayRecord, bool, QQueryOperations>
      inferredCompleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inferredComplete');
    });
  }

  QueryBuilder<NutritionDayRecord, String, QQueryOperations>
      mealsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mealsJson');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations> proteinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protein');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations> saltProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'salt');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations>
      saturatedFatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'saturatedFat');
    });
  }

  QueryBuilder<NutritionDayRecord, double, QQueryOperations> sugarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sugar');
    });
  }

  QueryBuilder<NutritionDayRecord, DateTime, QQueryOperations>
      syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }
}

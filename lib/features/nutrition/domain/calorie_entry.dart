import 'package:intl/intl.dart';

class FoodItem {
  final String name;
  final double kcalPer100g;
  final double? proteinsPer100g;
  final double? carbsPer100g;
  final double? fatsPer100g;

  const FoodItem({
    required this.name,
    required this.kcalPer100g,
    this.proteinsPer100g,
    this.carbsPer100g,
    this.fatsPer100g,
  });

  // Mapování z Open Food Facts JSON
  factory FoodItem.fromOpenFoodFacts(Map<String, dynamic> json) {
    final n = (json['nutriments'] as Map<String, dynamic>?) ?? {};
    return FoodItem(
      name: (json['product_name'] as String?)?.trim().isNotEmpty == true
          ? json['product_name'] as String
          : 'Neznámý produkt',
      kcalPer100g: (n['energy-kcal_100g'] as num?)?.toDouble() ?? 0,
      proteinsPer100g: (n['proteins_100g'] as num?)?.toDouble(),
      carbsPer100g: (n['carbohydrates_100g'] as num?)?.toDouble(),
      fatsPer100g: (n['fat_100g'] as num?)?.toDouble(),
    );
  }
}

enum MealType { snidane, obed, vecere, svacina }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
        MealType.snidane => 'Snídaně',
        MealType.obed => 'Oběd',
        MealType.vecere => 'Večeře',
        MealType.svacina => 'Svačina',
      };
}

class CalorieEntry {
  final String id; // lint-ignore: untyped-id — calorie-entry primary key persisted to KT and storage
  final DateTime date;
  final MealType meal;
  final FoodItem food;
  final double grams;

  CalorieEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.food,
    required this.grams,
  });

  double get kcal => food.kcalPer100g * grams / 100;
  double? get proteins =>
      food.proteinsPer100g != null ? food.proteinsPer100g! * grams / 100 : null;
  double? get carbs =>
      food.carbsPer100g != null ? food.carbsPer100g! * grams / 100 : null;
  double? get fats =>
      food.fatsPer100g != null ? food.fatsPer100g! * grams / 100 : null;

  List<Object?> toSheetRow() => [
        DateFormat('yyyy-MM-dd HH:mm').format(date),
        meal.label,
        food.name,
        grams.round(),
        kcal.round(),
        proteins?.toStringAsFixed(1),
        carbs?.toStringAsFixed(1),
        fats?.toStringAsFixed(1),
      ];
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../domain/calorie_entry.dart';

/// REST client for the kalorické tabulky food database.
///
/// Default implementation uses the free Open Food Facts API.
/// Override [searchFood] / [getProductByBarcode] to swap in a different source.
class CalorieApiService {
  final http.Client _client;

  CalorieApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Searches foods by name.
  Future<List<FoodItem>> searchFood(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('${AppConstants.foodApiBase}/cgi/search.pl').replace(
      queryParameters: {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': AppConstants.foodSearchPageSize.toString(),
        'fields': 'product_name,nutriments',
        'lc': 'cs',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final products = body['products'] as List<dynamic>? ?? [];

    return products
        .cast<Map<String, dynamic>>()
        .map(FoodItem.fromOpenFoodFacts)
        .where((f) => f.kcalPer100g > 0)
        .toList();
  }

  /// Fetches a product by barcode (EAN).
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final uri = Uri.parse(
        '${AppConstants.foodApiBase}/api/v2/product/$barcode.json?fields=product_name,nutriments');

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 1) return null;

    final product = body['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    return FoodItem.fromOpenFoodFacts(product);
  }

  void dispose() => _client.close();
}

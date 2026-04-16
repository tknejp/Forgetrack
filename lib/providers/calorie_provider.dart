import 'package:flutter/foundation.dart';
import '../models/calorie_entry.dart';
import '../services/calorie_api_service.dart';

class CalorieProvider extends ChangeNotifier {
  final CalorieApiService _api;

  CalorieProvider(this._api);

  // Lokální log (v paměti; persistence přes SharedPreferences lze přidat)
  final List<CalorieEntry> _log = [];

  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  List<CalorieEntry> get log => List.unmodifiable(_log);
  List<FoodItem> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  /// Celkové kcal za dnešní den.
  double get todayKcal {
    final today = DateTime.now();
    return _log
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .fold(0.0, (sum, e) => sum + e.kcal);
  }

  /// Záznamy za dnešní den, seřazené od nejnovějšího.
  List<CalorieEntry> get todayLog {
    final today = DateTime.now();
    return _log
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> searchFood(String query) async {
    _isSearching = true;
    _searchError = null;
    _searchResults = [];
    notifyListeners();

    try {
      _searchResults = await _api.searchFood(query);
    } catch (e) {
      _searchError = 'Chyba při hledání: $e';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  void addEntry(CalorieEntry entry) {
    _log.add(entry);
    notifyListeners();
  }

  void removeEntry(String id) {
    _log.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stable identity for each card slot on the home overview.
///
/// Order is user-configurable (long-press + drag). The slot survives
/// state changes — e.g. the `steps` slot renders the HC prompt card
/// when Health Connect isn't connected, and snaps back to the steps
/// data card when the user grants access. Same for `calories` and KT.
enum HomeCardKind {
  steps,
  calories,
  weight,
  activity,
  sleep,
}

/// Persists the user's preferred order of home-overview cards to
/// SharedPreferences and notifies listeners on change.
class HomeCardOrderProvider extends ChangeNotifier {
  static const _kStorageKey = 'home_card_order_v1';

  /// Order shipped with the app; falls back to this when storage is
  /// empty or contains a corrupted value.
  static const List<HomeCardKind> _defaultOrder = [
    HomeCardKind.steps,
    HomeCardKind.calories,
    HomeCardKind.weight,
    HomeCardKind.activity,
    HomeCardKind.sleep,
  ];

  List<HomeCardKind> _order = List<HomeCardKind>.from(_defaultOrder);

  List<HomeCardKind> get order => List.unmodifiable(_order);

  static List<HomeCardKind> get defaultOrder =>
      List.unmodifiable(_defaultOrder);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kStorageKey);
    if (stored == null) return;

    final parsed = <HomeCardKind>[];
    for (final name in stored) {
      final match =
          HomeCardKind.values.where((k) => k.name == name).firstOrNull;
      if (match != null && !parsed.contains(match)) {
        parsed.add(match);
      }
    }

    // Backfill any slots missing from storage (e.g. when a new card is
    // introduced in a later version) so the user doesn't lose access to
    // them after upgrade. Preserve their existing relative order.
    for (final kind in _defaultOrder) {
      if (!parsed.contains(kind)) parsed.add(kind);
    }

    _order = parsed;
    notifyListeners();
  }

  /// Move the card at [oldIndex] to [newIndex]. Caller passes the
  /// "natural" target index (i.e. ReorderableListView's `newIndex - 1`
  /// adjustment for downward moves should already be applied).
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _order.length) return;
    if (newIndex < 0 || newIndex >= _order.length) return;
    if (oldIndex == newIndex) return;

    final updated = List<HomeCardKind>.from(_order);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    _order = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> resetToDefault() async {
    _order = List<HomeCardKind>.from(_defaultOrder);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStorageKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kStorageKey,
      _order.map((k) => k.name).toList(),
    );
  }
}

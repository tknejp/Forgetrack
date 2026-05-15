import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-user mapping of the 11 emblem-collection slots → cosmetic id (or
/// null for an empty slot). Persisted to SharedPreferences keyed by uid
/// so the layout survives sign-out / reinstall on the same device, but
/// stays local to that device — the Firestore profile carries only the
/// single "primary" `equippedCosmetics.emblemId`, which is enough for
/// friends to see the player's currently-pinned emblem.
///
/// Storage shape: a single comma-joined string under
/// `pinned_emblems_$uid`. Empty entries mean "slot empty". Length is
/// always exactly [slotCount] when loaded — shorter / longer stored
/// values are tolerated (truncated or padded with nulls).
///
/// Listeners are notified whenever a pin changes. Mounted UI can rebuild
/// without waiting for the SharedPreferences write to complete because
/// the in-memory list is the source of truth during the session.
class PinnedEmblemsStore extends ChangeNotifier {
  PinnedEmblemsStore({SharedPreferences? prefs}) : _prefs = prefs;

  /// Total slot count, matches the visual 4+4+3 grid in the profile
  /// header. Last slot (index 10) is the "end-game" slot — the store
  /// makes no distinction; it's purely a presentation concern.
  static const int slotCount = 11;
  static const String _kPrefix = 'pinned_emblems_';

  SharedPreferences? _prefs;
  final Map<String, List<String?>> _byUid = <String, List<String?>>{};

  /// Returns a defensive copy of the pin list for [uid]. The list is
  /// always exactly [slotCount] entries long. Use [pinsForUserOrAutoFill]
  /// if you want unset slots auto-filled from a default order.
  List<String?> pinsForUser(String uid) {
    final stored = _byUid[uid];
    if (stored == null) return List<String?>.filled(slotCount, null);
    return List<String?>.from(stored);
  }

  /// Convenience for the first render: if the user has never pinned
  /// anything, fall back to the supplied order (typically the unlock
  /// chronology). Any explicit pins for the user override the fallback,
  /// even if some slots are intentionally empty.
  List<String?> pinsForUserOrAutoFill(
    String uid,
    List<String> autoFillIds,
  ) {
    final explicit = _byUid[uid];
    if (explicit != null) return List<String?>.from(explicit);

    final out = List<String?>.filled(slotCount, null);
    for (var i = 0; i < autoFillIds.length && i < slotCount; i++) {
      out[i] = autoFillIds[i];
    }
    return out;
  }

  /// Loads the cached SharedPreferences instance once and rehydrates
  /// every uid the app has touched. Safe to call multiple times.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_kPrefix)) continue;
      final uid = key.substring(_kPrefix.length);
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      _byUid[uid] = _decode(raw);
    }
  }

  /// Ensures the user's pin list is loaded into memory. Returns the
  /// loaded list (or a freshly-allocated empty one if nothing was
  /// stored). Cheap to call repeatedly — re-reads from cache after the
  /// first hit.
  Future<List<String?>> loadForUser(String uid) async {
    final cached = _byUid[uid];
    if (cached != null) return List<String?>.from(cached);

    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString('$_kPrefix$uid');
    final list = raw == null ? null : _decode(raw);
    if (list != null) {
      _byUid[uid] = list;
      return List<String?>.from(list);
    }
    return List<String?>.filled(slotCount, null);
  }

  /// Sets the pin at [slotIndex] for [uid]. If [cosmeticId] is non-null
  /// and already pinned in another slot, that other slot is cleared
  /// (each emblem can appear in at most one slot). No-op if the slot
  /// index is out of range.
  Future<void> setPin({
    required String uid,
    required int slotIndex,
    required String? cosmeticId,
  }) async {
    if (slotIndex < 0 || slotIndex >= slotCount) return;

    final current = await loadForUser(uid);
    if (cosmeticId != null) {
      // Clear any other slot that already holds this emblem so we don't
      // duplicate. Skips the target slot itself so this is a no-op when
      // the same emblem is reassigned to where it already lives.
      for (var i = 0; i < current.length; i++) {
        if (i != slotIndex && current[i] == cosmeticId) current[i] = null;
      }
    }
    current[slotIndex] = cosmeticId;
    _byUid[uid] = current;

    await _prefs!.setString('$_kPrefix$uid', _encode(current));
    notifyListeners();
  }

  /// Drops every pin for [uid]. Used by sign-out / factory reset.
  Future<void> clearForUser(String uid) async {
    _byUid.remove(uid);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('$_kPrefix$uid');
    notifyListeners();
  }

  static List<String?> _decode(String raw) {
    // Comma-joined, empty entries = empty slot. We pad / truncate to
    // exactly [slotCount] so callers can address every slot by index
    // without a bounds check.
    final parts = raw.split(',');
    final out = List<String?>.filled(slotCount, null);
    for (var i = 0; i < slotCount && i < parts.length; i++) {
      final v = parts[i];
      out[i] = v.isEmpty ? null : v;
    }
    return out;
  }

  static String _encode(List<String?> pins) {
    return pins.map((id) => id ?? '').join(',');
  }
}

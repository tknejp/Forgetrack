import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/emblem_board.dart';

/// State owner for the per-user [EmblemBoard] showcase.
///
/// Phase 12 moved this provider from `lib/features/social/application
/// /pinned_emblems_store.dart` (PinnedEmblemsStore) per proposal §2.4
/// — the 11-slot collection grid is semantically a cosmetic-side
/// concept (a curated subset of unlocked emblems) and only the
/// **worn** emblem ever crosses into social via the Firestore profile
/// mirror. The relocation also fixes a Phase 17 SocialPresence
/// boundary: social/ no longer owns cosmetic-collection state.
///
/// **Persistence wire format.** A single comma-joined string under
/// `pinned_emblems_<uid>` in SharedPreferences. Empty entries mean
/// "slot empty". Length is always exactly [EmblemBoard.slotCount]
/// when loaded — shorter / longer stored values are tolerated
/// (truncated / padded with nulls). The key prefix is preserved from
/// the legacy PinnedEmblemsStore so existing devices roll forward
/// without migration.
///
/// **Notify policy.** Listeners are notified whenever a pin changes.
/// Mounted UI can rebuild without waiting for the SharedPreferences
/// write to complete because the in-memory board is the source of
/// truth during the session.
class EmblemBoardProvider extends ChangeNotifier {
  EmblemBoardProvider({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _kPrefix = 'pinned_emblems_';

  SharedPreferences? _prefs;
  final Map<String, EmblemBoard> _byUid = <String, EmblemBoard>{};

  /// Returns the board for [uid]. Returns [EmblemBoard.empty] when
  /// the user has never pinned anything (or hasn't been loaded yet
  /// — call [loadForUser] first if a fresh disk read matters).
  EmblemBoard boardForUser(String uid) {
    return _byUid[uid] ?? EmblemBoard.empty;
  }

  /// First-render convenience: if the user has never pinned anything,
  /// surface the [autoFillIds] (typically the unlock chronology) as
  /// the default board layout. Explicit pins override the fallback
  /// even when some slots are intentionally null.
  EmblemBoard boardForUserOrAutoFill(String uid, List<String> autoFillIds) {
    final explicit = _byUid[uid];
    if (explicit != null) return explicit;
    return EmblemBoard.empty.autoFillWith(autoFillIds);
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
      _byUid[uid] = EmblemBoard.fromSlots(_decode(raw));
    }
  }

  /// Ensures the user's board is loaded into memory. Returns the
  /// loaded board (or [EmblemBoard.empty] if nothing was stored).
  /// Cheap to call repeatedly — re-reads from cache after the first
  /// hit.
  Future<EmblemBoard> loadForUser(String uid) async {
    final cached = _byUid[uid];
    if (cached != null) return cached;

    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString('$_kPrefix$uid');
    if (raw == null || raw.isEmpty) return EmblemBoard.empty;
    final board = EmblemBoard.fromSlots(_decode(raw));
    _byUid[uid] = board;
    return board;
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
    if (slotIndex < 0 || slotIndex >= EmblemBoard.slotCount) return;

    final current = await loadForUser(uid);
    final next = current.withPin(slotIndex, cosmeticId);
    if (identical(next, current)) return;
    _byUid[uid] = next;

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('$_kPrefix$uid', _encode(next.slots));
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
    final parts = raw.split(',');
    final out = List<String?>.filled(EmblemBoard.slotCount, null);
    for (var i = 0; i < EmblemBoard.slotCount && i < parts.length; i++) {
      final v = parts[i];
      out[i] = v.isEmpty ? null : v;
    }
    return out;
  }

  static String _encode(List<String?> pins) {
    return pins.map((id) => id ?? '').join(',');
  }
}

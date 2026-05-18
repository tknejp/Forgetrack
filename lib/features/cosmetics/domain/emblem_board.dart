import 'package:meta/meta.dart';

/// Immutable per-user mapping of the 11 emblem-collection slots →
/// cosmetic id (or null for an empty slot).
///
/// Phase 12 extracted this VO from `lib/features/social/application
/// /pinned_emblems_store.dart` per proposal §2.4. The "board" is a
/// **public showcase** (collection view rendered on the profile
/// header), distinct from `Loadout.emblemId` which carries the single
/// worn emblem broadcast to friends. The two concepts overlap only
/// in their value type (`String?` cosmetic id) — semantically the
/// loadout is "what I'm wearing now" and the board is "the 11 emblems
/// I want to show off".
///
/// **Persistence policy.** EmblemBoard lives in per-device
/// SharedPreferences (`pinned_emblems_<uid>`) — the layout survives
/// sign-out / reinstall on the same device but stays local. Friends
/// see only the worn emblem from the Firestore profile. The wire
/// shape is a comma-joined string; encoding lives on
/// `EmblemBoardProvider` so the VO surface stays pure (no I/O).
///
/// **Slot count.** 11 slots, rendered as a 4+4+3 grid in the profile
/// header. The last slot (index 10) is the "end-game" slot —
/// presentation concern only; the board treats every index uniformly.
///
/// **Empty sentinel.** `EmblemBoard.empty` is the const default for
/// brand-new users; reads return null for every slot. Consumers can
/// compare with `==` against this sentinel without allocation.
///
/// **Auto-fill semantics.** When the user has never pinned anything,
/// the profile screen typically wants to show unlocked emblems in
/// chronological order. The `EmblemBoardProvider.boardForUserOrAutoFill`
/// surface composes the no-pin case onto an auto-fill list; the VO
/// itself is just the data carrier.
@immutable
class EmblemBoard {
  /// Total slot count. Matches the visual 4+4+3 grid in the profile
  /// header. Last slot is the "end-game" slot — purely a
  /// presentation concern.
  static const int slotCount = 11;

  const EmblemBoard._(this._slots);

  /// All-null sentinel for brand-new users / never-pinned state. Use
  /// for default fields + const init paths.
  static const EmblemBoard empty = EmblemBoard._(
    <String?>[null, null, null, null, null, null, null, null, null, null, null],
  );

  /// Construct from an explicit slot list. Pads / truncates to
  /// exactly [slotCount] so every slot is addressable by index
  /// without a bounds check. Empty / blank ids collapse to null.
  factory EmblemBoard.fromSlots(List<String?> slots) {
    final out = List<String?>.filled(slotCount, null);
    for (var i = 0; i < slotCount && i < slots.length; i++) {
      final v = slots[i];
      out[i] = (v == null || v.isEmpty) ? null : v;
    }
    return EmblemBoard._(List<String?>.unmodifiable(out));
  }

  final List<String?> _slots;

  /// Defensive copy of the slot list. Always length [slotCount].
  List<String?> get slots => List<String?>.from(_slots);

  /// Look up the cosmetic id pinned in [slotIndex]. Returns null when
  /// the slot is empty or the index is out of range.
  String? slotAt(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= slotCount) return null;
    return _slots[slotIndex];
  }

  /// True when every slot is null.
  bool get isEmpty => _slots.every((id) => id == null);

  /// Returns a new board with [slotIndex] set to [cosmeticId]. If
  /// [cosmeticId] is non-null and already pinned in another slot,
  /// that other slot is cleared (each emblem may appear in at most
  /// one slot). No-op when the slot index is out of range.
  EmblemBoard withPin(int slotIndex, String? cosmeticId) {
    if (slotIndex < 0 || slotIndex >= slotCount) return this;
    final next = List<String?>.from(_slots);
    if (cosmeticId != null) {
      for (var i = 0; i < next.length; i++) {
        if (i != slotIndex && next[i] == cosmeticId) next[i] = null;
      }
    }
    next[slotIndex] = cosmeticId;
    return EmblemBoard._(List<String?>.unmodifiable(next));
  }

  /// Auto-fill the board's empty leading slots from [autoFillIds].
  /// Useful for the first-render case where the user has never
  /// pinned anything — the profile screen passes the unlock-order
  /// list and lets the board surface it as a default layout.
  ///
  /// If the board has **any** explicit pin (i.e. is not [empty]),
  /// the auto-fill is suppressed — the user's explicit layout wins
  /// even when individual slots are intentionally null.
  EmblemBoard autoFillWith(List<String> autoFillIds) {
    if (!isEmpty) return this;
    final next = List<String?>.filled(slotCount, null);
    for (var i = 0; i < autoFillIds.length && i < slotCount; i++) {
      next[i] = autoFillIds[i];
    }
    return EmblemBoard._(List<String?>.unmodifiable(next));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EmblemBoard) return false;
    if (other._slots.length != _slots.length) return false;
    for (var i = 0; i < _slots.length; i++) {
      if (other._slots[i] != _slots[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_slots);

  @override
  String toString() => 'EmblemBoard($_slots)';
}

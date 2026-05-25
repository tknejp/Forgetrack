import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/features/cosmetics/application/emblem_board_provider.dart';
import 'package:forgetrack/features/cosmetics/domain/emblem_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EmblemBoard VO', () {
    test('empty sentinel reads null for every slot', () {
      const board = EmblemBoard.empty;
      expect(board.isEmpty, isTrue);
      expect(board.slots.length, EmblemBoard.slotCount);
      for (var i = 0; i < EmblemBoard.slotCount; i++) {
        expect(board.slotAt(i), isNull);
      }
    });

    test('fromSlots pads / truncates / normalises empty strings to null',
        () {
      final board = EmblemBoard.fromSlots([
        'a',
        '',
        'b',
        // truncated: short list should pad to slotCount
      ]);
      expect(board.slots.length, EmblemBoard.slotCount);
      expect(board.slotAt(0), 'a');
      expect(board.slotAt(1), isNull);
      expect(board.slotAt(2), 'b');
      expect(board.slotAt(3), isNull);

      // Too-long lists truncate.
      final long = EmblemBoard.fromSlots(
        List<String?>.generate(20, (i) => 'id_$i'),
      );
      expect(long.slots.length, EmblemBoard.slotCount);
      expect(long.slotAt(EmblemBoard.slotCount - 1), 'id_${EmblemBoard.slotCount - 1}');
    });

    test('withPin assigns a slot + clears duplicates', () {
      const board = EmblemBoard.empty;
      final s0 = board.withPin(0, 'frame_a');
      expect(s0.slotAt(0), 'frame_a');
      // Re-pin same emblem in slot 3 should clear slot 0.
      final s3 = s0.withPin(3, 'frame_a');
      expect(s3.slotAt(0), isNull);
      expect(s3.slotAt(3), 'frame_a');
      // Pin null clears the slot.
      final cleared = s3.withPin(3, null);
      expect(cleared.slotAt(3), isNull);
      expect(cleared.isEmpty, isTrue);
    });

    test('withPin no-ops on out-of-range index', () {
      const board = EmblemBoard.empty;
      expect(board.withPin(-1, 'x'), same(board));
      expect(board.withPin(EmblemBoard.slotCount, 'x'), same(board));
    });

    test('autoFillWith fills leading slots when board is empty', () {
      const board = EmblemBoard.empty;
      final filled = board.autoFillWith(['a', 'b', 'c']);
      expect(filled.slotAt(0), 'a');
      expect(filled.slotAt(1), 'b');
      expect(filled.slotAt(2), 'c');
      expect(filled.slotAt(3), isNull);
    });

    test('autoFillWith is suppressed when board has any explicit pin', () {
      // User explicitly pinned to slot 5 — auto-fill must NOT overwrite
      // the leading nulls because the explicit layout (even with null
      // slots) is the player's intent.
      final pinned = EmblemBoard.empty.withPin(5, 'x');
      final filled = pinned.autoFillWith(['a', 'b', 'c']);
      expect(filled, same(pinned));
      expect(filled.slotAt(0), isNull);
      expect(filled.slotAt(5), 'x');
    });

    test('equality is value-based + hashCode stable', () {
      const a = EmblemBoard.empty;
      final b = EmblemBoard.empty.withPin(0, 'x').withPin(0, null);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EmblemBoardProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('boardForUser returns empty before any pin', () async {
      final provider = EmblemBoardProvider();
      await provider.init();
      expect(provider.boardForUser('uid_a'), EmblemBoard.empty);
    });

    test('setPin persists and rehydrates across provider instances',
        () async {
      final p1 = EmblemBoardProvider();
      await p1.init();
      await p1.setPin(uid: 'uid_a', slotIndex: 0, cosmeticId: CosmeticId('frame_a'));
      await p1.setPin(uid: 'uid_a', slotIndex: 3, cosmeticId: CosmeticId('relic_b'));

      // Fresh provider re-reads SharedPreferences.
      final p2 = EmblemBoardProvider();
      await p2.init();
      final board = await p2.loadForUser('uid_a');
      expect(board.slotAt(0), 'frame_a');
      expect(board.slotAt(3), 'relic_b');
    });

    test('boardForUserOrAutoFill autoFills on first render, then '
        'returns explicit board after a pin', () async {
      final provider = EmblemBoardProvider();
      await provider.init();

      // First render — auto-fill from unlock order.
      final autoFill = provider.boardForUserOrAutoFill(
        'uid_a',
        ['a', 'b', 'c'],
      );
      expect(autoFill.slotAt(0), 'a');
      expect(autoFill.slotAt(1), 'b');

      // After an explicit pin, auto-fill is suppressed for the user.
      await provider.setPin(uid: 'uid_a', slotIndex: 4, cosmeticId: CosmeticId('x'));
      final explicit = provider.boardForUserOrAutoFill(
        'uid_a',
        ['a', 'b', 'c'],
      );
      expect(explicit.slotAt(0), isNull);
      expect(explicit.slotAt(4), 'x');
    });

    test('setPin clears duplicate slots across the same user', () async {
      final provider = EmblemBoardProvider();
      await provider.init();
      await provider.setPin(uid: 'uid_a', slotIndex: 0, cosmeticId: CosmeticId('x'));
      await provider.setPin(uid: 'uid_a', slotIndex: 5, cosmeticId: CosmeticId('x'));
      final board = await provider.loadForUser('uid_a');
      expect(board.slotAt(0), isNull);
      expect(board.slotAt(5), 'x');
    });

    test('clearForUser drops all pins for that uid only', () async {
      final provider = EmblemBoardProvider();
      await provider.init();
      await provider.setPin(uid: 'uid_a', slotIndex: 0, cosmeticId: CosmeticId('a'));
      await provider.setPin(uid: 'uid_b', slotIndex: 0, cosmeticId: CosmeticId('b'));
      await provider.clearForUser('uid_a');

      expect(provider.boardForUser('uid_a'), EmblemBoard.empty);
      final b = await provider.loadForUser('uid_b');
      expect(b.slotAt(0), 'b');
    });

    test('legacy pinned_emblems_<uid> wire format roundtrips through '
        'the new EmblemBoardProvider', () async {
      // Phase 12 invariant: existing devices that wrote the comma-joined
      // string via PinnedEmblemsStore must roll forward without a
      // migration step. Seed the wire format manually + verify the new
      // provider reads it correctly. The 2026-05-25 slot-cap drop
      // (11 → 6) silently truncates extra entries — legacy strings
      // wider than the new cap lose tail pins on read, which is the
      // documented behaviour: no migration, no error.
      SharedPreferences.setMockInitialValues({
        'pinned_emblems_uid_a': 'frame_pilgrim,,relic_x,,emblem_y,emblem_tail',
      });
      final provider = EmblemBoardProvider();
      await provider.init();
      final board = provider.boardForUser('uid_a');
      expect(board.slots.length, EmblemBoard.slotCount);
      expect(board.slotAt(0), 'frame_pilgrim');
      expect(board.slotAt(1), isNull);
      expect(board.slotAt(2), 'relic_x');
      expect(board.slotAt(4), 'emblem_y');
      expect(board.slotAt(5), 'emblem_tail');
    });
  });
}
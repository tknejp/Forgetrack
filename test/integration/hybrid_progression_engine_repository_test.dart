// R.5.c — Hybrid progression engine repository integration tests.
//
// Two scenarios exercise the HybridProgressionEngineRepository against a
// `fake_cloud_firestore` instance and an in-memory local backing — no
// real Firebase emulator, no network. The fake covers the same wire
// codec as production, so the round-trip through
// `FirestoreProgressionEngineGateway._toMap` / `_*FromMap` is genuinely
// exercised:
//
//   * pullAndMerge on a fresh install — fake Firestore is pre-seeded
//     with engine documents for `uid='test-user'`. The first
//     `pullAndMerge` populates the in-memory local; the second is a
//     no-op (idempotency via deterministic eventKeys).
//   * appendEvents push-pull round-trip — bind a uid, append events,
//     allow the unawaited cloud push to flush, then call the gateway
//     directly to verify the events survived encode + decode through
//     real Firestore document shape.
//
// The ADR `r5c-emulator-integration-tests` records the choice to use
// `fake_cloud_firestore` over a real Firebase Emulator harness for this
// first round.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/features/progression_engine/data/firestore_progression_engine_gateway.dart';
import 'package:forgetrack/features/progression_engine/data/hybrid_progression_engine_repository.dart';
import 'package:forgetrack/features/progression_engine/data/in_memory_progression_engine_repository.dart';

const _uid = 'test-user';

NodeCompletionEvent _nodeCompletion(String nodeId, {String period = 'd|2026-05-19'}) {
  return NodeCompletionEvent(
    eventKey: 'node|$nodeId|$period|complete',
    timestamp: DateTime.utc(2026, 5, 19, 12),
    nodeId: nodeId,
    periodKey: period,
  );
}

NodeClaimEvent _nodeClaim(String nodeId, {String period = 'd|2026-05-19'}) {
  return NodeClaimEvent(
    eventKey: 'node|$nodeId|$period|claim',
    timestamp: DateTime.utc(2026, 5, 19, 12, 1),
    nodeId: nodeId,
    periodKey: period,
  );
}

RewardGrantEvent _rewardGrant(String nodeId, int xp) {
  return RewardGrantEvent(
    eventKey: 'reward|$nodeId|0',
    timestamp: DateTime.utc(2026, 5, 19, 12, 2),
    nodeId: nodeId,
    rewardOrdinal: 0,
    rewardKind: RewardGrantKind.xp,
    xpAmount: xp,
  );
}

Future<void> _seedFirestore(
  FakeFirebaseFirestore firestore,
  List<JournalEvent> events,
) async {
  final gateway = FirestoreProgressionEngineGateway(firestore: firestore);
  await gateway.pushEvents(_uid, events);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HybridProgressionEngineRepository.pullAndMerge', () {
    test('cold install pulls seeded events; re-pull is idempotent',
        () async {
      final firestore = FakeFirebaseFirestore();
      final seeded = <JournalEvent>[
        _nodeCompletion('steps_daily'),
        _nodeClaim('steps_daily'),
        _rewardGrant('steps_daily', 50),
      ];
      await _seedFirestore(firestore, seeded);

      final local = InMemoryProgressionEngineRepository();
      final repo = HybridProgressionEngineRepository(
        local: local,
        cloud: FirestoreProgressionEngineGateway(firestore: firestore),
      );

      // Local starts empty.
      final before = await repo.loadLedger();
      expect(before.nodeCompletions, isEmpty);
      expect(before.nodeClaims, isEmpty);
      expect(before.rewardGrants, isEmpty);

      final after = await repo.pullAndMerge(_uid);
      expect(after.nodeCompletions, hasLength(1));
      expect(after.nodeCompletions.single.nodeId, 'steps_daily');
      expect(after.nodeClaims, hasLength(1));
      expect(after.rewardGrants, hasLength(1));
      expect(after.rewardGrants.single.xpAmount, 50);

      // Second pull is a no-op — the in-memory repo dedupes by
      // eventKey, the gateway is idempotent at the data level, and the
      // resulting snapshot has the same counts.
      final second = await repo.pullAndMerge(_uid);
      expect(second.nodeCompletions, hasLength(1));
      expect(second.nodeClaims, hasLength(1));
      expect(second.rewardGrants, hasLength(1));
    });

    test('empty cloud leaves local untouched', () async {
      final firestore = FakeFirebaseFirestore();
      final local = InMemoryProgressionEngineRepository();
      // Seed local with an event the cloud doesn't know about; pull
      // must not drop it.
      await local.appendEvents([_nodeCompletion('weight_weekly')]);

      final repo = HybridProgressionEngineRepository(
        local: local,
        cloud: FirestoreProgressionEngineGateway(firestore: firestore),
      );

      final after = await repo.pullAndMerge(_uid);
      expect(after.nodeCompletions, hasLength(1));
      expect(after.nodeCompletions.single.nodeId, 'weight_weekly');
    });
  });

  group('HybridProgressionEngineRepository.appendEvents', () {
    test('push round-trips through Firestore wire codec', () async {
      final firestore = FakeFirebaseFirestore();
      final local = InMemoryProgressionEngineRepository();
      final gateway = FirestoreProgressionEngineGateway(firestore: firestore);
      final repo = HybridProgressionEngineRepository(
        local: local,
        cloud: gateway,
      )..bindUser(_uid);

      final events = <JournalEvent>[
        _nodeCompletion('cardio_session'),
        _rewardGrant('cardio_session', 120),
      ];
      await repo.appendEvents(events);

      // The push is unawaited inside appendEvents (offline-first design)
      // so flush the microtask queue before inspecting Firestore.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final snapshot = await firestore
          .collection('users')
          .doc(_uid)
          .collection('engineNodeCompletions')
          .get();
      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.single.data()['nodeId'], 'cardio_session');

      // Round-trip back through the gateway — verifies _toMap and
      // _*FromMap stay in sync, which is the production wire codec.
      final pulled = await gateway.pullEvents(_uid);
      expect(pulled.nodeCompletions, hasLength(1));
      expect(pulled.rewardGrants, hasLength(1));
      expect(pulled.rewardGrants.single.xpAmount, 120);
      expect(pulled.rewardGrants.single.rewardKind, RewardGrantKind.xp);
    });
  });
}

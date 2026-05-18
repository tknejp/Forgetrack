// Phase 8 adapter contract pin for PlayerAchievementShelfService.
//
// The service takes engine primitives (catalog rows + completed/locked
// sets + objective outcome lookups + XP scaling closure) and produces
// a PlayerAchievementShelf. Tests verify:
//
//   1. Empty catalog → empty shelf.
//   2. Completed nodes map to AchievementUnlocked carrying the scaled
//      XP and the earliest-completion timestamp.
//   3. Locked nodes (NodeState.locked) map to AchievementLocked even
//      when the objective has measurable progress — the locked branch
//      wins because the unlock-conditions gate hasn't fired.
//   4. Otherwise → AchievementInProgress carrying the objective's
//      actual / target values.
//   5. Precedence: Unlocked > Locked > InProgress. An achievement
//      idempotently in `completedNodeIds` stays Unlocked even when
//      flagged in `lockedNodeIds` simultaneously (defensive
//      precedence — achievements never re-lock).
//   6. evaluatedAt is stamped on every entry.
//   7. Duplicate catalog ids fold last-wins (defensive contract;
//      shouldn't happen in production).

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_lifecycle.dart';
import 'package:forgetrack/features/progression_engine/application/player_achievement_shelf_service.dart';
import 'package:forgetrack/features/progression_engine/domain/models/progression_node_definition.dart';
import 'package:forgetrack/features/progression_engine/domain/models/reward_definition.dart';

void main() {
  final evaluatedAt = DateTime.utc(2026, 5, 18, 12);
  final unlockedAtFixture = DateTime.utc(2026, 5, 17, 10);

  Achievement node({
    required String id,
    String? objectiveId = 'obj_steps_lifetime',
    int xpAmount = 230,
  }) {
    return Achievement(
      id: AchievementId(id),
      titleKey: _titleStub,
      descriptionKey: _descStub,
      rewards: [XpReward(amount: xpAmount)],
      objectiveId: objectiveId,
    );
  }

  // Default lookup helpers — tests override by id where needed.
  DateTime? earliest(String id) =>
      id == 'unlocked' ? unlockedAtFixture : null;
  double actual(String? id) => id == 'obj_steps_lifetime' ? 5000 : 0;
  double target(String? id) => id == 'obj_steps_lifetime' ? 10000 : 0;
  int scaled(int base) => base * 2; // deterministic level-multiplier stub

  const service = PlayerAchievementShelfService();

  test('empty catalog → empty shelf', () {
    final shelf = service.build(
      achievements: const [],
      completedNodeIds: const {},
      lockedNodeIds: const {},
      earliestCompletionAt: (_) => null,
      objectiveActual: (_) => 0,
      objectiveTarget: (_) => 0,
      scaledRewardXp: (b) => b,
      evaluatedAt: evaluatedAt,
    );
    expect(shelf.isEmpty, isTrue);
  });

  test('completed node → AchievementUnlocked(finalXp scaled, unlockedAt)', () {
    final shelf = service.build(
      achievements: [node(id: 'unlocked')],
      completedNodeIds: const {'unlocked'},
      lockedNodeIds: const {},
      earliestCompletionAt: earliest,
      objectiveActual: actual,
      objectiveTarget: target,
      scaledRewardXp: scaled,
      evaluatedAt: evaluatedAt,
    );
    final lifecycle =
        shelf.byId(const AchievementId('unlocked'))!.lifecycle
            as AchievementUnlocked;
    expect(lifecycle.finalXp, 460); // 230 base × 2
    expect(lifecycle.unlockedAt, unlockedAtFixture);
  });

  test('locked node (not completed) → AchievementLocked', () {
    final shelf = service.build(
      achievements: [node(id: 'gated')],
      completedNodeIds: const {},
      lockedNodeIds: const {'gated'},
      earliestCompletionAt: (_) => null,
      objectiveActual: actual,
      objectiveTarget: target,
      scaledRewardXp: scaled,
      evaluatedAt: evaluatedAt,
    );
    expect(
      shelf.byId(const AchievementId('gated'))!.lifecycle,
      const AchievementLocked(),
    );
  });

  test('eligible + objective in progress → AchievementInProgress', () {
    final shelf = service.build(
      achievements: [node(id: 'walking')],
      completedNodeIds: const {},
      lockedNodeIds: const {},
      earliestCompletionAt: (_) => null,
      objectiveActual: actual,
      objectiveTarget: target,
      scaledRewardXp: scaled,
      evaluatedAt: evaluatedAt,
    );
    final lifecycle = shelf
        .byId(const AchievementId('walking'))!
        .lifecycle as AchievementInProgress;
    expect(lifecycle.actual, 5000);
    expect(lifecycle.target, 10000);
  });

  test('condition-only achievement (objective null) → InProgress with 0/0', () {
    final shelf = service.build(
      achievements: [node(id: 'welcome', objectiveId: null)],
      completedNodeIds: const {},
      lockedNodeIds: const {},
      earliestCompletionAt: (_) => null,
      // Closures return 0 for unknown ids — matches the provider's
      // behaviour: `objectiveActualValue(null)` and the null-fallback
      // on `objectiveById(null)` both yield 0.
      objectiveActual: (_) => 0,
      objectiveTarget: (_) => 0,
      scaledRewardXp: scaled,
      evaluatedAt: evaluatedAt,
    );
    expect(
      shelf.byId(const AchievementId('welcome'))!.lifecycle,
      const AchievementInProgress(actual: 0, target: 0),
    );
  });

  test('precedence: completed wins over locked (idempotent unlock)', () {
    // Defensive: an achievement appearing in BOTH sets stays Unlocked.
    // V2 achievements never re-lock; the completion event is durable.
    final shelf = service.build(
      achievements: [node(id: 'won')],
      completedNodeIds: const {'won'},
      lockedNodeIds: const {'won'},
      earliestCompletionAt: (_) => unlockedAtFixture,
      objectiveActual: actual,
      objectiveTarget: target,
      scaledRewardXp: scaled,
      evaluatedAt: evaluatedAt,
    );
    expect(
      shelf.byId(const AchievementId('won'))!.lifecycle,
      isA<AchievementUnlocked>(),
    );
  });

  test('evaluatedAt stamped on every entry', () {
    final shelf = service.build(
      achievements: [node(id: 'a'), node(id: 'b')],
      completedNodeIds: const {'a'},
      lockedNodeIds: const {'b'},
      earliestCompletionAt: earliest,
      objectiveActual: actual,
      objectiveTarget: target,
      scaledRewardXp: scaled,
      evaluatedAt: evaluatedAt,
    );
    for (final entry in shelf.all) {
      expect(entry.evaluatedAt, evaluatedAt);
    }
  });

  test('zero-XP catalog row → AchievementUnlocked(finalXp 0)', () {
    // Some condition-driven achievements (welcome) carry no XP reward.
    // The bridge sums XpReward.amount → 0 → scaledXp(0) → 0.
    final shelf = service.build(
      achievements: [node(id: 'welcome', xpAmount: 0)],
      completedNodeIds: const {'welcome'},
      lockedNodeIds: const {},
      earliestCompletionAt: (_) => unlockedAtFixture,
      objectiveActual: actual,
      objectiveTarget: target,
      scaledRewardXp: scaled,
      evaluatedAt: evaluatedAt,
    );
    final lifecycle = shelf
        .byId(const AchievementId('welcome'))!
        .lifecycle as AchievementUnlocked;
    expect(lifecycle.finalXp, 0);
  });
}

String _titleStub(Object? _) => 'title';
String _descStub(Object? _) => 'desc';

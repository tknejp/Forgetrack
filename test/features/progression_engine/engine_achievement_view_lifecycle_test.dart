// Phase 8 view-model bridge pin: EngineAchievementView.lifecycle
// precedence table.
//
// The bridge getter routes the view's flags (unlocked,
// isLockedByConditions) to the sealed PlayerAchievementLifecycle.
// Precedence: Unlocked > Locked > InProgress. Different from Phase 6
// quests where Locked > Claimed (a side-quest of a closed chapter
// must stay locked even after the player finished it) — achievements
// never re-lock, so once the completion event is in the ledger the
// row idempotently stays Unlocked.
//
// All 4 boolean combinations of (unlocked, isLockedByConditions) are
// covered. Any precedence flip in a future refactor fails this test
// before it reaches the hero / journey consumers.

import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/player/player_achievement_lifecycle.dart';
import 'package:forgetrack/features/progression_engine/application/adapters/engine_achievement_view.dart';
import 'package:forgetrack/features/progression_engine/domain/display/progression_display_models.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:flutter/material.dart' show Colors;

void main() {
  EngineAchievementView view({
    bool unlocked = false,
    bool isLockedByConditions = false,
    int currentValue = 3000,
    int targetValue = 10000,
    int previewXp = 230,
    DateTime? unlockedAt,
  }) {
    return EngineAchievementView(
      node: Achievement(
        id: const AchievementId('a'),
        titleKey: _titleStub,
        descriptionKey: _descStub,
        rewards: const [XpReward(amount: 115)],
        objectiveId: ObjectiveId('obj'),
      ),
      display: NodeDisplay(
        nodeId: ProgressionEntryId('a'),
        kind: NodeDisplayKind.achievement,
        title: _titleStub,
        description: _descStub,
        accentColor: Colors.amber,
        rarity: Rarity.common,
      ),
      unlocked: unlocked,
      unlockedAt: unlockedAt,
      currentValue: currentValue,
      targetValue: targetValue,
      progress: targetValue == 0
          ? (unlocked ? 1.0 : 0.0)
          : (currentValue / targetValue).clamp(0.0, 1.0).toDouble(),
      levelTarget: null,
      isLockedByConditions: isLockedByConditions,
      previewXp: previewXp,
    );
  }

  test('(unlocked=F, locked=F) → AchievementInProgress with actual/target', () {
    final lc = view().lifecycle;
    expect(lc, isA<AchievementInProgress>());
    final progress = lc as AchievementInProgress;
    expect(progress.actual, 3000);
    expect(progress.target, 10000);
  });

  test('(unlocked=F, locked=T) → AchievementLocked', () {
    final lc = view(isLockedByConditions: true).lifecycle;
    expect(lc, const AchievementLocked());
  });

  test('(unlocked=T, locked=F) → AchievementUnlocked(previewXp, unlockedAt)',
      () {
    final at = DateTime.utc(2026, 5, 18, 10);
    final lc =
        view(unlocked: true, unlockedAt: at).lifecycle as AchievementUnlocked;
    expect(lc.finalXp, 230); // previewXp default in helper
    expect(lc.unlockedAt, at);
  });

  test('(unlocked=T, locked=T) → AchievementUnlocked wins (never re-locks)',
      () {
    // Defensive precedence: even if the engine resolver and the
    // completed set disagree, an unlocked achievement stays Unlocked.
    // Mirrors the achievement-shelf service contract.
    final lc = view(unlocked: true, isLockedByConditions: true).lifecycle;
    expect(lc, isA<AchievementUnlocked>());
  });
}

String _titleStub(Object? _) => 'title';
String _descStub(Object? _) => 'desc';

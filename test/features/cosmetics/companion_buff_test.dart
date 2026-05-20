import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/companion_buff.dart';

void main() {
  group('FlatCompanionBuff', () {
    test('returns its constant percent when source matches', () {
      const buff = FlatCompanionBuff(
        kind: RewardSourceKind.activityXp,
        percent: 8,
      );
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.activityXp,
          ),
        ),
        8,
      );
    });

    test('returns 0 when the source kind does not match', () {
      const buff = FlatCompanionBuff(
        kind: RewardSourceKind.nutritionXp,
        percent: 10,
      );
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.activityXp,
          ),
        ),
        0,
      );
    });

    test('allXp variant matches every source kind', () {
      const buff = FlatCompanionBuff(
        kind: RewardSourceKind.allXp,
        percent: 15,
      );
      for (final kind in RewardSourceKind.values) {
        expect(
          buff.resolvePercent(CompanionBuffContext(rewardSourceKind: kind)),
          15,
          reason: 'allXp should match $kind',
        );
      }
    });
  });

  group('StreakLengthCompanionBuff (Ember Sprite)', () {
    const buff = StreakLengthCompanionBuff();

    test('returns 0 when the reward has no streakDomain', () {
      // Quest / combo / chapter rewards carry streakDomain == null
      // and must therefore never pick up an Ember bonus.
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.questXp,
            // No streakDomain.
            currentStreak: 100,
          ),
        ),
        0,
      );
    });

    test('tier 0 covers fresh and 1-day streaks', () {
      for (final s in [0, 1]) {
        expect(
          buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.activityXp,
              streakDomain: ProgressionDomain.steps,
              currentStreak: s,
            ),
          ),
          CompanionBuffPercents.emberTier0,
          reason: 'streak=$s should be tier 0 (no bonus)',
        );
      }
    });

    test('boundary days land in the documented tier', () {
      int forStreak(int s) => buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.activityXp,
              streakDomain: ProgressionDomain.steps,
              currentStreak: s,
            ),
          );
      expect(forStreak(2), CompanionBuffPercents.emberTier1);
      expect(forStreak(6), CompanionBuffPercents.emberTier1);
      expect(forStreak(7), CompanionBuffPercents.emberTier2);
      expect(forStreak(13), CompanionBuffPercents.emberTier2);
      expect(forStreak(14), CompanionBuffPercents.emberTier3);
      expect(forStreak(20), CompanionBuffPercents.emberTier3);
      expect(forStreak(21), CompanionBuffPercents.emberTier4);
      expect(forStreak(99), CompanionBuffPercents.emberTier4);
    });

    test('100+ day streak hits the silent legendary tier', () {
      // The 100-day tier is intentionally absent from player-facing
      // copy. The buff still pays out so the milestone is real.
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.activityXp,
            streakDomain: ProgressionDomain.steps,
            currentStreak: 100,
          ),
        ),
        CompanionBuffPercents.emberLegendary,
      );
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.activityXp,
            streakDomain: ProgressionDomain.steps,
            currentStreak: 365,
          ),
        ),
        CompanionBuffPercents.emberLegendary,
      );
    });
  });

  group('StreakThresholdFlatCompanionBuff (Lantern Golem)', () {
    const buff = StreakThresholdFlatCompanionBuff(
      percent: CompanionBuffPercents.lanternGolemPercent,
      minStreak: CompanionBuffPercents.lanternGolemThreshold,
    );

    test('returns 0 when the reward has no streakDomain', () {
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.nutritionXp,
            currentStreak: 50,
          ),
        ),
        0,
      );
    });

    test('returns 0 below the activation threshold', () {
      for (final s in [0, 1, 6]) {
        expect(
          buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.nutritionXp,
              streakDomain: ProgressionDomain.nutrition,
              currentStreak: s,
            ),
          ),
          0,
          reason: 'streak=$s sits below the 7-day activation threshold',
        );
      }
    });

    test('returns the flat percent at and above the threshold', () {
      for (final s in [7, 14, 50, 99]) {
        expect(
          buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.nutritionXp,
              streakDomain: ProgressionDomain.nutrition,
              currentStreak: s,
            ),
          ),
          CompanionBuffPercents.lanternGolemPercent,
          reason: 'streak=$s should pay out the rare-tier flat',
        );
      }
    });

    test('100+ day streak hits the silent legendary tier', () {
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.nutritionXp,
            streakDomain: ProgressionDomain.nutrition,
            currentStreak: 100,
          ),
        ),
        CompanionBuffPercents.lanternLegendary,
      );
    });
  });

  group('WeeklyEmphasisCompanionBuff (Ruin Raven)', () {
    const buff = WeeklyEmphasisCompanionBuff();

    test('returns 0 when the source kind is not questXp', () {
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.nutritionXp,
          ),
        ),
        0,
      );
    });

    test('returns dampened daily / amplified weekly per source flag', () {
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.questXp,
          ),
        ),
        CompanionBuffPercents.ravenDaily,
      );
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.questXp,
            isWeeklyQuestSource: true,
          ),
        ),
        CompanionBuffPercents.ravenWeekly,
      );
    });
  });

  group('ChapterDepthCompanionBuff (Cave Lynx)', () {
    const buff = ChapterDepthCompanionBuff();

    test('returns 0 when the source kind is not chapterXp', () {
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.activityXp,
            chapterChainPosition: 4,
          ),
        ),
        0,
      );
    });

    test('returns opener / mid / deep tiers per chain position', () {
      int forPos(int? p) => buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.chapterXp,
              chapterChainPosition: p,
            ),
          );
      // Null position falls back to opener tier.
      expect(forPos(null), CompanionBuffPercents.lynxOpener);
      // 0–1 → opener.
      expect(forPos(0), CompanionBuffPercents.lynxOpener);
      expect(forPos(1), CompanionBuffPercents.lynxOpener);
      // 2–3 → mid.
      expect(forPos(2), CompanionBuffPercents.lynxMid);
      expect(forPos(3), CompanionBuffPercents.lynxMid);
      // 4+ → deep.
      expect(forPos(4), CompanionBuffPercents.lynxDeep);
      expect(forPos(7), CompanionBuffPercents.lynxDeep);
    });
  });
}

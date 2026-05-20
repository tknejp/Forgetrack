import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/companion_buff.dart';

void main() {
  group('FlatCompanionBuff', () {
    test('returns its constant percent regardless of context', () {
      const buff = FlatCompanionBuff(
        kind: RewardSourceKind.activityXp,
        percent: 8,
      );
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.activityXp,
            currentStreak: 0,
          ),
        ),
        8,
      );
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.activityXp,
            currentStreak: 50,
            chapterChainPosition: 10,
          ),
        ),
        8,
      );
    });
  });

  group('StreakLengthCompanionBuff (Ember Sprite)', () {
    const buff = StreakLengthCompanionBuff();

    test('targets streakXp', () {
      expect(buff.kind, RewardSourceKind.streakXp);
    });

    test('returns floor on fresh / short streaks (≤ 3 days)', () {
      for (final s in [0, 1, 2, 3]) {
        expect(
          buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.streakXp,
              currentStreak: s,
            ),
          ),
          CompanionBuffPercents.emberFloor,
          reason: 'streak=$s should hit floor',
        );
      }
    });

    test('returns short / medium / long tiers at boundaries', () {
      int forStreak(int s) => buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.streakXp,
              currentStreak: s,
            ),
          );
      expect(forStreak(4), CompanionBuffPercents.emberShort);
      expect(forStreak(7), CompanionBuffPercents.emberShort);
      expect(forStreak(8), CompanionBuffPercents.emberMedium);
      expect(forStreak(14), CompanionBuffPercents.emberMedium);
      expect(forStreak(15), CompanionBuffPercents.emberLong);
      expect(forStreak(100), CompanionBuffPercents.emberLong);
    });
  });

  group('WeeklyEmphasisCompanionBuff (Ruin Raven)', () {
    const buff = WeeklyEmphasisCompanionBuff();

    test('targets questXp', () {
      expect(buff.kind, RewardSourceKind.questXp);
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

    test('targets chapterXp', () {
      expect(buff.kind, RewardSourceKind.chapterXp);
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

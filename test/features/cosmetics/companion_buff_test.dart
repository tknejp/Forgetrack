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
          3,
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
      expect(forStreak(4), 6);
      expect(forStreak(7), 6);
      expect(forStreak(8), 9);
      expect(forStreak(14), 9);
      expect(forStreak(15), 12);
      expect(forStreak(100), 12);
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
        5,
      );
      expect(
        buff.resolvePercent(
          const CompanionBuffContext(
            rewardSourceKind: RewardSourceKind.questXp,
            isWeeklyQuestSource: true,
          ),
        ),
        30,
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
      expect(forPos(null), 25);
      // 0–1 → opener.
      expect(forPos(0), 25);
      expect(forPos(1), 25);
      // 2–3 → mid.
      expect(forPos(2), 40);
      expect(forPos(3), 40);
      // 4+ → deep.
      expect(forPos(4), 65);
      expect(forPos(7), 65);
    });
  });
}

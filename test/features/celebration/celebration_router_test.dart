import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/celebration/domain/models/celebration_event.dart';
import 'package:forgetrack/shared/domain/rarity.dart';
import 'package:forgetrack/features/celebration/domain/models/celebration_reward.dart';
import 'package:forgetrack/features/celebration/domain/services/celebration_router.dart';

CelebrationReward _reward(
  Rarity rarity, {
  CelebrationRewardKind kind = CelebrationRewardKind.xp,
}) =>
    CelebrationReward(
      id: 'r-${rarity.name}-${kind.name}',
      name: (_) => rarity.name,
      rarity: rarity,
      kind: kind,
    );

CelebrationEvent _event({
  required List<CelebrationReward> rewards,
  required Rarity headRarity,
  CelebrationVariant? variantOverride,
}) =>
    CelebrationEvent(
      id: 'test',
      type: CelebrationType.achievement,
      eyebrow: (_) => '',
      title: (_) => '',
      rewards: rewards,
      headRarity: headRarity,
      variantOverride: variantOverride,
    );

void main() {
  const router = CelebrationRouter();

  group('CelebrationRouter', () {
    test('topsheet for single common reward', () {
      final event = _event(
        rewards: [_reward(Rarity.common)],
        headRarity: Rarity.common,
      );
      expect(router.resolve(event), CelebrationVariant.topsheet);
    });

    test('topsheet for single uncommon reward', () {
      final event = _event(
        rewards: [_reward(Rarity.uncommon)],
        headRarity: Rarity.uncommon,
      );
      expect(router.resolve(event), CelebrationVariant.topsheet);
    });

    test('topsheet for single epic reward (under legendary threshold)', () {
      final event = _event(
        rewards: [_reward(Rarity.epic)],
        headRarity: Rarity.epic,
      );
      expect(router.resolve(event), CelebrationVariant.topsheet);
    });

    test('fullscreen for single legendary reward', () {
      final event = _event(
        rewards: [_reward(Rarity.legendary)],
        headRarity: Rarity.legendary,
      );
      expect(router.resolve(event), CelebrationVariant.fullscreen);
    });

    test('fullscreen for single mythic reward', () {
      final event = _event(
        rewards: [_reward(Rarity.mythic)],
        headRarity: Rarity.mythic,
      );
      expect(router.resolve(event), CelebrationVariant.fullscreen);
    });

    test('fullscreen when any reward is a frame', () {
      final event = _event(
        rewards: [
          _reward(Rarity.common,
              kind: CelebrationRewardKind.frame),
        ],
        headRarity: Rarity.common,
      );
      expect(router.resolve(event), CelebrationVariant.fullscreen);
    });

    test('fullscreen when any reward is a title', () {
      final event = _event(
        rewards: [
          _reward(Rarity.uncommon,
              kind: CelebrationRewardKind.title),
        ],
        headRarity: Rarity.uncommon,
      );
      expect(router.resolve(event), CelebrationVariant.fullscreen);
    });

    test('topsheet for XP-only rewards regardless of count', () {
      final event = _event(
        rewards: [
          _reward(Rarity.uncommon),
          _reward(Rarity.uncommon),
        ],
        headRarity: Rarity.uncommon,
      );
      expect(router.resolve(event), CelebrationVariant.topsheet);
    });

    test('topsheet for empty rewards under legendary head', () {
      final event = _event(
        rewards: const [],
        headRarity: Rarity.rare,
      );
      expect(router.resolve(event), CelebrationVariant.topsheet);
    });

    test('override beats auto rule (force topsheet for legendary)', () {
      final event = _event(
        rewards: [_reward(Rarity.legendary)],
        headRarity: Rarity.legendary,
        variantOverride: CelebrationVariant.topsheet,
      );
      expect(router.resolve(event), CelebrationVariant.topsheet);
    });

    test('override beats auto rule (force fullscreen for single common)', () {
      final event = _event(
        rewards: [_reward(Rarity.common)],
        headRarity: Rarity.common,
        variantOverride: CelebrationVariant.fullscreen,
      );
      expect(router.resolve(event), CelebrationVariant.fullscreen);
    });
  });

  group('CelebrationEvent.maxRarityFrom', () {
    test('returns common for empty list', () {
      expect(
        CelebrationEvent.maxRarityFrom(const []),
        Rarity.common,
      );
    });

    test('returns max rarity from mixed list', () {
      final result = CelebrationEvent.maxRarityFrom([
        _reward(Rarity.common),
        _reward(Rarity.legendary),
        _reward(Rarity.epic),
      ]);
      expect(result, Rarity.legendary);
    });
  });
}

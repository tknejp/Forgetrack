import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/social/domain/profile_stat_catalog.dart';

void main() {
  group('profileStatCatalog', () {
    test('every key resolves through profileStatDescriptorByKey', () {
      for (final descriptor in profileStatCatalog) {
        expect(
          profileStatDescriptorByKey(descriptor.key),
          same(descriptor),
          reason: 'lookup failed for ${descriptor.key}',
        );
      }
    });

    test('unknown key resolves to null', () {
      expect(profileStatDescriptorByKey('does.not.exist'), isNull);
    });

    test('keys are unique', () {
      final seen = <String>{};
      for (final descriptor in profileStatCatalog) {
        expect(
          seen.add(descriptor.key),
          isTrue,
          reason: 'duplicate key ${descriptor.key}',
        );
      }
    });
  });

  group('isStatVisibleForViewer', () {
    test('owner sees every catalog stat unconditionally', () {
      for (final descriptor in profileStatCatalog) {
        expect(
          isStatVisibleForViewer(
            key: descriptor.key,
            statVisibilityOverrides: const {},
            isOwner: true,
          ),
          isTrue,
          reason: '${descriptor.key} should be visible to owner',
        );
      }
    });

    test('owner sees stats with override flag too (muted in UI elsewhere)',
        () {
      expect(
        isStatVisibleForViewer(
          key: 'hero.level',
          statVisibilityOverrides: const {'hero.level'},
          isOwner: true,
        ),
        isTrue,
      );
    });

    test('XOR: default-visible + override = hidden on foreign profile', () {
      expect(
        isStatVisibleForViewer(
          key: 'hero.level',
          statVisibilityOverrides: const {'hero.level'},
          isOwner: false,
        ),
        isFalse,
      );
    });

    test('default-visible + no override = visible on foreign profile', () {
      expect(
        isStatVisibleForViewer(
          key: 'hero.level',
          statVisibilityOverrides: const {},
          isOwner: false,
        ),
        isTrue,
      );
    });

    test('default-hidden + no override = hidden on foreign profile', () {
      // Sensitive defaults remain hidden until the owner explicitly
      // opts in by flipping the override.
      expect(
        isStatVisibleForViewer(
          key: 'hero.grantedRewards',
          statVisibilityOverrides: const {},
          isOwner: false,
        ),
        isFalse,
      );
      expect(
        isStatVisibleForViewer(
          key: 'body.latestWeight',
          statVisibilityOverrides: const {},
          isOwner: false,
        ),
        isFalse,
      );
      expect(
        isStatVisibleForViewer(
          key: 'nutrition.avgKcal7d',
          statVisibilityOverrides: const {},
          isOwner: false,
        ),
        isFalse,
      );
    });

    test('XOR: default-hidden + override = visible on foreign profile', () {
      // The whole point of the rename — owner can opt in to publish a
      // default-hidden stat by toggling its override.
      expect(
        isStatVisibleForViewer(
          key: 'body.latestWeight',
          statVisibilityOverrides: const {'body.latestWeight'},
          isOwner: false,
        ),
        isTrue,
      );
      expect(
        isStatVisibleForViewer(
          key: 'nutrition.avgKcal7d',
          statVisibilityOverrides: const {'nutrition.avgKcal7d'},
          isOwner: false,
        ),
        isTrue,
      );
      expect(
        isStatVisibleForViewer(
          key: 'hero.cosmeticsUnlocked',
          statVisibilityOverrides: const {'hero.cosmeticsUnlocked'},
          isOwner: false,
        ),
        isTrue,
      );
    });

    test('unknown key collapses to hidden on foreign profiles', () {
      expect(
        isStatVisibleForViewer(
          key: 'does.not.exist',
          statVisibilityOverrides: const {},
          isOwner: false,
        ),
        isFalse,
      );
    });
  });
}

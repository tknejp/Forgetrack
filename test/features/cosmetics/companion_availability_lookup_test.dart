import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/companion_availability_lookup.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';

void main() {
  group('companionAvailabilityLookup', () {
    test('allCompanionAvailabilities is non-empty and unmodifiable', () {
      final all = allCompanionAvailabilities;
      expect(all, isNotEmpty);
      expect(() => all.add(all.first), throwsUnsupportedError);
    });

    test('every CompanionAvailability node points to a Companion in '
        'the cosmetics catalog (reverse id parity)', () {
      // Phase 11 invariant — every gating node must resolve to a
      // catalog companion or the matrix renders an empty row + the
      // claim flow crashes when the sheet looks up rarity / asset.
      final catalog = CosmeticCatalog();
      final dangling = <String>[];
      for (final node in allCompanionAvailabilities) {
        if (catalog.byId(node.companionId) == null) {
          dangling.add(node.companionId);
        }
      }
      expect(
        dangling,
        isEmpty,
        reason: 'Availability nodes without a matching cosmetic: $dangling',
      );
    });

    test('every catalog Companion is either gated by an availability '
        'node or listed in companionsClaimedViaUnlockRules (forward id '
        'parity)', () {
      // Track A R.7 invariant — a new companion must pick one of the
      // two claim paths and stick to it. The whitelist documents the
      // intentional unlock-rule path; everything else routes through
      // engine.claimNode via CompanionAvailability. Devtools-only and
      // dev-tagged companions (marked `metadata['devOnly'] == true`)
      // are exempt — they're not claimable through either pipeline.
      final catalog = CosmeticCatalog();
      final orphans = <String>[];
      for (final companion in catalog.companions) {
        final id = companion.id.value;
        if (companion.metadata['devOnly'] == true) continue;
        final hasNode = companionAvailabilityFor(id) != null;
        final whitelisted = companionsClaimedViaUnlockRules.contains(id);
        if (!hasNode && !whitelisted) {
          orphans.add(id);
        }
      }
      expect(
        orphans,
        isEmpty,
        reason: 'Companions with no claim path: $orphans. '
            'Either add a CompanionAvailability node in '
            'companions_content.dart or list the id in '
            'companionsClaimedViaUnlockRules in '
            'companion_availability_lookup.dart.',
      );
    });

    test('companionAvailabilityFor returns null for non-companion ids', () {
      // Frames / relics / backgrounds are not gated by
      // CompanionAvailability; lookup must return null so callers
      // (devtools matrix, claim flow) don't misroute a frame through
      // the companion path.
      expect(companionAvailabilityFor('frame_pilgrim'), isNull);
      expect(companionAvailabilityFor('relic_campfire_spark'), isNull);
      expect(companionAvailabilityFor('background_camp'), isNull);
      expect(companionAvailabilityFor('does_not_exist'), isNull);
    });

    test('companionAvailabilityFor returns the matching node for a '
        'known companion', () {
      final node = companionAvailabilityFor('companion_ember_sprite');
      expect(node, isNotNull);
      expect(node!.companionId, 'companion_ember_sprite');
    });
  });
}

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

    test('every catalog Companion is gated by an availability node '
        '(forward id parity)', () {
      // R.7 correction — every non-devOnly companion must claim
      // through engine.claimNode via CompanionAvailability. The earlier
      // "claimed-via-unlock-rules" whitelist branch was removed once
      // the dead CosmeticUnlockEvaluator was deleted; the three
      // companions previously listed there (bridge_gargoyle / cave_lynx
      // / aurora_stag) now have first-class CompanionAvailability
      // nodes in companions_content.dart. Devtools-only and dev-tagged
      // companions (`metadata['devOnly'] == true`) stay exempt — they
      // are not claimable through any production pipeline.
      final catalog = CosmeticCatalog();
      final orphans = <String>[];
      for (final companion in catalog.companions) {
        final id = companion.id.value;
        if (companion.metadata['devOnly'] == true) continue;
        if (companionAvailabilityFor(id) == null) {
          orphans.add(id);
        }
      }
      expect(
        orphans,
        isEmpty,
        reason: 'Companions with no CompanionAvailability node: $orphans. '
            'Add one in companions_content.dart.',
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

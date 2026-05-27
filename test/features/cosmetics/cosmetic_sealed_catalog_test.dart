import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';

void main() {
  group('Cosmetic sealed hierarchy', () {
    test('each subtype is const-constructible and reports its slot type', () {
      const frame = Frame(
        id: CosmeticId('test_frame'),
        rarity: Rarity.common,
        region: CosmeticRegion.neutral,
        name: _noL10n,
        description: _noL10n,
      );
      const background = Background(
        id: CosmeticId('test_background'),
        rarity: Rarity.common,
        region: CosmeticRegion.neutral,
        name: _noL10n,
        description: _noL10n,
      );
      const companion = Companion(
        id: CosmeticId('test_companion'),
        rarity: Rarity.common,
        region: CosmeticRegion.neutral,
        name: _noL10n,
        description: _noL10n,
      );
      const relic = RelicCosmetic(
        id: CosmeticId('test_relic'),
        rarity: Rarity.common,
        region: CosmeticRegion.neutral,
        name: _noL10n,
        description: _noL10n,
      );
      const emblem = Emblem(
        id: CosmeticId('test_emblem'),
        rarity: Rarity.common,
        region: CosmeticRegion.neutral,
        name: _noL10n,
        description: _noL10n,
      );
      const titleFlair = TitleFlair(
        id: CosmeticId('test_title'),
        rarity: Rarity.common,
        region: CosmeticRegion.neutral,
        name: _noL10n,
        description: _noL10n,
      );
      const mapEffect = MapEffect(
        id: CosmeticId('test_map'),
        rarity: Rarity.common,
        region: CosmeticRegion.neutral,
        name: _noL10n,
        description: _noL10n,
      );

      expect(frame.type, CosmeticType.frame);
      expect(background.type, CosmeticType.background);
      expect(companion.type, CosmeticType.companion);
      expect(relic.type, CosmeticType.relic);
      expect(emblem.type, CosmeticType.emblem);
      expect(titleFlair.type, CosmeticType.titleFlair);
      expect(mapEffect.type, CosmeticType.mapEffect);

      // Pattern matching discriminates via subtype, not an enum field.
      // (Static `is` checks on the concrete-typed locals are tautologies;
      // the catalog-integrity test below verifies it on `Cosmetic` upcasts.)
      final Cosmetic upcast = frame;
      expect(upcast is Frame, isTrue);
      expect(upcast is Background, isFalse);
      // Disambiguation: `RelicCosmetic` is intentionally distinct from the
      // progression catalog's `Relic` gating node — references are by id.
    });

    test('CosmeticCatalog rows are well-typed per subtype', () {
      final catalog = CosmeticCatalog();
      expect(catalog.validate(), isEmpty);

      for (final def in catalog.frames) {
        expect(def, isA<Frame>(), reason: '${def.id} is in frames');
        expect(def.type, CosmeticType.frame);
      }
      for (final def in catalog.backgrounds) {
        expect(def, isA<Background>());
        expect(def.type, CosmeticType.background);
      }
      for (final def in catalog.companions) {
        expect(def, isA<Companion>());
        expect(def.type, CosmeticType.companion);
      }
      for (final def in catalog.relics) {
        expect(def, isA<RelicCosmetic>());
        expect(def.type, CosmeticType.relic);
      }
      for (final def in catalog.emblems) {
        expect(def, isA<Emblem>());
        expect(def.type, CosmeticType.emblem);
      }
    });

    test('byId(id) returns a row of the correct subtype', () {
      final catalog = CosmeticCatalog();
      final frame = catalog.byId('frame_pilgrim');
      expect(frame, isA<Frame>());
      final companion = catalog.byId('companion_ember_sprite');
      expect(companion, isA<Companion>());
      final relic = catalog.byId('relic_campfire_spark');
      expect(relic, isA<RelicCosmetic>());
      final emblem = catalog.byId('emblem_pilgrim_mark');
      expect(emblem, isA<Emblem>());
      final background = catalog.byId('background_camp');
      expect(background, isA<Background>());
    });

    test('per-type accessors partition the catalog', () {
      final catalog = CosmeticCatalog();
      final partitionSum = catalog.frames.length +
          catalog.backgrounds.length +
          catalog.companions.length +
          catalog.relics.length +
          catalog.emblems.length +
          catalog.titleFlairs.length +
          catalog.mapEffects.length +
          catalog.skins.length +
          catalog.banners.length;
      expect(partitionSum, catalog.all.length);
    });
  });
}

String _noL10n(Object l10n) => '';

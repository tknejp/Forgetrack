import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';

/// Guard against catalog drift on the cosmetics side: every
/// player-facing [Companion] in the catalog must declare a buff so
/// the player can pick a companion knowing what it does. Dev-only
/// companions (Monster Energy, Lesni liska, Lucernovy golem) sit
/// in their own block at the bottom of the catalog and are gated
/// by `isPremium == false` + an explicit dev-tools-only contract;
/// they are excluded from this check.
void main() {
  test('every public Companion in the catalog declares a buff', () {
    const catalog = CosmeticCatalog();
    final missing = <String>[];
    for (final cosmetic in catalog.all) {
      if (cosmetic is! Companion) continue;
      // Skip the developer-only block at the bottom of the catalog.
      // Those rows exist to test devtools transitions and don't
      // need a balance-tier buff.
      if (cosmetic.id.raw.startsWith('companion_monster_energy') ||
          cosmetic.id.raw == 'companion_lesni_liska' ||
          cosmetic.id.raw == 'companion_lucernovy_golem') {
        continue;
      }
      if (cosmetic.buff == null) {
        missing.add(cosmetic.id.raw);
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'Add a `buff:` field to each companion below in '
          '`lib/features/cosmetics/domain/cosmetic_catalog.dart`. The '
          'card #91 table maps each one to a flat / streak / weekly / '
          'chapter-depth buff:\n${missing.join('\n')}',
    );
  });
}

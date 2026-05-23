import 'hero_race.dart';

/// Single source of truth for the 9 starter races. Compiled in; loaded
/// only at onboarding Step 1 and at render time through
/// [SkinAssetResolver].
///
/// Catalog ordering matches the design grid (3-row layout):
///   * row 1: Human male / Human female / Elf male
///   * row 2: Elf female / Dwarf male / Dwarf female
///   * row 3: Orc / Spirit / Golem
///
/// Adding a race = appending an entry + shipping artwork under
/// `assets/cosmetics/skins/<folder>/` (one base skin per race, plus
/// any unlockable themes). l10n keys are auto-checked at compile
/// time through the closure-style name/description fields.
class HeroRaceCatalog {
  const HeroRaceCatalog();

  static final List<HeroRace> definitions = List.unmodifiable(<HeroRace>[
    HeroRace(
      id: const HeroRaceId('race_human_male'),
      folder: 'human_male',
      name: (l) => l.heroRaceHumanName,
      description: (l) => l.heroRaceHumanDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_human_female'),
      folder: 'human_female',
      name: (l) => l.heroRaceHumanName,
      description: (l) => l.heroRaceHumanDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_elf_male'),
      folder: 'elf_male',
      name: (l) => l.heroRaceElfName,
      description: (l) => l.heroRaceElfDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_elf_female'),
      folder: 'elf_female',
      name: (l) => l.heroRaceElfName,
      description: (l) => l.heroRaceElfDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_dwarf_male'),
      folder: 'dwarf_male',
      name: (l) => l.heroRaceDwarfName,
      description: (l) => l.heroRaceDwarfDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_dwarf_female'),
      folder: 'dwarf_female',
      name: (l) => l.heroRaceDwarfName,
      description: (l) => l.heroRaceDwarfDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_orc'),
      folder: 'orc',
      name: (l) => l.heroRaceOrcName,
      description: (l) => l.heroRaceOrcDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_spirit'),
      folder: 'spirit',
      name: (l) => l.heroRaceSpiritName,
      description: (l) => l.heroRaceSpiritDesc,
    ),
    HeroRace(
      id: const HeroRaceId('race_golem'),
      folder: 'golem',
      name: (l) => l.heroRaceGolemName,
      description: (l) => l.heroRaceGolemDesc,
    ),
  ]);

  /// Linear lookup over [definitions]. Catalog is 9 entries so a
  /// pre-built map would be overengineered.
  static HeroRace? byId(String? id) {
    if (id == null) return null;
    for (final r in definitions) {
      if (r.id == id) return r;
    }
    return null;
  }
}

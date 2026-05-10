import '../../l10n/app_localizations.dart';

/// Six-tier rarity ladder shared by every reward in the app — cosmetics,
/// quest milestones, achievement milestones, level titles, and the
/// celebration overlay. There is exactly one source of truth; features
/// extend their definitions with a [Rarity] field rather than re-deriving
/// "how rare is this" from category, difficulty, XP amount, etc.
///
/// Ordered ascending: `common` is the lowest, `mythic` the highest. Use
/// [Rarity.max] to combine multiple rewards into a single "head rarity"
/// for celebration tinting.
enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic;

  /// Returns the higher of two rarities (the one further along the ladder).
  static Rarity max(Rarity a, Rarity b) => a.index >= b.index ? a : b;

  /// Localised label (e.g. "Legendární"). Reuses the existing
  /// `cosmeticRarity*` ARB strings so a Common cosmetic and a Common
  /// quest reward always read the same.
  String label(AppLocalizations l10n) {
    switch (this) {
      case Rarity.common:
        return l10n.cosmeticRarityCommon;
      case Rarity.uncommon:
        return l10n.cosmeticRarityUncommon;
      case Rarity.rare:
        return l10n.cosmeticRarityRare;
      case Rarity.epic:
        return l10n.cosmeticRarityEpic;
      case Rarity.legendary:
        return l10n.cosmeticRarityLegendary;
      case Rarity.mythic:
        return l10n.cosmeticRarityMythic;
    }
  }
}

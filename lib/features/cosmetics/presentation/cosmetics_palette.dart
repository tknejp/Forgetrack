import '../../../shared/theme/design_tokens.dart';
import '../domain/cosmetic_models.dart';

abstract final class CosmeticsPalette {
  static Rarity forRarity(CosmeticRarity rarity) {
    switch (rarity) {
      case CosmeticRarity.common:
        return Rarity.common;
      case CosmeticRarity.uncommon:
        return Rarity.uncommon;
      case CosmeticRarity.rare:
        return Rarity.rare;
      case CosmeticRarity.epic:
        return Rarity.epic;
      case CosmeticRarity.legendary:
        return Rarity.legendary;
      case CosmeticRarity.mythic:
        return Rarity.mythic;
    }
  }
}

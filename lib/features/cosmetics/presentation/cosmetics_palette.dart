import '../../../shared/theme/design_tokens.dart';
import '../domain/cosmetic_models.dart';

abstract final class CosmeticsPalette {
  static FtRarity forRarity(CosmeticRarity rarity) {
    switch (rarity) {
      case CosmeticRarity.common:
        return FtRarity.common;
      case CosmeticRarity.rare:
        return FtRarity.rare;
      case CosmeticRarity.epic:
        return FtRarity.epic;
      case CosmeticRarity.legendary:
        return FtRarity.legendary;
      case CosmeticRarity.mythic:
        return FtRarity.mythic;
    }
  }
}

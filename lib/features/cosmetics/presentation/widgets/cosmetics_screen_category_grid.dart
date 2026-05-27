import 'package:flutter/material.dart' hide Banner;
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../application/cosmetics_provider.dart';
import '../../application/emblem_board_provider.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/inventory.dart';
import 'banner_inventory_tile.dart';
import 'cosmetics_screen_card.dart';
import 'cosmetics_screen_chrome.dart';

class CosmeticsScreenCategoryGrid extends StatelessWidget {
  const CosmeticsScreenCategoryGrid({
    super.key,
    required this.defs,
    required this.cosmetics,
    required this.state,
    required this.inventory,
    required this.devTools,
    required this.l10n,
    required this.onTap,
    this.consumedRelicIds = const {},
  });

  final List<Cosmetic> defs;
  final CosmeticsProvider cosmetics;
  final UserCosmeticsState state;
  /// Phase 10 read projection. Cards pattern-match on lifecycle
  /// instead of reading `CosmeticRevealState` directly.
  final Inventory inventory;
  final bool devTools;
  final AppLocalizations l10n;
  final ValueChanged<Cosmetic> onTap;
  final Set<String> consumedRelicIds;

  @override
  Widget build(BuildContext context) {
    // Pin lookup for the emblem `isEquipped` chrome below. Watching
    // the board provider so the badge updates the instant the player
    // pins / unpins from any other surface (board screen, debug).
    final uid = cosmetics.currentUid;
    final Set<String> pinnedEmblemIds;
    if (uid != null) {
      final board = context.watch<EmblemBoardProvider>().boardForUser(uid);
      pinnedEmblemIds = {
        for (final id in board.slots)
          if (id != null) id,
      };
    } else {
      pinnedEmblemIds = const <String>{};
    }

    if (defs.isEmpty) {
      return RefreshIndicator(
        onRefresh: cosmetics.refresh,
        color: Tokens.accent,
        backgroundColor: Tokens.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.fromLTRB(14, 30, 14, 36),
              child: CosmeticsScreenEmptyInventory(),
            ),
          ],
        ),
      );
    }

    // Banner-only category gets a vertical list of full-width
    // BannerInventoryTile rows so each banner previews live with the
    // player's current level + title. The 3-col grid would squash the
    // 4:1 chrome down to a thumbnail where the overlay text is
    // unreadable.
    final bannerOnly = defs.every((d) => d is Banner);
    if (bannerOnly) {
      return RefreshIndicator(
        onRefresh: cosmetics.refresh,
        color: Tokens.accent,
        backgroundColor: Tokens.surface,
        child: _BannerInventoryList(
          defs: defs.cast<Banner>(),
          state: state,
          l10n: l10n,
          onTap: onTap,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cosmetics.refresh,
      color: Tokens.accent,
      backgroundColor: Tokens.surface,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        itemCount: defs.length,
        itemBuilder: (context, index) {
          final def = defs[index];
          final isUnlocked = state.unlocked.containsKey(def.id);
          final lifecycle =
              devTools ? null : inventory.byIdString(def.id)?.lifecycle;
          final isRelicConsumed = !devTools &&
              def is RelicCosmetic &&
              consumedRelicIds.contains(def.id);
          // Emblems are multi-slot via EmblemBoard, not the single
          // `equipped` slot — show the equipped chrome whenever an
          // emblem is pinned anywhere on the player's board so
          // "equipped = buffed" reads consistently with the new
          // emblem XP buff system. Relics aren't equippable from
          // the inventory at all (they're consumed by companion
          // claims), so a stale `Loadout.relicId` doesn't count.
          final isEmblemPinned =
              def is Emblem && pinnedEmblemIds.contains(def.id);
          final slotEquipped = def is! Emblem &&
              def is! RelicCosmetic &&
              state.equipped.slotId(def.type) == def.id;
          return CosmeticsScreenCard(
            definition: def,
            isEquipped: isEmblemPinned || slotEquipped,
            isLocked: devTools && !isUnlocked,
            showMissingAsset: devTools,
            lifecycle: lifecycle,
            l10n: l10n,
            isRelicConsumed: isRelicConsumed,
            onTap: () => onTap(def),
          );
        },
      ),
    );
  }
}

/// Vertical list renderer for the banner-only category. Resolves the
/// player's current level + title once, then renders each unlocked
/// banner via [BannerInventoryTile] so the player sees how each banner
/// would look against their *live* chrome — not a generic placeholder.
class _BannerInventoryList extends StatelessWidget {
  const _BannerInventoryList({
    required this.defs,
    required this.state,
    required this.l10n,
    required this.onTap,
  });

  final List<Banner> defs;
  final UserCosmeticsState state;
  final AppLocalizations l10n;
  final ValueChanged<Cosmetic> onTap;

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionEngineProvider>();
    final level = progression.level;
    final display = const ProgressionDisplayResolver().levelDisplay(level);
    final title = display.title(l10n);

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
      itemCount: defs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final def = defs[index];
        final isUnlocked = state.unlocked.containsKey(def.id);
        final isEquipped = state.equipped.slotId(def.type) == def.id;
        return BannerInventoryTile(
          definition: def,
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          level: level,
          title: title,
          l10n: l10n,
          onTap: () => onTap(def),
        );
      },
    );
  }
}

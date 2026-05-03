import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_models.dart';
import 'widgets/cosmetic_collection_tile.dart';
import 'widgets/cosmetic_equipped_chip.dart';

/// Temporary end-to-end smoke screen for the cosmetics engine. Lists every
/// catalog entry grouped by type, lets you tap an unlocked one to equip it,
/// and shows a chip-row for currently equipped slots with an unequip button.
///
/// Not intended as a final collection / wardrobe UI — once the real screen
/// lands, delete this file (or keep behind a debug flag).
class CosmeticsDebugScreen extends StatelessWidget {
  const CosmeticsDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmetics — debug'),
      ),
      body: _Body(cosmetics: cosmetics, l10n: l10n),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.cosmetics, required this.l10n});

  final CosmeticsProvider cosmetics;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    if (cosmetics.isLoading && cosmetics.state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = cosmetics.state;
    if (state == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No cosmetics state. Sign in first — CosmeticsProvider binds to '
            'the AuthProvider uid via ChangeNotifierProxyProvider.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final catalog = cosmetics.service.catalog;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _StatusRow(cosmetics: cosmetics),
        const SizedBox(height: 16),
        Text('Equipped', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _EquippedRow(
          cosmetics: cosmetics,
          state: state,
          l10n: l10n,
        ),
        const SizedBox(height: 24),
        for (final type in CosmeticType.values) ...[
          _TypeSection(
            type: type,
            definitions: catalog.byType(type),
            state: state,
            cosmetics: cosmetics,
            l10n: l10n,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.cosmetics});

  final CosmeticsProvider cosmetics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedCount = cosmetics.state?.unlocked.length ?? 0;
    final error = cosmetics.errorMessage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'uid: ${cosmetics.currentUid ?? '—'}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'unlocked: $unlockedCount   loading: ${cosmetics.isLoading}',
            style: theme.textTheme.bodySmall,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'last error: $error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EquippedRow extends StatelessWidget {
  const _EquippedRow({
    required this.cosmetics,
    required this.state,
    required this.l10n,
  });

  final CosmeticsProvider cosmetics;
  final UserCosmeticsState state;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final equippedDefs = cosmetics.service.getEquippedDefinitions(state);
    if (equippedDefs.isEmpty) {
      return Text(
        'Nothing equipped. Tap an unlocked tile below to equip it.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final def in equippedDefs)
          _UnequipChip(
            definition: def,
            l10n: l10n,
            onUnequip: () => cosmetics.unequip(def.type),
          ),
      ],
    );
  }
}

class _UnequipChip extends StatelessWidget {
  const _UnequipChip({
    required this.definition,
    required this.l10n,
    required this.onUnequip,
  });

  final CosmeticDefinition definition;
  final AppLocalizations? l10n;
  final VoidCallback onUnequip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CosmeticEquippedChip(definition: definition, l10n: l10n),
        IconButton(
          tooltip: 'Unequip',
          icon: const Icon(Icons.close, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: onUnequip,
        ),
      ],
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.definitions,
    required this.state,
    required this.cosmetics,
    required this.l10n,
  });

  final CosmeticType type;
  final List<CosmeticDefinition> definitions;
  final UserCosmeticsState state;
  final CosmeticsProvider cosmetics;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    if (definitions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final equippedId = state.equipped.slotId(type);
    final unlockedInType =
        definitions.where((d) => state.unlocked.containsKey(d.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                type.name,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              '$unlockedInType / ${definitions.length}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final cols = constraints.maxWidth > 480 ? 4 : 3;
            final tileSize =
                (constraints.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final def in definitions)
                  SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: _Tile(
                      definition: def,
                      isUnlocked: state.unlocked.containsKey(def.id),
                      isEquipped: def.id == equippedId,
                      l10n: l10n,
                      cosmetics: cosmetics,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.definition,
    required this.isUnlocked,
    required this.isEquipped,
    required this.l10n,
    required this.cosmetics,
  });

  final CosmeticDefinition definition;
  final bool isUnlocked;
  final bool isEquipped;
  final AppLocalizations? l10n;
  final CosmeticsProvider cosmetics;

  @override
  Widget build(BuildContext context) {
    return CosmeticCollectionTile(
      definition: definition,
      isUnlocked: isUnlocked,
      isEquipped: isEquipped,
      l10n: l10n,
      onTap: () {
        if (!isUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Locked: ${definition.id}'),
              duration: const Duration(seconds: 1),
            ),
          );
          return;
        }
        if (isEquipped) {
          // Tap equipped item to unequip — convenient for quick toggling.
          cosmetics.unequip(definition.type);
          return;
        }
        cosmetics.equip(definition.id);
      },
    );
  }
}

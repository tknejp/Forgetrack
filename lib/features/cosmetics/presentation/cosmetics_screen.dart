import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_models.dart';
import 'cosmetic_details_sheet.dart';
import 'cosmetics_l10n.dart';
import 'cosmetics_screen_internals.dart';

class CosmeticsScreen extends StatefulWidget {
  const CosmeticsScreen({super.key, this.initialType});

  final CosmeticType? initialType;

  @override
  State<CosmeticsScreen> createState() => _CosmeticsScreenState();
}

class _CosmeticsScreenState extends State<CosmeticsScreen> {
  CosmeticType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final l10n = CosmeticsL10n(AppLocalizations.of(context));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                MediaQuery.of(context).padding.top + 12,
                14,
                0,
              ),
              child: ScreenHeader(
                greeting: '',
                title: 'Kosmetika',
                leading: const FtBackButton(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody(context, cosmetics, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CosmeticsProvider cosmetics,
    CosmeticsL10n l10n,
  ) {
    if (cosmetics.isLoading && cosmetics.state == null) {
      return const Center(
        child: CircularProgressIndicator(color: Tokens.accent),
      );
    }

    final state = cosmetics.state;
    if (state == null) return const _NotSignedIn();

    final config = cosmetics.service.config;
    final unlockedDefs = cosmetics.service
        .getUnlockedDefinitions(state)
        .where(config.isUsable)
        .toList(growable: false)
      ..sort((a, b) => _compareUnlockedCosmetics(a, b, state));
    final equippedDefs = cosmetics.service.getEquippedDefinitions(state);
    final presentTypes = CosmeticType.values
        .where((type) => unlockedDefs.any((def) => def.type == type))
        .toList(growable: false);
    final selectedType =
        presentTypes.contains(_selectedType) ? _selectedType : null;
    final filteredDefs = selectedType == null
        ? unlockedDefs
        : unlockedDefs
            .where((def) => def.type == selectedType)
            .toList(growable: false);

    return RefreshIndicator(
      onRefresh: cosmetics.refresh,
      color: Tokens.accent,
      backgroundColor: Tokens.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            sliver: SliverToBoxAdapter(
              child: _EquippedSection(
                definitions: equippedDefs,
                state: state,
                l10n: l10n,
                onTap: (definition) => _showDetails(
                  context,
                  cosmetics: cosmetics,
                  state: state,
                  definition: definition,
                  l10n: l10n,
                ),
              ),
            ),
          ),
          if (presentTypes.isNotEmpty)
            SliverToBoxAdapter(
              child: _FilterBar(
                types: presentTypes,
                selectedType: selectedType,
                onSelect: (type) => setState(() => _selectedType = type),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
            sliver: filteredDefs.isEmpty
                ? const SliverToBoxAdapter(child: _EmptyInventory())
                : SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final definition = filteredDefs[index];
                        return _CosmeticCard(
                          definition: definition,
                          isEquipped: state.equipped.slotId(definition.type) ==
                              definition.id,
                          l10n: l10n,
                          onTap: () => _showDetails(
                            context,
                            cosmetics: cosmetics,
                            state: state,
                            definition: definition,
                            l10n: l10n,
                          ),
                        );
                      },
                      childCount: filteredDefs.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.88,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetails(
    BuildContext context, {
    required CosmeticsProvider cosmetics,
    required UserCosmeticsState state,
    required CosmeticDefinition definition,
    required CosmeticsL10n l10n,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CosmeticDetailsSheet(
        definition: definition,
        state: state,
        l10n: l10n,
      ),
    );
  }
}

class _EquippedSection extends StatelessWidget {
  const _EquippedSection({
    required this.definitions,
    required this.state,
    required this.l10n,
    required this.onTap,
  });

  final List<CosmeticDefinition> definitions;
  final UserCosmeticsState state;
  final CosmeticsL10n l10n;
  final ValueChanged<CosmeticDefinition> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead(
          label: 'Vybaveno',
          caption: 'Aktuální vzhled profilu a cesty',
        ),
        const SizedBox(height: 10),
        if (definitions.isEmpty)
          const _EmptyLine(
            title: 'Zatím nic není vybavené.',
            caption: 'Klepni na odemčenou kosmetiku níže a vyber Vybavit.',
          )
        else
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final definition = definitions[index];
                return SizedBox(
                  width: 116,
                  child: _CosmeticCard(
                    definition: definition,
                    isEquipped: true,
                    l10n: l10n,
                    onTap: () => onTap(definition),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: definitions.length,
            ),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.types,
    required this.selectedType,
    required this.onSelect,
  });

  final List<CosmeticType> types;
  final CosmeticType? selectedType;
  final ValueChanged<CosmeticType?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHead(label: 'Inventář'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'Vše',
                  icon: Icons.apps_rounded,
                  isSelected: selectedType == null,
                  onTap: () => onSelect(null),
                ),
                for (final type in types) ...[
                  const SizedBox(width: Tokens.spaceSm),
                  _FilterChipButton(
                    label: cosmeticTypeLabel(type),
                    icon: cosmeticIconForType(type),
                    isSelected: selectedType == type,
                    onTap: () => onSelect(type),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Tokens.accent : Tokens.onSurfaceMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusProgress),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Tokens.accent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(
            color: isSelected
                ? Tokens.accent.withValues(alpha: 0.44)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.definition,
    required this.isEquipped,
    required this.l10n,
    required this.onTap,
  });

  final CosmeticDefinition definition;
  final bool isEquipped;
  final CosmeticsL10n l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = cosmeticRarityColor(definition.rarity);
    final assetPath = context
        .read<CosmeticsProvider>()
        .service
        .config
        .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.13),
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: color.withValues(alpha: 0.27)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CosmeticBadge(
                      definition: definition,
                      assetPath: assetPath,
                      color: color,
                      size: _cardBadgeSize(definition.type),
                    ),
                    const SizedBox(height: Tokens.spaceSm),
                    Text(
                      l10n.name(definition),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: Tokens.fontSizeTiny,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isEquipped)
              Positioned(
                top: 7,
                right: 7,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 17,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.label, this.caption});

  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded,
            size: 14, color: Tokens.accent),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Tokens.accent,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    color: Tokens.onSurfaceFaint,
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 6),
      child: _EmptyLine(
        title: 'Zatím žádná odemčená kosmetika.',
        caption: 'Nové kousky se objeví po splnění úspěchů a milníků.',
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Tokens.onSurface,
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              color: Tokens.onSurfaceMuted,
              fontSize: Tokens.fontSizeCaption,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotSignedIn extends StatelessWidget {
  const _NotSignedIn();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: _EmptyLine(
          title: 'Inventář není dostupný.',
          caption: 'Přihlas se pro přístup ke kosmetice.',
        ),
      ),
    );
  }
}

double _cardBadgeSize(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return 66;
    case CosmeticType.relic:
    case CosmeticType.background:
    case CosmeticType.emblem:
    case CosmeticType.companion:
    case CosmeticType.titleFlair:
    case CosmeticType.mapEffect:
      return 48;
  }
}

int _compareUnlockedCosmetics(
  CosmeticDefinition a,
  CosmeticDefinition b,
  UserCosmeticsState state,
) {
  final rarity = _rarityRank(b.rarity).compareTo(_rarityRank(a.rarity));
  if (rarity != 0) return rarity;
  final unlockedAtA = state.unlocked[a.id]?.unlockedAt;
  final unlockedAtB = state.unlocked[b.id]?.unlockedAt;
  if (unlockedAtA != null && unlockedAtB != null) {
    final unlockedAt = unlockedAtB.compareTo(unlockedAtA);
    if (unlockedAt != 0) return unlockedAt;
  }
  final sortOrder = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrder != 0) return sortOrder;
  return a.id.compareTo(b.id);
}

int _rarityRank(CosmeticRarity rarity) {
  switch (rarity) {
    case CosmeticRarity.common:
      return 0;
    case CosmeticRarity.rare:
      return 1;
    case CosmeticRarity.epic:
      return 2;
    case CosmeticRarity.legendary:
      return 3;
  }
}

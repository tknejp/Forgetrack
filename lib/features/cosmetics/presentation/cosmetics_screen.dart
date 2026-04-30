import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_models.dart';
import 'cosmetics_l10n.dart';

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

    return Scaffold(
      backgroundColor: FtTokens.bg,
      appBar: const _CosmeticsAppBar(),
      body: _buildBody(context, cosmetics, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CosmeticsProvider cosmetics,
    CosmeticsL10n l10n,
  ) {
    if (cosmetics.isLoading && cosmetics.state == null) {
      return const Center(
        child: CircularProgressIndicator(color: FtTokens.accent),
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
      color: FtTokens.accent,
      backgroundColor: FtTokens.surface,
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
      builder: (_) => _CosmeticDetailsSheet(
        definition: definition,
        state: state,
        l10n: l10n,
      ),
    );
  }
}

class _CosmeticsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CosmeticsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: FtTokens.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: FtTokens.onSurface,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: const Text(
        'Kosmetika',
        style: TextStyle(
          color: FtTokens.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
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
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: _typeLabel(type),
                    icon: _iconForType(type),
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
    final color = isSelected ? FtTokens.accent : FtTokens.onSurfaceMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? FtTokens.accent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected
                ? FtTokens.accent.withValues(alpha: 0.44)
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
                fontSize: 11,
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
    final color = _rarityColor(definition.rarity);
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
          borderRadius: BorderRadius.circular(12),
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
                    _CosmeticBadge(
                      definition: definition,
                      assetPath: assetPath,
                      color: color,
                      size: _cardBadgeSize(definition.type),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.name(definition),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: FtTokens.fontSizeTiny,
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

class _CosmeticBadge extends StatelessWidget {
  const _CosmeticBadge({
    required this.definition,
    required this.assetPath,
    required this.color,
    this.size = 42,
  });

  final CosmeticDefinition definition;
  final String? assetPath;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isFrame = definition.type == CosmeticType.frame;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isFrame ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: color.withValues(alpha: isFrame ? 0.52 : 0.32),
          width: isFrame ? 1.8 : 1,
        ),
      ),
      clipBehavior: isFrame ? Clip.none : Clip.antiAlias,
      child: assetPath == null
          ? _BadgeFallback(type: definition.type, color: color, size: size)
          : Image.asset(
              assetPath!,
              fit: isFrame ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (_, __, ___) => _BadgeFallback(
                type: definition.type,
                color: color,
                size: size,
              ),
            ),
    );
  }
}

class _BadgeFallback extends StatelessWidget {
  const _BadgeFallback({
    required this.type,
    required this.color,
    required this.size,
  });

  final CosmeticType type;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _iconForType(type),
          color: Colors.white.withValues(alpha: 0.9),
          size: size * 0.52,
        ),
      ),
    );
  }
}

class _CosmeticDetailsSheet extends StatefulWidget {
  const _CosmeticDetailsSheet({
    required this.definition,
    required this.state,
    required this.l10n,
  });

  final CosmeticDefinition definition;
  final UserCosmeticsState state;
  final CosmeticsL10n l10n;

  @override
  State<_CosmeticDetailsSheet> createState() => _CosmeticDetailsSheetState();
}

class _CosmeticDetailsSheetState extends State<_CosmeticDetailsSheet> {
  bool _busy = false;

  Future<void> _toggleEquipped() async {
    if (_busy) return;
    setState(() => _busy = true);
    final provider = context.read<CosmeticsProvider>();
    final definition = widget.definition;
    final isEquipped =
        widget.state.equipped.slotId(definition.type) == definition.id;

    if (isEquipped) {
      await provider.unequip(definition.type);
    } else {
      await provider.equip(definition.id);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    final l10n = widget.l10n;
    final color = _rarityColor(definition.rarity);
    final isEquipped =
        widget.state.equipped.slotId(definition.type) == definition.id;
    final assetPath = context
        .read<CosmeticsProvider>()
        .service
        .config
        .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
    final description = l10n.description(definition);
    final unlock = widget.state.unlocked[definition.id];
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: FtTokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CosmeticBadge(
                definition: definition,
                assetPath: assetPath,
                color: color,
                size: 94,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.name(definition),
                      style: const TextStyle(
                        color: FtTokens.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyPill(
                            label: _typeLabel(definition.type), color: color),
                        _TinyPill(
                          label: _rarityLabel(definition.rarity),
                          color: color,
                        ),
                        if (isEquipped)
                          _TinyPill(label: l10n.equippedBadge, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              description,
              style: const TextStyle(
                color: FtTokens.onSurfaceMuted,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (unlock != null) ...[
            const SizedBox(height: 14),
            Text(
              'Odemčeno ${MaterialLocalizations.of(context).formatMediumDate(unlock.unlockedAt)}',
              style: TextStyle(
                color: color.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _ActionButton(
            label: isEquipped ? 'Odebrat z výbavy' : 'Vybavit',
            icon: isEquipped
                ? Icons.remove_circle_outline_rounded
                : Icons.check_circle_rounded,
            color: color,
            busy: _busy,
            onTap: _toggleEquipped,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: const Color(0xFF0D0F1C),
          disabledBackgroundColor: color.withValues(alpha: 0.34),
          disabledForegroundColor: FtTokens.onSurfaceMuted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: FtTokens.fontSizeMicro,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
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
            size: 14, color: FtTokens.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: FtTokens.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    color: FtTokens.onSurfaceFaint,
                    fontSize: FtTokens.fontSizeCaption,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FtTokens.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              color: FtTokens.onSurfaceMuted,
              fontSize: 11,
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

IconData _iconForType(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return Icons.crop_square_rounded;
    case CosmeticType.relic:
      return Icons.auto_awesome_rounded;
    case CosmeticType.background:
      return Icons.landscape_rounded;
    case CosmeticType.emblem:
      return Icons.shield_rounded;
    case CosmeticType.companion:
      return Icons.pets_rounded;
    case CosmeticType.titleFlair:
      return Icons.title_rounded;
    case CosmeticType.mapEffect:
      return Icons.map_rounded;
  }
}

String _typeLabel(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return 'Rámeček';
    case CosmeticType.relic:
      return 'Relikvie';
    case CosmeticType.background:
      return 'Pozadí';
    case CosmeticType.emblem:
      return 'Znak';
    case CosmeticType.companion:
      return 'Společník';
    case CosmeticType.titleFlair:
      return 'Titul';
    case CosmeticType.mapEffect:
      return 'Efekt mapy';
  }
}

String _rarityLabel(CosmeticRarity rarity) {
  switch (rarity) {
    case CosmeticRarity.common:
      return 'Běžné';
    case CosmeticRarity.rare:
      return 'Vzácné';
    case CosmeticRarity.epic:
      return 'Epické';
    case CosmeticRarity.legendary:
      return 'Legendární';
  }
}

Color _rarityColor(CosmeticRarity rarity) {
  switch (rarity) {
    case CosmeticRarity.common:
      return const Color(0xFF34D399);
    case CosmeticRarity.rare:
      return const Color(0xFF60A5FA);
    case CosmeticRarity.epic:
      return const Color(0xFFA78BFA);
    case CosmeticRarity.legendary:
      return const Color(0xFFFBBF24);
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

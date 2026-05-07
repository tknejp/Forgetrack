import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'ft_expand_chevron.dart';
import 'progress_bar.dart';
import 'stat_cell.dart';
import 'xp_claim_pill.dart';

class StatStat {
  final String value;
  final String label;
  final String? unit;

  const StatStat({
    required this.value,
    required this.label,
    this.unit,
  });
}

class StatCardVisualAssets {
  const StatCardVisualAssets({
    this.iconAssetPath,
    this.backgroundAssetPath,
    this.backgroundAlignment = Alignment.centerRight,
    this.backgroundOpacity = 0.12,
  });

  final String? iconAssetPath;
  final String? backgroundAssetPath;
  final Alignment backgroundAlignment;
  final double backgroundOpacity;

  bool get hasIconAsset => iconAssetPath != null && iconAssetPath!.isNotEmpty;
  bool get hasBackgroundAsset =>
      backgroundAssetPath != null && backgroundAssetPath!.isNotEmpty;
}

class StatCard extends StatefulWidget {
  final String icon;
  final String label;
  final Domain domain;
  final List<StatStat> stats;
  final double? progress;
  final String? badge;
  final bool trophy;
  final bool showProgress;
  final String? xp;
  final XpClaimPillData? xpData;
  final String? claimedXpLabel;
  final StatCardVisualAssets? visualAssets;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool collapsible;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.domain,
    required this.stats,
    this.progress,
    this.badge,
    this.trophy = false,
    this.showProgress = true,
    this.xp,
    this.xpData,
    this.claimedXpLabel,
    this.visualAssets,
    this.children = const [],
    this.initiallyExpanded = false,
    this.collapsible = true,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.collapsible ? widget.initiallyExpanded : true;
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final d = widget.domain;
    return GestureDetector(
      onTap: widget.collapsible ? () => setState(() => _open = !_open) : null,
      child: Container(
        decoration: d.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _buildBackgroundImage(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroIcon(d),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(d, ft),
                            const SizedBox(height: 5),
                            _buildCompactBody(d, ft),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _open
                          ? _buildExpandedBody(d, ft)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final assets = widget.visualAssets;
    if (assets == null || !assets.hasBackgroundAsset) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: assets.backgroundOpacity.clamp(0.0, 1.0),
          child: Image.asset(
            assets.backgroundAssetPath!,
            fit: BoxFit.cover,
            alignment: assets.backgroundAlignment,
            color: Colors.black.withValues(alpha: 0.18),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Domain d, ThemeTokens ft) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ft.onSurface,
            ),
          ),
        ),
        if (widget.trophy) ...[
          const Text('🏆', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
        ],
        if (widget.xpData != null) ...[
          XpClaimPill(
            data: widget.xpData!,
            claimedLabel: widget.claimedXpLabel,
          ),
          const SizedBox(width: 6),
        ] else if (widget.xp != null) ...[
          _XpPill(label: widget.xp!),
          const SizedBox(width: 6),
        ],
        if (widget.collapsible) ExpandChevron(expanded: _open),
      ],
    );
  }

  Widget _buildHeroIcon(Domain d) {
    final assets = widget.visualAssets;
    final hasAsset = assets != null && assets.hasIconAsset;
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: d.glow.withValues(alpha: 0.18),
                  blurRadius: 14,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          if (hasAsset)
            Image.asset(
              assets.iconAssetPath!,
              width: 74,
              height: 74,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Text(widget.icon, style: const TextStyle(fontSize: 30));
              },
            )
          else
            Text(widget.icon, style: const TextStyle(fontSize: 30)),
        ],
      ),
    );
  }

  Widget _buildCompactBody(Domain d, ThemeTokens ft) {
    final primary = widget.stats.isNotEmpty ? widget.stats[0] : null;
    final secondary = widget.stats.length > 1 ? widget.stats[1] : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                primary.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: d.color,
                  letterSpacing: -0.5,
                ),
              ),
              if (primary.unit != null) ...[
                const SizedBox(width: Tokens.spaceXs),
                Text(
                  primary.unit!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: d.color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          if (secondary != null && !widget.showProgress) ...[
            const SizedBox(height: 2),
            Text(
              _compactSubtitle(primary, secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ft.onSurfaceMuted,
              ),
            ),
          ],
        ],
        if (widget.showProgress && widget.progress != null) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(child: _buildProgressBar(d)),
              if (widget.badge != null) ...[
                const SizedBox(width: 10),
                Text(
                  widget.badge!,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w800,
                    color: ft.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  String _compactSubtitle(StatStat primary, StatStat secondary) {
    final primaryUnit = primary.unit == null ? '' : ' ${primary.unit}';
    final secondaryUnit = secondary.unit == null ? '' : ' ${secondary.unit}';
    if (widget.progress != null) {
      return '${primary.label}: ${primary.value}$primaryUnit / '
          '${secondary.value}$secondaryUnit';
    }
    return '${secondary.value}$secondaryUnit ${secondary.label}';
  }

  Widget _buildExpandedBody(Domain d, ThemeTokens ft) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Divider(color: ft.divider, thickness: 1, height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < widget.stats.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: ft.divider,
                ),
              Expanded(
                child: StatCell(
                  value: widget.stats[i].value,
                  label: widget.stats[i].label,
                  unit: widget.stats[i].unit,
                  color:
                      i == 0 ? d.color : ft.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
        if (!widget.showProgress && widget.progress != null) ...[
          const SizedBox(height: 10),
          _buildProgressBar(d),
          if (widget.stats.length >= 2) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.stats[0].value} / ${widget.stats[1].value}'
                  '${widget.stats[1].unit != null ? ' ${widget.stats[1].unit}' : ''}',
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    color: ft.onSurfaceFaint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(widget.progress!.clamp(0.0, 9.9) * 100).round()}%',
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    color: ft.onSurfaceFaint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
        ...widget.children,
      ],
    );
  }

  Widget _buildProgressBar(Domain d) {
    return ProgressBar(
      value: widget.progress!,
      color: d.color,
      glow: d.glow,
    );
  }
}

class _XpPill extends StatelessWidget {
  final String label;
  const _XpPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ft.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: ft.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: ft.sleep.color,
        ),
      ),
    );
  }
}

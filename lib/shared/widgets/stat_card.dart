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

class StatCard extends StatefulWidget {
  final String icon;
  final String label;
  final Domain domain;
  final List<StatStat> stats;
  final double? progress;
  final String? badge;
  final bool trophy;
  final String? xp;
  final XpClaimPillData? xpData;
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
    this.xp,
    this.xpData,
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
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(d, ft),
            const SizedBox(height: 10),
            _buildCompactBody(d, ft),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child:
                    _open ? _buildExpandedBody(d, ft) : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Domain d, ThemeTokens ft) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: d.dim,
            borderRadius: BorderRadius.circular(Tokens.radiusIcon),
            border: Border.all(color: d.color.withValues(alpha: 0.27)),
          ),
          child: Center(
            child: Text(widget.icon, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ft.onSurface,
            ),
          ),
        ),
        if (widget.badge != null) ...[
          _BadgePill(label: widget.badge!, color: d.color, bg: d.dim),
          const SizedBox(width: 6),
        ],
        if (widget.trophy) ...[
          const Text('🏆', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
        ],
        if (widget.xpData != null) ...[
          XpClaimPill(data: widget.xpData!),
          const SizedBox(width: 6),
        ] else if (widget.xp != null) ...[
          _XpPill(label: widget.xp!),
          const SizedBox(width: 6),
        ],
        if (widget.collapsible)
          ExpandChevron(expanded: _open),
      ],
    );
  }

  Widget _buildCompactBody(Domain d, ThemeTokens ft) {
    final primary = widget.stats.isNotEmpty ? widget.stats[0] : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                primary.value,
                style: TextStyle(
                  fontSize: 28,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: d.color.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                primary.label.toUpperCase(),
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: ft.onSurfaceMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        if (widget.progress != null) ...[
          const SizedBox(height: Tokens.spaceSm),
          if (!_open) _buildProgressBar(d),
        ],
      ],
    );
  }

  Widget _buildExpandedBody(Domain d, ThemeTokens ft) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
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
        if (widget.progress != null) ...[
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

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _BadgePill(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.33)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Tokens.fontSizeCaption,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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

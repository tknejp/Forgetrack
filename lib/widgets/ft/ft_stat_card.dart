import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';
import 'ft_progress_bar.dart';
import 'ft_stat_cell.dart';

class FtStatStat {
  final String value;
  final String label;
  final String? unit;

  const FtStatStat({
    required this.value,
    required this.label,
    this.unit,
  });
}

class FtStatCard extends StatefulWidget {
  final String icon;
  final String label;
  final FtDomain domain;
  final List<FtStatStat> stats;
  final double? progress;
  final String? badge;
  final bool trophy;
  final String? xp;
  final List<Widget> children;
  final bool initiallyExpanded;

  const FtStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.domain,
    required this.stats,
    this.progress,
    this.badge,
    this.trophy = false,
    this.xp,
    this.children = const [],
    this.initiallyExpanded = false,
  });

  @override
  State<FtStatCard> createState() => _FtStatCardState();
}

class _FtStatCardState extends State<FtStatCard> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.domain;
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        decoration: d.cardDecoration(),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(d),
            const SizedBox(height: 10),
            _buildCompactBody(d),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _open ? _buildExpandedBody(d) : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FtDomain d) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: d.dim,
            borderRadius: BorderRadius.circular(FtTokens.radiusIcon),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: FtTokens.onSurface,
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
        if (widget.xp != null) ...[
          _XpPill(label: widget.xp!),
          const SizedBox(width: 6),
        ],
        AnimatedRotation(
          turns: _open ? 0 : -0.25,
          duration: const Duration(milliseconds: 220),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0x66FFFFFF),
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBody(FtDomain d) {
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
                const SizedBox(width: 4),
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
                style: const TextStyle(
                  fontSize: FtTokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: FtTokens.onSurfaceMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        if (widget.progress != null) ...[
          const SizedBox(height: 8),
          if (!_open) _buildProgressBar(d),
        ],
      ],
    );
  }

  Widget _buildExpandedBody(FtDomain d) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        const Divider(color: Color(0x12FFFFFF), thickness: 1, height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < widget.stats.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: const Color(0x12FFFFFF),
                ),
              Expanded(
                child: FtStatCell(
                  value: widget.stats[i].value,
                  label: widget.stats[i].label,
                  unit: widget.stats[i].unit,
                  color: i == 0 ? d.color : const Color(0xD9FFFFFF),
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
                  style: const TextStyle(
                    fontSize: FtTokens.fontSizeMicro,
                    color: FtTokens.onSurfaceFaint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(widget.progress!.clamp(0.0, 9.9) * 100).round()}%',
                  style: const TextStyle(
                    fontSize: FtTokens.fontSizeMicro,
                    color: FtTokens.onSurfaceFaint,
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

  Widget _buildProgressBar(FtDomain d) {
    return FtProgressBar(
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
  const _BadgePill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.33)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: FtTokens.fontSizeCaption,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x2E7C6FFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x597C6FFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: FtTokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: Color(0xFFA89BFF),
        ),
      ),
    );
  }
}

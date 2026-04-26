import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/progression_models.dart';
import 'ft_progression_domain_theme.dart';

/// Square domain tile with a Material icon (the handoff's `DomIco`).
class FtProgDomIco extends StatelessWidget {
  const FtProgDomIco({
    super.key,
    required this.domain,
    this.size = 26,
  });

  final ProgressionDomain domain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final token = FtProgressionDomainTheme.tokenFor(domain);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: token.dim,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: token.color.withValues(alpha: 0.28)),
      ),
      child: Icon(
        FtProgressionDomainTheme.iconFor(domain),
        color: token.color,
        size: size * 0.55,
      ),
    );
  }
}

/// Pill-shaped label used for `Active`, `Completed`, `Unlocked` badges.
class FtProgTinyPill extends StatelessWidget {
  const FtProgTinyPill({
    super.key,
    required this.label,
    required this.color,
  });

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
          fontSize: FtTokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Section header with a small accent star, uppercase label and caption.
class FtProgSectionHead extends StatelessWidget {
  const FtProgSectionHead({
    super.key,
    required this.label,
    required this.accent,
    this.caption,
  });

  final String label;
  final Color accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 1.1,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    fontSize: FtTokens.fontSizeCaption,
                    color: FtTokens.onSurfaceFaint,
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

/// Two-up streak cards (aktuální / nejlepší). Used by home card + profile.
class FtProgStreakDuel extends StatelessWidget {
  const FtProgStreakDuel({
    super.key,
    required this.currentLabel,
    required this.currentValue,
    required this.currentCaption,
    required this.currentDomain,
    required this.bestLabel,
    required this.bestValue,
    required this.bestCaption,
    required this.bestDomain,
    required this.daysSuffix,
    this.valueSize = 24,
    this.currentColor,
    this.currentDim,
    this.currentGlow,
    this.bestColor,
    this.bestDim,
    this.bestGlow,
  });

  final String currentLabel;
  final int currentValue;
  final String currentCaption;
  final ProgressionDomain? currentDomain;

  final String bestLabel;
  final int bestValue;
  final String bestCaption;
  final ProgressionDomain? bestDomain;

  final String daysSuffix;
  final double valueSize;
  final Color? currentColor;
  final Color? currentDim;
  final Color? currentGlow;
  final Color? bestColor;
  final Color? bestDim;
  final Color? bestGlow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StreakCard(
            label: currentLabel,
            value: currentValue,
            caption: currentCaption,
            daysSuffix: daysSuffix,
            color: currentColor ?? FtTokens.active.color,
            dim: currentDim ?? FtTokens.active.dim,
            glow: currentGlow ?? FtTokens.active.glow,
            domain: currentDomain,
            valueSize: valueSize,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StreakCard(
            label: bestLabel,
            value: bestValue,
            caption: bestCaption,
            daysSuffix: daysSuffix,
            color: bestColor ?? FtTokens.calories.color,
            dim: bestDim ?? FtTokens.calories.dim,
            glow: bestGlow ?? FtTokens.calories.glow,
            domain: bestDomain,
            valueSize: valueSize,
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.daysSuffix,
    required this.color,
    required this.dim,
    required this.glow,
    required this.domain,
    required this.valueSize,
  });

  final String label;
  final int value;
  final String caption;
  final String daysSuffix;
  final Color color;
  final Color dim;
  final Color glow;
  final ProgressionDomain? domain;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [dim, Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: glow, blurRadius: 14, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (domain != null) ...[
                FtProgDomIco(domain: domain!, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  daysSuffix,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            caption.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.55),
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

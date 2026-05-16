import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'progress_bar.dart';
import 'xp_claim_pill.dart';

class MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Domain domain;
  final bool isLast;

  /// Per-macro daily-goal claim affordance. Each macro
  /// (`daily_protein_today` / `daily_carbs_today` / `daily_fat_today` /
  /// `daily_fiber_today`) is its own daily goal with its own XP reward;
  /// the pill goes here so the player can claim straight from the row
  /// where they read the value, without having to chase down a quests
  /// screen.
  final XpClaimPillData? xpData;

  /// Label shown on the pill once a claim has landed (e.g. localized
  /// "Vyzvednuto"). Optional — defaults to the bare "+N XP".
  final String? claimedXpLabel;

  const MacroRow({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.domain,
    this.isLast = false,
    this.xpData,
    this.claimedXpLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final over = value > goal;
    final barColor = over ? ft.danger : domain.color;
    final barGlow = over ? ft.danger.withValues(alpha: 0.30) : domain.glow;

    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: ft.divider)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ft.onSurface.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  fontSize: Tokens.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                  color: over ? barColor : ft.onSurfaceMuted,
                ),
              ),
              if (xpData != null) ...[
                const SizedBox(width: 8),
                XpClaimPill(
                  data: xpData!,
                  claimedLabel: claimedXpLabel,
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          ProgressBar(
            value: (value / goal).clamp(0.0, 1.3),
            color: barColor,
            glow: barGlow,
            height: 5,
          ),
        ],
      ),
    );
  }
}

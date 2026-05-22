import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_catalog.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/cosmetic_reveal_state.dart';
import '../cosmetics_screen_internals.dart' show cosmeticRarityColor;
import 'cosmetic_asset_thumb.dart';

/// Renders the companion's unlock requirements as a horizontal row of
/// tiles: a level badge on the left + one tile per `OwnsCosmetic`
/// gate (typically two relics) on the right.
class CompanionChecklist extends StatelessWidget {
  const CompanionChecklist({
    super.key,
    required this.conditionRows,
    required this.color,
    required this.l10n,
    required this.onOpenRelic,
  });

  final List<CosmeticRevealConditionRow> conditionRows;
  final Color color;
  final AppLocalizations l10n;

  /// Tap handler for a relic-gate tile — opens that relic's own
  /// [CosmeticDetailsSheet] on top of the current modal. The screen
  /// owns the sheet construction so this widget doesn't need to import
  /// the sheet (avoids a circular import).
  final void Function(BuildContext context, Cosmetic relic) onOpenRelic;

  static const _levelPrefix = 'level_at_least_';
  static const _ownsPrefix = 'owns_';

  @override
  Widget build(BuildContext context) {
    CosmeticRevealConditionRow? levelRow;
    int? levelTarget;
    final relicRows = <CosmeticRevealConditionRow>[];
    final otherRows = <CosmeticRevealConditionRow>[];
    for (final row in conditionRows) {
      final id = row.conditionId;
      if (id.startsWith(_levelPrefix)) {
        levelRow = row;
        levelTarget = int.tryParse(id.substring(_levelPrefix.length));
      } else if (id.startsWith(_ownsPrefix)) {
        relicRows.add(row);
      } else {
        otherRows.add(row);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rounded,
                size: 13, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 5),
            Text(
              l10n.cosmeticRequirementsHeader,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (levelRow != null && levelTarget != null)
                Expanded(
                  child: _LevelGateTile(
                    level: levelTarget,
                    met: levelRow.met,
                    color: color,
                    l10n: l10n,
                  ),
                ),
              for (final row in relicRows) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _RelicGateTile(
                    conditionRow: row,
                    color: color,
                    l10n: l10n,
                    onOpenRelic: onOpenRelic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (otherRows.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final row in otherRows)
            _LegacyTextRow(row: row, color: color, l10n: l10n),
        ],
      ],
    );
  }
}

class _LevelGateTile extends StatelessWidget {
  const _LevelGateTile({
    required this.level,
    required this.met,
    required this.color,
    required this.l10n,
  });

  final int level;
  final bool met;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final accent = met ? color : Tokens.onSurfaceMuted;
    final alpha = met ? 0.9 : 0.55;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.workspace_premium_rounded : Icons.lock_rounded,
            size: 26,
            color: accent.withValues(alpha: alpha),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.cosmeticCompanionLevelBadge(level),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent.withValues(alpha: alpha),
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelicGateTile extends StatelessWidget {
  const _RelicGateTile({
    required this.conditionRow,
    required this.color,
    required this.l10n,
    required this.onOpenRelic,
  });

  final CosmeticRevealConditionRow conditionRow;
  final Color color;
  final AppLocalizations l10n;
  final void Function(BuildContext, Cosmetic) onOpenRelic;

  static const _ownsPrefix = 'owns_';
  static const _catalog = CosmeticCatalog();

  @override
  Widget build(BuildContext context) {
    final met = conditionRow.met;
    final relicId =
        conditionRow.conditionId.substring(_ownsPrefix.length);
    final relic = _catalog.byId(relicId);
    final relicColor =
        relic == null ? color : cosmeticRarityColor(relic.rarity);
    final accent = relicColor;
    final alpha = met ? 0.9 : 0.55;
    final label = relic == null
        ? conditionRow.conditionId
        : relic.name(l10n);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: relic == null ? null : () => onOpenRelic(context, relic),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CosmeticAssetThumb(
              cosmeticId: relicId,
              size: 44,
              dimmed: !met,
              fallbackColor: accent,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent.withValues(alpha: alpha),
                fontSize: Tokens.fontSizeTiny,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyTextRow extends StatelessWidget {
  const _LegacyTextRow({
    required this.row,
    required this.color,
    required this.l10n,
  });

  final CosmeticRevealConditionRow row;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final metColor = row.met ? color : Tokens.onSurfaceMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            row.met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: metColor.withValues(alpha: row.met ? 0.9 : 0.45),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              row.conditionId.replaceAll('_', ' '),
              style: TextStyle(
                color: metColor.withValues(alpha: row.met ? 0.9 : 0.6),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


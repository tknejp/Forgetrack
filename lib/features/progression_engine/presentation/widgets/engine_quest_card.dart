import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../../progression/domain/models/core_models.dart';
import '../../../progression/presentation/widgets/progression_primitives.dart';
import '../../application/progression_engine_provider.dart';

/// One quest card in the V2 quests screen.
///
/// Layout: domain icon · title + description · XP pill (locked /
/// claimable / claimed) · progress bar with actual/target text. The
/// XP pill switches state via [EngineQuestProgress.isCompleted] /
/// [EngineQuestProgress.isAvailableForClaim] and triggers the [onClaim]
/// callback (with the pill centre offset so the parent can launch a
/// sparkle).
///
/// Stateless — the parent owns the claim flow and the pill key for the
/// sparkle target.
class EngineQuestCard extends StatelessWidget {
  const EngineQuestCard({
    super.key,
    required this.quest,
    required this.l10n,
    required this.enabled,
    required this.pillKey,
    required this.onClaim,
  });

  final EngineQuestProgress quest;
  final AppLocalizations l10n;

  /// False while a refresh / claim is in flight — disables the pill.
  final bool enabled;

  /// Key used by the parent's sparkle launcher to target this pill.
  final GlobalKey pillKey;

  /// Fired when the player taps the claimable pill. The parent reads
  /// the pill centre via [pillKey] and triggers [ProgressionEngineProvider.claimNode].
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;

  @override
  Widget build(BuildContext context) {
    final domain = quest.domain ?? ProgressionDomain.steps;
    final accent = domain.color;

    return Container(
      padding: const EdgeInsets.all(Tokens.questCardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF111423),
        borderRadius: BorderRadius.circular(Tokens.questCardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgDomIco(domain: domain, size: 32),
              const SizedBox(width: Tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.node.titleKey(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quest.node.descriptionKey(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.spaceSm),
              XpClaimPill(
                key: pillKey,
                data: _pillData(),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceSm),
          _ProgressRow(quest: quest, accent: accent),
        ],
      ),
    );
  }

  XpClaimPillData _pillData() {
    if (quest.isCompleted) {
      // After a successful claim the ledger has the actually-granted
      // XP; the pill mirrors V1 (greyed-out check + final XP value).
      return XpClaimPillData.claimed(quest.previewXp);
    }
    if (quest.isAvailableForClaim && enabled) {
      return XpClaimPillData.claimable(
        quest.previewXp,
        onTap: (center) => onClaim(quest, from: center),
      );
    }
    // Either the objective isn't satisfied yet, or a refresh/claim is
    // in flight — show the locked pill with the would-be XP.
    return XpClaimPillData.locked(quest.previewXp);
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.quest, required this.accent});

  final EngineQuestProgress quest;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final pct = (quest.progress * 100).clamp(0, 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _progressLabel(locale),
                style: const TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: Tokens.onSurfaceMuted,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w800,
                color: accent.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(
          value: quest.progress,
          color: accent,
          glow: accent.withValues(alpha: 0.34),
        ),
      ],
    );
  }

  String _progressLabel(String locale) {
    final actual = _formatNumber(quest.actualValue, locale);
    final target = _formatNumber(quest.targetValue, locale);
    return '$actual / $target';
  }

  String _formatNumber(double value, String locale) {
    final safe = value.isFinite ? value : 0;
    final isWhole = safe.truncateToDouble() == safe;
    if (isWhole) {
      return NumberFormat.decimalPattern(locale).format(safe.toInt());
    }
    return safe.toStringAsFixed(1);
  }
}

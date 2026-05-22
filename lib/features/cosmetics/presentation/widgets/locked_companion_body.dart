import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/player_cosmetic_lifecycle.dart';
import '../cosmetics_screen_internals.dart' show cosmeticRarityColor;
import 'companion_checklist.dart';
import 'hidden_badge_large.dart';
import 'tiny_pill.dart';

/// Body shown for `hidden` or `partial` companions. Identity stays
/// concealed (silhouette + mystery name) per the four-state spec.
class LockedCompanionBody extends StatelessWidget {
  const LockedCompanionBody({
    super.key,
    required this.definition,
    required this.teased,
    required this.l10n,
    required this.bottomPad,
    required this.onOpenRelic,
  });

  final Cosmetic definition;
  final CosmeticTeased? teased;
  final AppLocalizations l10n;
  final double bottomPad;
  final void Function(BuildContext, Cosmetic) onOpenRelic;

  @override
  Widget build(BuildContext context) {
    final color = cosmeticRarityColor(definition.rarity);
    final hiddenColor = Tokens.onSurfaceMuted;
    final satisfied =
        teased?.hasProgress == true ? teased!.satisfiedConditions : null;
    final total =
        teased?.hasProgress == true ? teased!.totalConditions : null;
    final rows = teased?.conditionRows;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(26)),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SingleChildScrollView(
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
                    borderRadius:
                        BorderRadius.circular(Tokens.radiusProgress),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HiddenBadgeLarge(color: hiddenColor),
                  const SizedBox(width: Tokens.spaceLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cosmeticCompanionClaimableHiddenName,
                          style: const TextStyle(
                            color: Tokens.onSurfaceMuted,
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
                            TinyPill(
                              label: l10n.journeyBadgeLocked,
                              color: hiddenColor.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                        if (satisfied != null && total != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.incomplete_circle_rounded,
                                size: 13,
                                color: color.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.cosmeticPartialProgress(
                                    satisfied, total),
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.8),
                                  fontSize: Tokens.fontSizeCaption,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (rows != null && rows.isNotEmpty) ...[
                const SizedBox(height: 18),
                CompanionChecklist(
                  conditionRows: rows,
                  color: color,
                  l10n: l10n,
                  onOpenRelic: onOpenRelic,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 13,
                    color: Tokens.onSurfaceFaint.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      l10n.cosmeticHiddenUnlockCondition,
                      style: TextStyle(
                        color: Tokens.onSurfaceFaint.withValues(alpha: 0.7),
                        fontSize: Tokens.fontSizeCaption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hiddenColor,
                    side: BorderSide(
                      color: hiddenColor.withValues(alpha: 0.34),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Tokens.radiusInner),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  child: Text(l10n.dialogClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

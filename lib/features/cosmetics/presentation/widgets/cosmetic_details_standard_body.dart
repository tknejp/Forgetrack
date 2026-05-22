import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/cosmetic_reveal_state.dart';
import '../../domain/cosmetic_unlock_rule.dart';
import '../../domain/player_cosmetic_lifecycle.dart';
import 'companion_buff_chip.dart';
import 'companion_checklist.dart';
import 'cosmetic_details_actions.dart';
import 'cosmetic_details_header.dart';
import 'debug_details_section.dart';
import 'emblem_buff_banner.dart';
import 'unlock_conditions_section.dart';

/// Standard scrollable layout for the cosmetic details sheet — the
/// non-companion / unlocked / devtools path. Receives all state and
/// callbacks from the owning sheet so it stays a pure stateless widget.
class CosmeticDetailsStandardBody extends StatelessWidget {
  const CosmeticDetailsStandardBody({
    super.key,
    required this.definition,
    required this.l10n,
    required this.color,
    required this.assetPath,
    required this.description,
    required this.unlock,
    required this.bottomPad,
    required this.isLocked,
    required this.devTools,
    required this.devToolsUnlockRules,
    required this.isRelicConsumed,
    required this.revealResult,
    required this.teased,
    required this.isHidden,
    required this.isPartial,
    required this.isVisibleLocked,
    required this.effectiveLocked,
    required this.isEquipped,
    required this.displayName,
    required this.hiddenColor,
    required this.companionSlotKey,
    required this.hideCompanion,
    required this.equipBusy,
    required this.devBusy,
    required this.anyBusy,
    required this.onToggleEquipped,
    required this.onDevGrant,
    required this.onDevRevoke,
    required this.onOpenRelic,
  });

  final Cosmetic definition;
  final AppLocalizations l10n;
  final Color color;
  final String? assetPath;
  final String description;
  final UnlockedCosmetic? unlock;
  final double bottomPad;
  final bool isLocked;
  final bool devTools;
  final List<CosmeticUnlockRule>? devToolsUnlockRules;
  final bool isRelicConsumed;
  final CosmeticRevealResult? revealResult;
  final CosmeticTeased? teased;
  final bool isHidden;
  final bool isPartial;
  final bool isVisibleLocked;
  final bool effectiveLocked;
  final bool isEquipped;
  final String displayName;
  final Color hiddenColor;
  final GlobalKey companionSlotKey;
  final ValueNotifier<bool> hideCompanion;
  final bool equipBusy;
  final bool devBusy;
  final bool anyBusy;
  final VoidCallback onToggleEquipped;
  final VoidCallback onDevGrant;
  final VoidCallback onDevRevoke;
  final void Function(BuildContext, Cosmetic) onOpenRelic;

  @override
  Widget build(BuildContext context) {
    final rules = devToolsUnlockRules;
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
              // drag handle
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

              CosmeticDetailsHeader(
                definition: definition,
                l10n: l10n,
                color: color,
                hiddenColor: hiddenColor,
                displayName: displayName,
                assetPath: assetPath,
                isHidden: isHidden,
                isEquipped: isEquipped,
                effectiveLocked: effectiveLocked,
                isLocked: isLocked,
                devTools: devTools,
                isRelicConsumed: isRelicConsumed,
                isPartial: isPartial,
                teased: teased,
                companionSlotKey: companionSlotKey,
                hideCompanion: hideCompanion,
              ),

              // description
              if (!isHidden && description.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  description,
                  style: const TextStyle(
                    color: Tokens.onSurfaceMuted,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Companion XP buff
              if (!devTools &&
                  !isHidden &&
                  !effectiveLocked &&
                  definition is Companion &&
                  (definition as Companion).buff != null) ...[
                const SizedBox(height: 14),
                CompanionBuffBanner(
                  buff: (definition as Companion).buff!,
                  currentChapterChainPosition:
                      (definition as Companion).buff is ChapterDepthCompanionBuff
                          ? context
                              .watch<ProgressionEngineProvider>()
                              .currentChapterChainPosition
                          : null,
                ),
              ],

              // Emblem XP buff
              if (!devTools &&
                  !isHidden &&
                  !effectiveLocked &&
                  definition is Emblem &&
                  (definition as Emblem).buff != null) ...[
                const SizedBox(height: 14),
                EmblemBuffBanner(buff: (definition as Emblem).buff!),
              ],

              // companion requirements checklist
              if (!devTools &&
                  !isHidden &&
                  definition is Companion &&
                  revealResult?.conditionRows != null) ...[
                const SizedBox(height: 18),
                CompanionChecklist(
                  conditionRows: revealResult!.conditionRows!,
                  color: color,
                  l10n: l10n,
                  onOpenRelic: onOpenRelic,
                ),
              ],

              // unlock info (unlocked items)
              if (unlock != null) ...[
                const SizedBox(height: 14),
                Text(
                  l10n.cosmeticUnlockedAt(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(unlock!.unlockedAt),
                  ),
                  style: TextStyle(
                    color: color.withValues(alpha: 0.78),
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],

              // hidden mystery hint
              if (isHidden) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.help_outline_rounded,
                        size: 13,
                        color: Tokens.onSurfaceFaint.withValues(alpha: 0.6)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.cosmeticHiddenUnlockCondition,
                        style: TextStyle(
                          color: Tokens.onSurfaceFaint.withValues(alpha: 0.6),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // visible-locked unlock hint
              if ((isVisibleLocked || isPartial) &&
                  definition.unlockHint != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13, color: color.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        definition.unlockHint!(l10n),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // consumed relic flavor line
              if (isRelicConsumed) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 13, color: Tokens.onSurfaceMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.cosmeticRelicConsumedHint,
                        style: const TextStyle(
                          color: Tokens.onSurfaceMuted,
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // unlocked items: how this was earned
              if (!isHidden &&
                  !effectiveLocked &&
                  !devTools &&
                  definition.unlockHint != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star_border_rounded,
                        size: 13, color: color.withValues(alpha: 0.55)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        definition.unlockHint!(l10n),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.55),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // devTools: always show the player-facing unlock hint
              if (devTools && definition.unlockHint != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13, color: color.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        definition.unlockHint!(l10n),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // unlock conditions (devtools)
              if (rules != null && rules.isNotEmpty) ...[
                const SizedBox(height: 18),
                UnlockConditionsSection(rules: rules, color: color),
              ],

              // debug details section
              if (devTools) ...[
                const SizedBox(height: 18),
                DebugDetailsSection(
                  definition: definition,
                  unlock: unlock,
                  color: color,
                ),
              ],

              const SizedBox(height: 20),

              CosmeticDetailsActions(
                definition: definition,
                l10n: l10n,
                color: color,
                isHidden: isHidden,
                isLocked: isLocked,
                devTools: devTools,
                isEquipped: isEquipped,
                effectiveLocked: effectiveLocked,
                anyBusy: anyBusy,
                equipBusy: equipBusy,
                devBusy: devBusy,
                onToggleEquipped: onToggleEquipped,
                onDevGrant: onDevGrant,
                onDevRevoke: onDevRevoke,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/catalog/progression_node_catalog.dart';

/// Compact "next chapter is coming" tile rendered at the tail of the
/// JOURNEY section. Shows the chapter's icon (greyed), title, and a
/// single hint line — no chain dots, no rewards, no XP pill. The
/// player learns *what* is next and *when* it unlocks without seeing
/// the actual chapter content yet.
class NextChapterLockedTeaser extends StatelessWidget {
  const NextChapterLockedTeaser({
    super.key,
    required this.quest,
    required this.l10n,
  });

  final EngineQuestProgress quest;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final node = quest.node;
    final asset = node.assetKey;
    final level = quest.levelGate;
    final prereqId = quest.prereqGateNodeId;
    // Prefer the prereq hint (= "Dokonči [previous chapter finale]")
    // when the chapter is gated by a cross-chapter NodeCompleted
    // condition rather than a level threshold. Mirrors
    // `EngineLockedQuestRow._resolveSubtitle`. Falls back to the level
    // hint, then to a generic "soon" copy so the teaser never reads
    // as the empty-locked-section title (Trello #66 follow-up — the
    // old fallback to `progQuestsEmptyLockedTitle` rendered as "Teď
    // tu nejsou žádné zamčené questy", which is a section header, not
    // a per-chapter caption).
    String? prereqTitle;
    if (prereqId != null) {
      final node = ProgressionEntryCatalog.definitionForId(prereqId);
      prereqTitle = switch (node) {
        Quest(:final titleKey) => titleKey(l10n),
        Achievement(:final titleKey) => titleKey(l10n),
        Milestone(:final titleKey) => titleKey(l10n),
        LevelMilestone(:final titleKey) => titleKey(l10n),
        _ => null,
      };
    }
    final String hint;
    if (prereqTitle != null && prereqTitle.isNotEmpty) {
      hint = l10n.progQuestDetailCompleteQuest(prereqTitle);
    } else if (level != null) {
      hint = l10n.progChapterLockedLabel(level);
    } else {
      hint = l10n.progChapterLockedSoon;
    }

    return Container(
      padding: const EdgeInsets.all(Tokens.questCardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF111423),
        borderRadius: BorderRadius.circular(Tokens.questCardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (asset != null && asset.isNotEmpty)
            // RepaintBoundary so the greyscale ColorFiltered output is
            // cached as a raster layer. Without it, every frame of the
            // outer PageView swipe re-evaluates the per-pixel matrix
            // multiply for each locked chapter teaser (4× × ~13 ms in
            // the 2026-05-22 trace).
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    // Greyscale matrix — chapter art is decorative until
                    // the player unlocks it.
                    0.33, 0.33, 0.33, 0, 0,
                    0.33, 0.33, 0.33, 0, 0,
                    0.33, 0.33, 0.33, 0, 0,
                    0, 0, 0, 0.55, 0,
                  ]),
                  child: Image.asset(asset,
                      width: 44, height: 44, fit: BoxFit.cover),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white, size: 22),
            ),
          const SizedBox(width: Tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.titleKey(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

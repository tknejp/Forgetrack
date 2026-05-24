import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_map_layout.dart';
import 'journey_primitives.dart';

class JourneyCheckpointOverlayCard extends StatelessWidget {
  const JourneyCheckpointOverlayCard({
    super.key,
    required this.checkpoint,
    this.onClose,
    this.maxWidth,
  });

  final JourneyCheckpoint checkpoint;
  final VoidCallback? onClose;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cp = checkpoint;
    final color = journeyCheckpointColor(cp);
    final locale = Localizations.localeOf(context).toString();
    final dateStr = cp.unlockedAt != null
        ? DateFormat('d. MMM yyyy', locale).format(cp.unlockedAt!)
        : null;

    final card = Container(
      padding: JourneyMapTooltipStyle.padding,
      decoration: BoxDecoration(
        color: JourneyMapTooltipStyle.cardColor,
        borderRadius: BorderRadius.circular(JourneyMapTooltipStyle.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _typeLabelL10n(l10n, cp.type),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (cp.achievementDifficultyLabel != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    cp.achievementDifficultyLabel!,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: color.withValues(alpha: 0.92),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              if (cp.isCurrent) ...[
                const SizedBox(width: 5),
                const _CurrentDot(),
              ],
              if (!cp.isUnlocked) ...[
                const SizedBox(width: 5),
                const Icon(Icons.lock_outline_rounded,
                    size: 10, color: Tokens.onSurfaceFaint),
                const SizedBox(width: 2),
                Text(
                  l10n.journeyBadgeLocked,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Tokens.onSurfaceMuted,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
              const Spacer(),
              if (onClose != null) _CloseButton(color: color, onTap: onClose!),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: JourneyMapTooltipStyle.iconBoxSize,
                  height: JourneyMapTooltipStyle.iconBoxSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withValues(alpha: 0.32)),
                  ),
                  child: Center(
                    child: _emojiOrIcon(
                      cp,
                      color,
                      JourneyMapTooltipStyle.iconSize,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cp.isUnlocked
                            ? cp.label
                            : l10n.journeyLevelLabel(cp.levelNumber ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (cp.sublabel != null || dateStr != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _composeSubtitle(cp.sublabel, dateStr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Tokens.fontSizeMicro,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (cp.description != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                cp.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: Tokens.fontSizeCaption,
                  height: 1.4,
                  color: Tokens.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedSwitcher(
      duration: JourneyMapMotion.overlaySwitchDuration,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: JourneyMapMotion.overlayScaleBegin,
            end: 1.0,
          ).animate(anim),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(cp.id),
        child: maxWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: card,
              )
            : card,
      ),
    );
  }

  static String _composeSubtitle(String? sublabel, String? date) {
    if (sublabel != null && date != null) return '$sublabel · $date';
    return sublabel ?? date ?? '';
  }

  Widget _emojiOrIcon(JourneyCheckpoint cp, Color color, double size) {
    if (!cp.isUnlocked) {
      return Icon(Icons.lock_outline_rounded,
          size: size - 2, color: Tokens.onSurfaceFaint);
    }
    if (cp.emoji != null) {
      return Text(
        cp.emoji!,
        style: TextStyle(fontSize: size, height: 1),
      );
    }
    return Icon(journeyIcon(cp.type), size: size, color: color);
  }
}

String _typeLabelL10n(AppLocalizations l10n, JourneyEventType type) {
  switch (type) {
    // Title breakpoints intentionally show as "LEVEL" (not "TITUL"): the
    // unified UI bucket is Levely; the title is already inside the label
    // ("Level 10 · Pathfinder"), so a separate "TITUL" pill would just
    // duplicate that information.
    case JourneyEventType.titleMilestone:
    case JourneyEventType.level:
      return l10n.journeyTypeLevel;
    case JourneyEventType.achievement:
      return l10n.journeyTypeAchievement;
    case JourneyEventType.quest:
      return l10n.journeyTypeQuest;
    case JourneyEventType.streak:
    case JourneyEventType.xpMilestone:
      return l10n.journeyTypeLevel;
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 14,
            color: Tokens.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _CurrentDot extends StatelessWidget {
  const _CurrentDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Tokens.accent,
        boxShadow: [
          BoxShadow(
            color: Tokens.accent.withValues(alpha: 0.8),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

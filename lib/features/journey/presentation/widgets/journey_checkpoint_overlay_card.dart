import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/player/level_curve.dart';
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
    final isLevelType = cp.type == JourneyEventType.level ||
        cp.type == JourneyEventType.titleMilestone;

    // Layout split: level / titleMilestone tooltips put the level
    // number in the pill, the RPG title next to the icon and a
    // dedicated "Level dosažen · DATE" line ("Začátek cesty · DATE"
    // for the level-1 origin). Achievement / quest tooltips keep the
    // unified label + sublabel + date logic so their bespoke
    // descriptors (difficulty pill, custom sublabels) still render.
    String? titleText;
    String? subtitleText;
    if (isLevelType) {
      // Locked level nodes hide the RPG title to avoid spoilers and
      // surface a generic "Zamčeno" / "Locked" line next to the lock
      // icon instead — the level number already lives in the pill.
      titleText = cp.isUnlocked ? cp.title : l10n.journeyLockedTitle;
      if (cp.isUnlocked) {
        final prefix = cp.id == 'start'
            ? l10n.journeyStartLabel
            : l10n.journeyEventLevelReached;
        subtitleText = dateStr != null ? '$prefix · $dateStr' : prefix;
      } else if (cp.levelNumber != null) {
        // Locked → orient the player by stating the XP they still need
        // to reach this milestone. `LevelCurve` is a pure VO; the
        // const ctor keeps the lookup allocation-free.
        const curve = LevelCurve();
        final xp = curve.xpRequiredForLevel(cp.levelNumber!);
        subtitleText = l10n.journeyRequiredXp(xp);
      }
    } else {
      titleText = cp.isUnlocked
          ? cp.label
          : l10n.journeyLevelLabel(cp.levelNumber ?? 0);
      if (cp.sublabel != null || dateStr != null) {
        subtitleText = _composeSubtitle(cp.sublabel, dateStr);
      }
    }

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
                  _typeLabelL10n(l10n, cp),
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
              // The "ZAMČENO" badge previously rendered here moved into
              // the title row (next to the lock icon) for level types;
              // achievement / quest tooltips keep using their custom
              // sublabel for that signal.
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
                      if (titleText != null)
                        Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            // Locked level tooltips render the generic
                            // "Zamčeno" placeholder; tone it down so it
                            // doesn't compete with the (still
                            // attention-worthy) "potřebné XP" line
                            // directly underneath it.
                            color: (isLevelType && !cp.isUnlocked)
                                ? Colors.white.withValues(alpha: 0.45)
                                : Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      if (subtitleText != null) ...[
                        if (titleText != null) const SizedBox(height: 2),
                        Text(
                          subtitleText,
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
          if (cp.rewardLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            _RewardChipsRow(
              labels: cp.rewardLabels,
              color: color,
              locked: !cp.isUnlocked,
              lockedLabel: l10n.journeyRewardLockedLabel,
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

String _typeLabelL10n(AppLocalizations l10n, JourneyCheckpoint cp) {
  switch (cp.type) {
    // Both level + titleMilestone show as "LEVEL N" — the unified
    // tooltip layout puts the level number into the pill and reserves
    // the body's title row for the RPG title (Pathfinder, Poutník, …).
    // Title breakpoints intentionally don't get a separate "TITUL" pill
    // because the body already calls out the title in big text.
    case JourneyEventType.titleMilestone:
    case JourneyEventType.level:
      return cp.levelNumber != null
          ? '${l10n.journeyTypeLevel} ${cp.levelNumber}'
          : l10n.journeyTypeLevel;
    case JourneyEventType.achievement:
      return l10n.journeyTypeAchievement;
    case JourneyEventType.quest:
      return l10n.journeyTypeQuest;
    case JourneyEventType.streak:
    case JourneyEventType.xpMilestone:
      return l10n.journeyTypeLevel;
  }
}

/// Reward row that appears below the description when a checkpoint
/// has level-tied cosmetic rewards. For unlocked levels each chip
/// carries the localised cosmetic display name resolved by the
/// adapter. For locked levels the row collapses to a single
/// lock-icon + [lockedLabel] chip so the player sees a reward exists
/// at that level without spoiling the specific cosmetic name.
class _RewardChipsRow extends StatelessWidget {
  const _RewardChipsRow({
    required this.labels,
    required this.color,
    required this.locked,
    required this.lockedLabel,
  });

  final List<String> labels;
  final Color color;
  final bool locked;
  final String lockedLabel;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      // Muted palette: locked reward placeholders shouldn't steal
      // attention from the unlocked content above the chip row.
      final mutedFg = Colors.white.withValues(alpha: 0.55);
      return _RewardChip(
        icon: Icons.lock_outline_rounded,
        label: lockedLabel,
        fg: mutedFg,
        bgColor: Colors.white.withValues(alpha: 0.06),
        borderColor: Colors.white.withValues(alpha: 0.14),
      );
    }
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final label in labels)
          _RewardChip(
            icon: Icons.card_giftcard_rounded,
            label: label,
            fg: color.withValues(alpha: 0.92),
            bgColor: color.withValues(alpha: 0.12),
            borderColor: color.withValues(alpha: 0.30),
          ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bgColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
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

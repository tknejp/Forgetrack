import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../../../shared/widgets/xp_claim_pill.dart';
import '../../../domain/backfill/daily_backfill_models.dart';
import '../engine_quest_card.dart' show EngineQuestLeading;
import '../progression_primitives.dart';

/// Small typed wrapper so the row's claim handler doesn't have to
/// thread the whole [ActivityClaimState] all the way through —
/// callers only need the underlying record + identity for the sparkle
/// key.
class ActivityClaimRef {
  ActivityClaimRef(this.record);
  final dynamic record;
}

/// Compact backfill row for a daily-section quest offered on this
/// day. Smaller than [BackfillDailyGoalRow] — no value / target
/// column, just quest icon + title + pill — so the day card stays
/// readable when many goals + quests + activities stack up.
class BackfillDailyQuestRow extends StatelessWidget {
  const BackfillDailyQuestRow({
    super.key,
    required this.item,
    required this.day,
    required this.pillKey,
    required this.onClaim,
    required this.l10n,
  });

  final DailyQuestClaimItem item;
  final DateTime day;
  final GlobalKey pillKey;
  final Future<void> Function(
    DailyQuestClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaim;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = item.node.titleKey(l10n);

    return Row(
      children: [
        EngineQuestLeading(
          node: item.node,
          domain: item.domain,
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 6),
        KeyedSubtree(
          key: pillKey,
          child: XpClaimPill(
            data: item.isClaimed
                ? XpClaimPillData.claimed(item.previewXp)
                : item.isClaimable
                    ? XpClaimPillData.claimable(
                        item.previewXp,
                        onTap: (center) => onClaim(item, day, center),
                      )
                    : XpClaimPillData.locked(item.previewXp),
          ),
        ),
      ],
    );
  }
}

class BackfillDailyGoalRow extends StatelessWidget {
  const BackfillDailyGoalRow({
    super.key,
    required this.item,
    required this.day,
    required this.pillKey,
    required this.onClaim,
    required this.l10n,
  });

  final DailyGoalClaimItem item;
  final DateTime day;
  final GlobalKey pillKey;
  final Future<void> Function(
    DailyGoalClaimItem item,
    DateTime day,
    Offset? sparkleFrom,
  ) onClaim;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final title = item.node.titleKey(l10n);

    return Row(
      children: [
        ProgDomIco(domain: item.domain, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _valueLabel(item, l10n),
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w500,
                  color: ft.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _rowPill(context),
      ],
    );
  }

  Widget _rowPill(BuildContext context) {
    if (!item.hasData && !item.isClaimed) {
      return _MutedHintPill(text: l10n.progBackfillGoalNoData);
    }
    if (item.isClaimed) {
      return KeyedSubtree(
        key: pillKey,
        child: XpClaimPill(data: XpClaimPillData.claimed(item.previewXp)),
      );
    }
    if (item.isClaimable) {
      return KeyedSubtree(
        key: pillKey,
        child: XpClaimPill(
          data: XpClaimPillData.claimable(
            item.previewXp,
            onTap: (center) {
              onClaim(item, day, center);
            },
          ),
        ),
      );
    }
    if (!item.isMet) {
      return _MutedHintPill(text: l10n.progBackfillGoalUnmet);
    }
    return KeyedSubtree(
      key: pillKey,
      child: XpClaimPill(data: XpClaimPillData.locked(item.previewXp)),
    );
  }

  String _valueLabel(DailyGoalClaimItem item, AppLocalizations l10n) {
    switch (item.valueUnit) {
      case DailyGoalValueUnit.count:
        final actualStr = _formatNumber(item.actualValue);
        final targetStr = _formatNumber(item.targetValue);
        return '$actualStr / $targetStr';
      case DailyGoalValueUnit.minutes:
        return '${_formatMinutes(item.actualValue)} / '
            '${_formatMinutes(item.targetValue)}';
      case DailyGoalValueUnit.flag:
        return '';
    }
  }

  String _formatNumber(double value) => value.round().toString();

  String _formatMinutes(double minutes) {
    final total = minutes.round();
    if (total < 60) return '${total}m';
    final h = total ~/ 60;
    final rest = total - h * 60;
    return '${h}h ${rest.toString().padLeft(2, '0')}m';
  }
}

class BackfillActivityClaimRow extends StatelessWidget {
  const BackfillActivityClaimRow({
    super.key,
    required this.state,
    required this.pillKey,
    required this.onClaim,
  });

  final dynamic state; // ActivityClaimState — kept dynamic to avoid extra import
  final GlobalKey pillKey;
  final Future<void> Function(ActivityClaimRef ref, Offset? sparkleFrom)
      onClaim;

  @override
  Widget build(BuildContext context) {
    final record = state.record;
    final ft = context.ft;
    final time = _formatStartTime(context, record.startTime);
    final duration = _formatDuration(record.duration);
    final label = _formatType(record.type);
    final emoji = _emojiFor(record.type);

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ft.active.dim,
            borderRadius: BorderRadius.circular(Tokens.radiusIcon),
            border: Border.all(
              color: ft.active.color.withValues(alpha: 0.25),
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$time · $duration',
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w500,
                  color: ft.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        KeyedSubtree(
          key: pillKey,
          child: XpClaimPill(
            data: state.isClaimed
                ? XpClaimPillData.claimed(state.previewXp)
                : state.isClaimable
                    ? XpClaimPillData.claimable(
                        state.previewXp,
                        onTap: (center) =>
                            onClaim(ActivityClaimRef(record), center),
                      )
                    : XpClaimPillData.locked(state.previewXp),
          ),
        ),
      ],
    );
  }

  String _formatType(String hcType) => hcType
      .split('_')
      .map(
        (w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join(' ');

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}m';
    final h = d.inHours;
    final rest = m - h * 60;
    return '${h}h ${rest.toString().padLeft(2, '0')}m';
  }

  String _formatStartTime(BuildContext context, DateTime t) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('HH:mm', locale).format(t);
  }

  String _emojiFor(String hcType) {
    final t = hcType.toUpperCase();
    if (t.contains('HIKE') || t.contains('TRAIL')) return '🥾';
    if (t.contains('RUN') || t.contains('JOG')) return '🏃';
    if (t.contains('CYCL') || t.contains('BIKE')) return '🚴';
    if (t.contains('SWIM')) return '🏊';
    if (t.contains('WALK')) return '🚶';
    if (t.contains('YOGA') || t.contains('MEDIT') || t.contains('STRETCH')) {
      return '🧘';
    }
    if (t.contains('STRENGTH') || t.contains('WEIGHT')) return '🏋';
    return '⚔';
  }
}

class _MutedHintPill extends StatelessWidget {
  const _MutedHintPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w600,
          color: Tokens.onSurfaceFaint,
        ),
      ),
    );
  }
}

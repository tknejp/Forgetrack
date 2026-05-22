import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../../health_connect/domain/activity_record.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/domain/activity_claim/activity_claim_state.dart';

typedef ActivityClaimTap = void Function(ActivityRecord record, Offset center);

/// Compact list of per-workout claim pills rendered inside the home
/// activity card's expanded body. One row per activity for the
/// selected day; each row carries an [XpClaimPill] reflecting the
/// engine's per-activity claim state (locked / claimable / claimed).
class ActivityClaimsList extends StatelessWidget {
  const ActivityClaimsList({
    super.key,
    required this.claims,
    required this.header,
    required this.onClaim,
  });

  final List<ActivityClaimState> claims;
  final String header;
  final ActivityClaimTap onClaim;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) return const SizedBox.shrink();
    final ft = context.ft;
    return Padding(
      padding: const EdgeInsets.only(top: Tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            header.toUpperCase(),
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: ft.onSurfaceMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: Tokens.spaceSm),
          for (int i = 0; i < claims.length; i++)
            _ActivityClaimRow(
              key: ValueKey(claims[i].claimKey),
              state: claims[i],
              isLast: i == claims.length - 1,
              onClaim: onClaim,
            ),
        ],
      ),
    );
  }
}

class _ActivityClaimRow extends StatelessWidget {
  const _ActivityClaimRow({
    super.key,
    required this.state,
    required this.isLast,
    required this.onClaim,
  });

  final ActivityClaimState state;
  final bool isLast;
  final ActivityClaimTap onClaim;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final record = state.record;
    final emoji = _emojiFor(record.type);
    final label = _formatType(record.type);
    final duration = _formatDuration(record.duration);
    final time = _formatStartTime(context, record.startTime);

    final progression = context.read<ProgressionEngineProvider>();
    final companionBonus = progression
        .projectedCompanionBuffBonusForActivityClaim(state.previewXp);

    final XpClaimPillData pillData;
    if (state.isClaimed) {
      pillData = XpClaimPillData.claimed(
        state.previewXp,
        companionBonus: companionBonus,
      );
    } else if (state.isClaimable) {
      pillData = XpClaimPillData.claimable(
        state.previewXp,
        onTap: (center) => onClaim(record, center),
        companionBonus: companionBonus,
      );
    } else {
      pillData = XpClaimPillData.locked(
        state.previewXp,
        companionBonus: companionBonus,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: ft.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ft.active.dim,
                borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                border: Border.all(
                  color: ft.active.color.withValues(alpha: 0.25),
                ),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ft.onSurface.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$time · $duration',
                    style: TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      color: ft.onSurfaceMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            XpClaimPill(data: pillData, inline: true),
          ],
        ),
      ),
    );
  }

  String _formatType(String hcType) => hcType
      .split('_')
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
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

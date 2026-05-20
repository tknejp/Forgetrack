import 'package:flutter/material.dart';

import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression_engine/domain/progression_domain_chrome.dart';

/// One row of [HeroStreakStatsCard]. Carries the per-domain numbers
/// the widget needs to render a single line — `null` on either count
/// renders a dash placeholder rather than zero, so "unknown" (e.g.
/// friend's domain we don't sync) reads differently from "zero
/// streak yet".
class DomainStreakRow {
  const DomainStreakRow({
    required this.domain,
    this.currentStreak,
    this.bestStreak,
  });

  final ProgressionDomain domain;

  /// Player's current active streak in this domain, or null when
  /// unknown (friend profiles where the wire format doesn't carry
  /// this metric).
  final int? currentStreak;

  /// Player's all-time best streak in this domain, or null when
  /// unknown.
  final int? bestStreak;
}

/// Hero-screen stats card surfacing per-domain streak records.
///
/// Replaces the legacy 3-pill row (achievements / max streak /
/// steps streak) with a per-domain table that explicitly carries
/// **both** the current streak (live progress signal) and the
/// all-time best streak (record-chasing motivator) for every main
/// domain the player tracks.
///
/// The widget is render-only — it takes pre-resolved rows so:
/// * the owner screen can build them from `ProgressionEngineProvider`
///   for the signed-in user (full 5-domain coverage), and
/// * friend-profile callers can build them from the partial Firestore
///   wire stats (today: steps + nutrition; rest renders as a dash
///   until the Firestore schema grows the missing fields — tracked
///   under #99 follow-ups).
class HeroStreakStatsCard extends StatefulWidget {
  const HeroStreakStatsCard({
    super.key,
    required this.achievementsCount,
    required this.rows,
  });

  /// Total achievements unlocked. Headline number kept from the
  /// legacy stat row — it's the only non-streak metric the previous
  /// card surfaced and removing it would feel like a regression.
  final int achievementsCount;

  /// Per-domain streak rows. Order is preserved so callers can pin
  /// the canonical steps / nutrition / sleep / activity / body
  /// order across own and friend profiles.
  final List<DomainStreakRow> rows;

  @override
  State<HeroStreakStatsCard> createState() => _HeroStreakStatsCardState();
}

class _HeroStreakStatsCardState extends State<HeroStreakStatsCard> {
  /// Collapsed by default — the per-domain table is dense and most
  /// profile visits only need the headline (achievements count). Tap
  /// the header to reveal the full streak record table.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasRows = widget.rows.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasRows
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: _Header(
              achievementsCount: widget.achievementsCount,
              l10n: l10n,
              expanded: _expanded,
              showChevron: hasRows,
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: hasRows && _expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        const _Divider(),
                        const SizedBox(height: 8),
                        _ColumnLegend(l10n: l10n),
                        const SizedBox(height: 4),
                        for (var i = 0; i < widget.rows.length; i++) ...[
                          if (i > 0) const SizedBox(height: 4),
                          _DomainRow(row: widget.rows[i], l10n: l10n),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.achievementsCount,
    required this.l10n,
    required this.expanded,
    required this.showChevron,
  });

  final int achievementsCount;
  final AppLocalizations l10n;
  final bool expanded;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: 18,
          color: Tokens.active.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.heroStatsStreakRecordsTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Tokens.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Tokens.accent.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_moon_rounded,
                size: 12,
                color: Tokens.accent,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.heroStatsAchievementsBadge(achievementsCount),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Tokens.accent,
                ),
              ),
            ],
          ),
        ),
        if (showChevron) ...[
          const SizedBox(width: 6),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

class _ColumnLegend extends StatelessWidget {
  const _ColumnLegend({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.45);
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: muted,
      letterSpacing: 0.5,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          // Reserve the same horizontal slot the icon + label take
          // on data rows so the column header lines up cleanly above
          // the values.
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              l10n.heroStatsDomainColumn.toUpperCase(),
              style: style,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              l10n.heroStatsCurrentColumn.toUpperCase(),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              l10n.heroStatsBestColumn.toUpperCase(),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({required this.row, required this.l10n});

  final DomainStreakRow row;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = row.domain.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          Icon(row.domain.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              row.domain.label(l10n),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              _formatStreak(row.currentStreak, l10n),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: row.currentStreak == null || row.currentStreak == 0
                    ? Colors.white.withValues(alpha: 0.55)
                    : color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              _formatStreak(row.bestStreak, l10n),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: row.bestStreak == null || row.bestStreak == 0
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.white,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStreak(int? count, AppLocalizations l10n) {
    if (count == null) return '—';
    return l10n.heroStatsStreakDays(count);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/selected_period.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/drag_reveal_pager.dart';
import '../../coach_log_export/application/bushido_export_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/health_connect_settings_launcher.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import 'widgets/day_content.dart';
import 'widgets/period_navigator_bar.dart';

class OverviewScreen extends StatefulWidget {
  final PageController outerController;
  final GlobalKey barKey;
  final double topContentInset;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  const OverviewScreen({
    super.key,
    required this.outerController,
    required this.barKey,
    this.topContentInset = 0,
    required this.onOpenActivities,
    required this.onOpenSteps,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  SelectedPeriod _period = SelectedPeriod.today();

  /// When true, the user has explicitly chosen to view cached HC data
  /// instead of being shown the "set up Health Connect" prompt. Reset on
  /// app restart — once HC becomes ready, this flag stops mattering.
  bool _showCachedHcAnyway = false;

  /// Mirror of [_showCachedHcAnyway] for the Kalorické Tabulky source.
  bool _showCachedKtAnyway = false;

  Future<void> _refresh() async {
    final fitness = context.read<FitnessProvider>();
    final kt = context.read<KalorickeTabulkyProvider>();

    final isCurrentDay =
        _period.type == PeriodType.day && _period.isCurrentPeriod;

    final futures = <Future>[
      isCurrentDay
          ? fitness.refresh()
          : fitness.refreshRange(_period.start, _period.end),
    ];

    if (kt.isLoggedIn) {
      futures.add(kt.refreshRange(_period.start, _period.end));
    }

    await Future.wait(futures);

    if (mounted) {
      await context.read<ProgressionEngineProvider>().refresh();
    }
  }

  Future<void> _handleHcAction() async {
    await runHcAccessFlow(context.read<FitnessProvider>());
  }

  /// One-tap coach-log export of the current week, triggered from the header
  /// quick-export icon. Feedback is a snackbar — success offers an action that
  /// copies the spreadsheet link (mirrors the dedicated export screen, which
  /// has no url_launcher); failure surfaces the provider's localized error.
  Future<void> _quickExport() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<BushidoExportProvider>();
    try {
      final result = await provider.exportCurrentWeek(l10n: l10n);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Tokens.surface,
          duration: const Duration(seconds: 4),
          content: Text(
            l10n.coachLogExportSuccessWeeks(result.weeksExported),
            style: const TextStyle(color: Tokens.onSurface),
          ),
          action: SnackBarAction(
            label: l10n.coachLogExportOpenSheets,
            textColor: Tokens.accent,
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: result.spreadsheetUrl),
              );
              messenger.showSnackBar(
                SnackBar(
                  backgroundColor: Tokens.surface,
                  duration: const Duration(seconds: 2),
                  content: Text(
                    l10n.exportTargetLinkCopied,
                    style: const TextStyle(color: Tokens.onSurface),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final message =
          provider.lastError ?? l10n.exportErrorPrefix(l10n.exportErrorGeneric);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Tokens.surface,
          duration: const Duration(seconds: 4),
          content: Text(
            message,
            style: const TextStyle(color: Tokens.onSurface),
          ),
        ),
      );
    }
  }

  Future<void> _openDatePicker() async {
    if (_period.type != PeriodType.day) return;
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _period.referenceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Tokens.accent,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _period = SelectedPeriod.forDay(picked));
    }
  }

  String _periodDateLabel(BuildContext context, SelectedPeriod period) {
    final locale = Localizations.localeOf(context).toString();
    switch (period.type) {
      case PeriodType.day:
        return DateFormat('EEE d MMM', locale).format(period.referenceDate);
      case PeriodType.week:
        final start = period.start;
        final end = period.end;
        return '${start.day} ${DateFormat.MMM(locale).format(start)} – '
            '${end.day} ${DateFormat.MMM(locale).format(end)}';
      case PeriodType.month:
        return DateFormat.yMMM(locale).format(period.referenceDate);
      case PeriodType.custom:
        final start = period.start;
        final end = period.end;
        return '${start.day} ${DateFormat.MMM(locale).format(start)} – '
            '${end.day} ${DateFormat.MMM(locale).format(end)}';
    }
  }

  void _changeTab(String tab) {
    final l10n = context.l10n;
    final type = tab == l10n.periodDay
        ? PeriodType.day
        : tab == l10n.periodWeek
            ? PeriodType.week
            : PeriodType.month;
    setState(() => _period = _period.withType(type));
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1.2 perf fix: the screen build no longer watches any
    // providers. Provider subscriptions live in the per-card slot
    // widgets and in `Selector`s scoped to layout-decision values
    // (`PeriodNavigatorBar`, `_HomeOfflineBanner`, `HomeCardList`).
    // This stops a `FitnessProvider` step tick or a
    // `KalorickeTabulkyProvider` log tick from rebuilding the entire
    // CustomScrollView; only the slot widgets that actually consume
    // the changed data rebuild.
    return EdgePageHandoff(
      controller: widget.outerController,
      currentPage: 0,
      targetPage: 1,
      isEnabled: () => !_period.canGoForward,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: Tokens.accent,
        backgroundColor: Tokens.surface,
        edgeOffset: widget.topContentInset,
        displacement: 16,
        strokeWidth: 2.5,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 0),
                child: PeriodNavigatorBar(
                  period: _period,
                  dateLabel: _periodDateLabel(context, _period),
                  onTabChange: _changeTab,
                  onPrev: () =>
                      setState(() => _period = _period.backward()),
                  onNext: _period.canGoForward
                      ? () => setState(() => _period = _period.forward())
                      : null,
                  onToday: _period.isCurrentPeriod
                      ? null
                      : () => setState(
                          () => _period = _period.withType(_period.type)),
                  onDateTap: _period.type == PeriodType.day
                      ? _openDatePicker
                      : null,
                  onQuickExport: () => unawaited(_quickExport()),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              sliver: SliverToBoxAdapter(
                child: DragRevealPager<SelectedPeriod>(
                  item: _period,
                  pageGap: 16,
                  hasPrevious: (_) => true,
                  hasNext: (period) => period.canGoForward,
                  previousOf: (period) => period.backward(),
                  nextOf: (period) => period.forward(),
                  onCommit: (period) => setState(() => _period = period),
                  builder: (context, period) => DayContent(
                    key: ValueKey(period),
                    period: period,
                    barKey: widget.barKey,
                    showCachedHcAnyway: _showCachedHcAnyway,
                    showCachedKtAnyway: _showCachedKtAnyway,
                    onShowCachedHc: () =>
                        setState(() => _showCachedHcAnyway = true),
                    onShowCachedKt: () =>
                        setState(() => _showCachedKtAnyway = true),
                    onHcAction: () => unawaited(_handleHcAction()),
                    onOpenActivities: widget.onOpenActivities,
                    onOpenSteps: widget.onOpenSteps,
                    onOpenNutrition: widget.onOpenNutrition,
                    onOpenBody: widget.onOpenBody,
                    onOpenSleep: widget.onOpenSleep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

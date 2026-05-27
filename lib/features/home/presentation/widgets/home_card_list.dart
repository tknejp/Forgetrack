import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../onboarding/widgets/kt_login_sheet.dart';
import '../../application/home_card_order_provider.dart';
import '../../../../shared/widgets/dashboard_card_assets.dart';
import 'activity_slot.dart';
import 'calories_slot.dart';
import 'data_source_prompt_card.dart';
import 'home_helpers.dart';
import 'sleep_slot.dart';
import 'steps_slot.dart';
import 'weight_slot.dart';

/// Owns the reorderable list of dashboard cards. Subscribes via
/// `Selector2` to the small set of `FitnessProvider` + KT fields that
/// decide layout (HC prompt vs. real card, KT prompt vs. real card,
/// offline banners). Steps/kcal/sleep data ticks don't flip those
/// derived bits, so the `Selector2` builder is skipped — only the
/// individual slot widgets (which `context.watch` their own providers)
/// rebuild.
class HomeCardList extends StatelessWidget {
  const HomeCardList({
    super.key,
    required this.period,
    required this.barKey,
    required this.showCachedHcAnyway,
    required this.showCachedKtAnyway,
    required this.onShowCachedHc,
    required this.onShowCachedKt,
    required this.onHcAction,
    required this.onOpenActivities,
    required this.onOpenSteps,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final bool showCachedHcAnyway;
  final bool showCachedKtAnyway;
  final VoidCallback onShowCachedHc;
  final VoidCallback onShowCachedKt;
  final VoidCallback onHcAction;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Selector2<FitnessProvider, KalorickeTabulkyProvider, CardVisibility>(
      selector: (_, fitness, kt) {
        final hcReady = fitness.accessState == FitnessAccessState.ready;
        final hcChecking = fitness.accessState == FitnessAccessState.checking;
        final hcCached = hasCachedHcData(fitness);
        final ktCached = kt.hasCachedNutrition;
        // `showCached*Anyway` is a one-shot "user opted into viewing the
        // cache" intent. Honor it only while the underlying cache still
        // exists — once the data is wiped (logout + factory reset),
        // fall back to the login prompt instead of leaving the user
        // stuck on an empty-but-real card.
        final ktCachedView = showCachedKtAnyway && ktCached;
        final hcCachedView = showCachedHcAnyway && hcCached;
        return (
          showHcPrompt: !hcReady && !hcChecking && !hcCachedView,
          hcUnavailable:
              fitness.accessState == FitnessAccessState.unavailable,
          showKtPrompt: !kt.isLoggedIn &&
              !kt.isInitializing &&
              !kt.hasStoredCredentials &&
              !ktCachedView,
          hasCachedHcData: hcCached,
          hasCachedKtData: ktCached,
        );
      },
      builder: (context, viz, _) {
        final cardOrderProvider = context.watch<HomeCardOrderProvider>();
        final cardOrder = cardOrderProvider.order;

        final Widget stepsSlot = viz.showHcPrompt
            ? DataSourcePromptCard(
                domain: Tokens.steps,
                heroIcon: '🥾',
                visualAssets: DashboardCardAssetResolver.forKind(
                  DashboardCardKind.steps,
                ),
                title: viz.hcUnavailable
                    ? l10n.healthNotAvailable
                    : l10n.healthPermissionRequired,
                body: viz.hcUnavailable
                    ? l10n.healthNotAvailableBody
                    : l10n.healthPermissionBody,
                ctaLogoAsset: 'assets/icons/hc/health_connect_logo.png',
                ctaLabel: viz.hcUnavailable
                    ? l10n.healthInstall
                    : l10n.healthGrantAccess,
                providerAccent: const Color(0xFF34A853),
                onAction: onHcAction,
                onShowCached: viz.hasCachedHcData ? onShowCachedHc : null,
              )
            : StepsSlot(
                period: period,
                barKey: barKey,
                onOpenSteps: onOpenSteps,
              );

        final Widget caloriesSlot = viz.showKtPrompt
            ? DataSourcePromptCard(
                domain: Tokens.calories,
                heroIcon: '🔥',
                visualAssets: DashboardCardAssetResolver.forKind(
                  DashboardCardKind.nutrition,
                ),
                title: l10n.caloriesTodayTitle,
                body: l10n.ktLoginPrompt,
                ctaLogoAsset: 'assets/icons/kt/kaloricke_tabulky.png',
                ctaLabel: l10n.ktReauthCta,
                providerAccent: const Color(0xFF7AB342),
                onAction: () => KTLoginSheet.show(context),
                onShowCached: viz.hasCachedKtData ? onShowCachedKt : null,
              )
            : CaloriesSlot(
                period: period,
                barKey: barKey,
                onOpenNutrition: onOpenNutrition,
              );

        final Widget? weightSlot = viz.showHcPrompt
            ? null
            : WeightSlot(
                period: period,
                barKey: barKey,
                onOpenBody: onOpenBody,
              );
        final Widget? activitySlot = viz.showHcPrompt
            ? null
            : ActivitySlot(
                period: period,
                barKey: barKey,
                onOpenActivities: onOpenActivities,
              );
        final Widget? sleepSlot = viz.showHcPrompt
            ? null
            : SleepSlot(
                period: period,
                barKey: barKey,
                onOpenSleep: onOpenSleep,
              );

        final slots = <HomeCardKind, Widget?>{
          HomeCardKind.steps: stepsSlot,
          HomeCardKind.calories: caloriesSlot,
          HomeCardKind.weight: weightSlot,
          HomeCardKind.activity: activitySlot,
          HomeCardKind.sleep: sleepSlot,
        };

        // Walk the user's stored order; drop slots hidden in the
        // current state but keep their position in the prefs so the
        // cards reappear in their preferred slot once the source
        // becomes available again.
        final visibleKinds = <HomeCardKind>[];
        final visibleWidgets = <Widget>[];
        for (final kind in cardOrder) {
          final w = slots[kind];
          if (w != null) {
            visibleKinds.add(kind);
            visibleWidgets.add(w);
          }
        }

        if (visibleWidgets.isEmpty) return const SizedBox.shrink();

        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Whole-card long-press drag instead of visible side handles.
          buildDefaultDragHandles: false,
          itemCount: visibleWidgets.length,
          itemBuilder: (ctx, i) {
            final isLast = i == visibleWidgets.length - 1;
            return ReorderableDelayedDragStartListener(
              key: ValueKey(visibleKinds[i]),
              index: i,
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: visibleWidgets[i],
              ),
            );
          },
          // Lift the dragged card so the user gets clear feedback.
          proxyDecorator: (child, index, anim) => Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            child: child,
          ),
          // ignore: deprecated_member_use, migrate to onReorderItem later
          onReorder: (oldIndex, newIndex) {
            // ReorderableListView reports newIndex post-removal of the
            // dragged item, so subtract 1 when moving downward.
            var actualNew = newIndex;
            if (newIndex > oldIndex) actualNew -= 1;
            final fromKind = visibleKinds[oldIndex];
            final toKind = visibleKinds[actualNew];
            final fromAbs = cardOrder.indexOf(fromKind);
            final toAbs = cardOrder.indexOf(toKind);
            unawaited(cardOrderProvider.reorder(fromAbs, toAbs));
          },
        );
      },
    );
  }
}

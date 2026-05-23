import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_log.dart';
import '../../../l10n/l10n.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../cosmetics/domain/hero_race_catalog.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/onboarding_theme.dart';
import 'race_picker_view.dart';

/// One-shot race picker for existing players whose
/// `UserCosmeticsState.selectedRaceId` is null — typically game state
/// that predates the race system. Routed in from `app.dart`'s gate when
/// onboarding is already completed but no race is set.
///
/// UX:
///   * Same visual treatment as onboarding Step 1 — sparkle preview,
///     grid, tag — wrapped in the welcome screen's gradient bg.
///   * No skip / no back / no system back gesture: race lock is the
///     contract; the screen blocks until a pick is committed.
///   * CTA at the bottom commits the cosmetics-provider trio
///     (selectRace + unlock(skin_pilgrim) + equip(skin_pilgrim)) and
///     pops back into the routing tree — the app.dart selector then
///     re-evaluates and shows MainShell because `currentRaceId` is now
///     non-null.
class ForcePickRaceScreen extends StatefulWidget {
  const ForcePickRaceScreen({super.key});

  @override
  State<ForcePickRaceScreen> createState() => _ForcePickRaceScreenState();
}

class _ForcePickRaceScreenState extends State<ForcePickRaceScreen> {
  /// Catalog id granted at commit time. Matches the onboarding Step 1
  /// trio so re-entered players land in the same baseline state as
  /// new players.
  static const _starterSkinId = 'skin_pilgrim';

  String _draftRaceId = HeroRaceCatalog.definitions.first.id;
  bool _busy = false;

  Future<void> _commit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final cosmetics = context.read<CosmeticsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await cosmetics.selectRace(_draftRaceId);
      final hasStarter =
          cosmetics.state?.unlocked.containsKey(_starterSkinId) ?? false;
      if (!hasStarter) {
        await cosmetics.unlock(
          _starterSkinId,
          sourceType: CosmeticUnlockSource.defaultBaseline.name,
        );
      }
      if (cosmetics.state?.equipped.skinId != _starterSkinId) {
        await cosmetics.equip(_starterSkinId);
      }
      AppLog.app.info(
        'force-race-pick: committed',
        payload:
            'race=$_draftRaceId skin=$_starterSkinId uid=${cosmetics.currentUid}',
      );
      // `app.dart` watches CosmeticsProvider — listeners fired by the
      // calls above re-evaluate the routing gate and swap the home
      // back to MainShell. Nothing more to navigate here.
    } catch (e, st) {
      AppLog.app.error(
        'force-race-pick: commit failed',
        payload: 'race=$_draftRaceId',
        err: e,
        stackTrace: st,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.forcePickRaceCommitFailed)),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: OnboardingTheme.bg,
      ),
      child: PopScope(
        // Block both swipe-back and system-back. Race lock is the
        // contract — the only exit is a successful commit.
        canPop: false,
        child: Scaffold(
          backgroundColor: OnboardingTheme.bg,
          body: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: OnboardingTheme.pageGradientTop,
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: OnboardingTheme.pageGradientBottom,
                  ),
                ),
              ),
              Column(
                children: [
                  SizedBox(height: topInset + 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        children: [
                          Text(
                            l10n.forcePickRaceHeader,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: OnboardingTheme.gold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          RacePickerView(
                            draftRaceId: _draftRaceId,
                            onPickRace: (id) =>
                                setState(() => _draftRaceId = id),
                            title: l10n.forcePickRaceTitle,
                            subtitle: l10n.forcePickRaceSubtitle,
                            // No accent phrase — the subtitle reads as
                            // one continuous explanation, no inline
                            // highlight needed for a one-shot prompt.
                            subtitleAccent: '',
                            levelLabel: l10n.welcomeStep1HeroPill,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + bottomInset),
                    child: Row(
                      children: [
                        PrimaryBtn(
                          label: _busy
                              ? l10n.forcePickRaceCtaBusy
                              : l10n.forcePickRaceCta,
                          onTap: _busy ? () {} : _commit,
                          showArrow: false,
                          showWand: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

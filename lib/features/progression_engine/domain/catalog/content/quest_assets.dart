// Shared PNG asset paths used by V2 quest nodes.
//
// Mirrors the V1 quest catalog's `_questAsset*` constants so the same
// art ships under both engines until V1 is removed in Phase 9. Adding
// a new asset: place the file under `assets/ui/quests/` (declared in
// `pubspec.yaml`) and add a constant here.

/// Generic activity / general daily quest icon.
const questAssetActivity = 'assets/ui/quests/activity.png';

/// Combo / two-up quest icon.
const questAssetDoubleWin = 'assets/ui/quests/double_win.png';

/// Nutrition (protein, calories, etc.) quest icon.
const questAssetNutrition = 'assets/ui/quests/nutri_combo.png';

/// Steps quest icon.
const questAssetSteps = 'assets/ui/quests/steps.png';

/// Streak / recovery / sleep quest icon.
const questAssetStreak = 'assets/ui/quests/streak.png';

// Chapter assets — icon + parallax background, paired by chapter id.
// One pair per V1 chapter so the V2 port can drop into the same art.

const questAssetPilgrimPathIcon =
    'assets/ui/quests/chapter/icon/pilgrim_path.png';
const questAssetForestTrialIcon =
    'assets/ui/quests/chapter/icon/forest_trial.png';
const questAssetRuinsDisciplineIcon =
    'assets/ui/quests/chapter/icon/ruins_discipline.png';
const questAssetMineDescentIcon =
    'assets/ui/quests/chapter/icon/mine_descent.png';
const questAssetForgeMomentumIcon =
    'assets/ui/quests/chapter/icon/forge_momentum.png';
const questAssetUnderwayPactIcon =
    'assets/ui/quests/chapter/icon/underway_pact.png';
const questAssetFrostboundOathIcon =
    'assets/ui/quests/chapter/icon/frostbound_oath.png';
const questAssetIcewalkerRouteIcon =
    'assets/ui/quests/chapter/icon/icewalker_route.png';
const questAssetMountainAscentIcon =
    'assets/ui/quests/chapter/icon/mountain_ascent.png';
const questAssetDragonroadIcon =
    'assets/ui/quests/chapter/icon/dragonroad.png';
const questAssetDragonrockSovereignIcon =
    'assets/ui/quests/chapter/icon/dragonrock_sovereign.png';

const questBgPilgrimPath =
    'assets/ui/quests/chapter/bg/pilgrim_path_bg.png';
const questBgForestTrial =
    'assets/ui/quests/chapter/bg/forest_trial_bg.png';
const questBgRuinsDiscipline =
    'assets/ui/quests/chapter/bg/ruins_discipline_bg.png';
const questBgMineDescent =
    'assets/ui/quests/chapter/bg/mine_descent_bg.png';
const questBgForgeMomentum =
    'assets/ui/quests/chapter/bg/forge_momentum_bg.png';
const questBgUnderwayPact =
    'assets/ui/quests/chapter/bg/underway_pact_bg.png';
const questBgFrostboundOath =
    'assets/ui/quests/chapter/bg/frostbound_oath_bg.png';
const questBgIcewalkerRoute =
    'assets/ui/quests/chapter/bg/icewalker_route_bg.png';
const questBgMountainAscent =
    'assets/ui/quests/chapter/bg/mountain_ascent_bg.png';
const questBgDragonroad =
    'assets/ui/quests/chapter/bg/dragonroad_bg.png';
const questBgDragonrockSovereign =
    'assets/ui/quests/chapter/bg/dragonrock_sovereign_bg.png';

/// Resolves a chapter id to its background asset, empty string when
/// the chapter is unknown. Mirrors V1's `chapterBgKey()`.
String chapterBgAssetFor(String chapterId) {
  switch (chapterId) {
    case 'pilgrim_path':
      return questBgPilgrimPath;
    case 'forest_trial':
      return questBgForestTrial;
    case 'ruins_discipline':
      return questBgRuinsDiscipline;
    case 'mine_descent':
      return questBgMineDescent;
    case 'forge_momentum':
      return questBgForgeMomentum;
    case 'underway_pact':
      return questBgUnderwayPact;
    case 'frostbound_oath':
      return questBgFrostboundOath;
    case 'icewalker_route':
      return questBgIcewalkerRoute;
    case 'mountain_ascent':
      return questBgMountainAscent;
    case 'dragonroad':
      return questBgDragonroad;
    case 'dragonrock_sovereign':
      return questBgDragonrockSovereign;
    default:
      return '';
  }
}

/// Resolves a chapter id to its icon asset. Falls back to the generic
/// activity icon when the chapter is unknown.
String chapterIconAssetFor(String chapterId) {
  switch (chapterId) {
    case 'pilgrim_path':
      return questAssetPilgrimPathIcon;
    case 'forest_trial':
      return questAssetForestTrialIcon;
    case 'ruins_discipline':
      return questAssetRuinsDisciplineIcon;
    case 'mine_descent':
      return questAssetMineDescentIcon;
    case 'forge_momentum':
      return questAssetForgeMomentumIcon;
    case 'underway_pact':
      return questAssetUnderwayPactIcon;
    case 'frostbound_oath':
      return questAssetFrostboundOathIcon;
    case 'icewalker_route':
      return questAssetIcewalkerRouteIcon;
    case 'mountain_ascent':
      return questAssetMountainAscentIcon;
    case 'dragonroad':
      return questAssetDragonroadIcon;
    case 'dragonrock_sovereign':
      return questAssetDragonrockSovereignIcon;
    default:
      return questAssetActivity;
  }
}

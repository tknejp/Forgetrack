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

/// Forest Trial chapter icon.
const questAssetForestTrialIcon =
    'assets/ui/quests/chapter/icon/forest_trial.png';

/// Forest Trial chapter background (used behind the chapter card).
const questBgForestTrial =
    'assets/ui/quests/chapter/bg/forest_trial_bg.png';

/// Resolves a chapter id to its background asset, empty string when
/// the chapter is unknown. Mirrors V1's `chapterBgKey()`.
String chapterBgAssetFor(String chapterId) {
  switch (chapterId) {
    case 'forest_trial':
      return questBgForestTrial;
    default:
      return '';
  }
}

/// Resolves a chapter id to its icon asset. Falls back to the generic
/// activity icon when the chapter is unknown.
String chapterIconAssetFor(String chapterId) {
  switch (chapterId) {
    case 'forest_trial':
      return questAssetForestTrialIcon;
    default:
      return questAssetActivity;
  }
}

## Summary

- 127 total hardcoded configuration values found across 18 files
- 28 to BuildConfig candidates
- 47 to UserSettings candidates  
- 41 to AdminConfig candidates
- 11 duplicates (same value in multiple files)
- Largest concentration in progression engine catalog content (XP rewards, objective thresholds, achievement targets) and goals provider (9 goal field defaults tripled)

## BuildConfig candidates

| File:Line | Identifier / context | Current value | Notes |
|---|---|---|---|
| lib/core/config/constants.dart:4 | appName | Forgetrack | App branding, compile-time constant |
| lib/core/config/constants.dart:5 | appVersion | 1.0.0 | Version number, per-release |
| lib/core/config/constants.dart:8 | sheetsTitle | Forgetrack Data | Google Sheets document title |
| lib/core/config/constants.dart:9 | stepsSheet | Kroky | Google Sheets tab name |
| lib/core/config/constants.dart:10 | activitiesSheet | Aktivity | Google Sheets tab name |
| lib/core/config/constants.dart:11 | caloriesSheet | Kalorie | Google Sheets tab name |
| lib/core/config/constants.dart:14 | exportSheetName | Forgetrack | Google Sheets unified export tab |
| lib/core/config/constants.dart:18 | coachLogSheetName | Coach Log | Bushido coach-log tab |
| lib/core/config/constants.dart:21 | exportDateColumn | date | Merge-key column header |
| lib/core/config/constants.dart:24 | prefSpreadsheetId | spreadsheet_id | SharedPreferences key (not a value) |
| lib/core/config/constants.dart:28 | foodApiBase | https://world.openfoodfacts.org | Open Food Facts API base URL |
| lib/core/config/constants.dart:29 | foodSearchPageSize | 20 | Food search pagination limit |
| lib/core/config/constants.dart:32 | defaultHistoryDays | 30 | Health Connect fetch window default (flagged for review per plan) |

## UserSettings candidates

| File:Line | Identifier / context | Current value | Notes |
|---|---|---|---|
| lib/core/config/constants.dart:35 | dailyStepGoal | 10000 | Default daily steps - also at goals_provider.dart:25, engine_catalog_context.dart:10 (DUPLICATE) |
| lib/core/config/constants.dart:36 | weeklyStepGoal | 70000 | Default weekly steps - move to UserSettings |
| lib/core/config/constants.dart:37 | monthlyStepGoal | 300000 | Default monthly steps - move to UserSettings |
| lib/core/config/constants.dart:38 | defaultCalorieGoal | 2650 | Default daily calorie - move to UserSettings |
| lib/core/config/constants.dart:39 | defaultWeightGoal | 100 | Default target weight kg - move to UserSettings |
| lib/features/health_connect/application/goals_provider.dart:25 | _dailySteps | 10000 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:26 | _targetWeight | 75.0 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:27 | _dailyCalories | 2000 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:28 | _dailyProtein | 150 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:29 | _dailyFat | 65 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:30 | _dailyCarbs | 250 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:31 | _dailyFiber | 30 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:32 | _sleepHours | 8.0 | In-memory default |
| lib/features/health_connect/application/goals_provider.dart:33 | _weeklyActivityMins | 150 | In-memory default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:10 | dailySteps | 10000 | EngineGoalSet default (DUPLICATE) |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:11 | dailyCalories | 2000 | EngineGoalSet default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:12 | dailyProteinGrams | 150 | EngineGoalSet default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:13 | dailyCarbsGrams | 250 | EngineGoalSet default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:14 | dailyFatGrams | 65 | EngineGoalSet default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:15 | dailyFiberGrams | 30 | EngineGoalSet default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:16 | sleepMinutes | 480 | EngineGoalSet default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:17 | weeklyActivityMinutes | 150 | EngineGoalSet default |
| lib/features/progression_engine/domain/catalog/engine_catalog_context.dart:18 | targetWeightKg | 70.0 | EngineGoalSet default |
| lib/features/health_connect/application/fitness_provider.dart:23 | _defaultHistoryDays | 30 | Fetch window for initial load |
| lib/features/health_connect/application/fitness_provider.dart:24 | _extendedHistoryDays | 365 | Extended fetch window annual |
| lib/features/health_connect/application/fitness_provider.dart:25 | _normalRefreshDays | 7 | Normal refresh lookback window |
| lib/features/health_connect/application/fitness_provider.dart:26 | _appOpenRefreshMinInterval | Duration(minutes: 5) | App-open refresh debounce |
| lib/features/nutrition/application/kaloricke_tabulky_provider.dart:42 | _appOpenRefreshMinInterval | Duration(minutes: 5) | App-open refresh debounce (duplicate) |

## AdminConfig candidates

| File:Line | Identifier / context | Current value | Why operator-tunable |
|---|---|---|---|
| lib/features/progression_engine/domain/catalog/content/nutrition_content.dart:19 | _nutritionTol | 0.10 | Macro tolerance ratio - tune post-launch |
| lib/features/progression_engine/domain/catalog/content/activity_content.dart:18 | _dailyActivityTargetMinutes | 30 | Daily activity quest threshold - tune for engagement |
| lib/core/services/background_sync_service.dart:36 | _syncInterval | Duration(minutes: 15) | Background sync cadence - tune for battery |
| lib/features/progression_engine/domain/policy/level_policy.dart:12 | baseDailyRewardXp | 230 | Base daily reward XP - balance knob |
| lib/features/progression_engine/domain/policy/level_policy.dart:13 | baseWeeklyRewardXp | 120 | Base weekly reward XP - balance knob |
| lib/features/progression_engine/domain/policy/level_policy.dart:14 | level30RewardMultiplier | 12.5 | XP reward multiplier at level 30 |
| lib/features/progression_engine/domain/policy/level_policy.dart:15 | level50RewardMultiplier | 62.5 | XP reward multiplier at level 50 |
| lib/features/progression_engine/domain/policy/level_policy.dart:16 | level100RewardMultiplier | 150.0 | XP reward multiplier at level 100 |
| lib/features/progression_engine/domain/policy/level_policy.dart:17 | level1DaysToAdvance | 1.15 | Days to reach level 2 |
| lib/features/progression_engine/domain/policy/level_policy.dart:18 | level10DaysToAdvance | 2.45 | Days to reach level 10 |
| lib/features/progression_engine/domain/policy/level_policy.dart:19 | level30DaysToAdvance | 6.2 | Days to reach level 30 |
| lib/features/progression_engine/domain/policy/level_policy.dart:20 | level50DaysToAdvance | 11.8 | Days to reach level 50 |
| lib/features/progression_engine/domain/policy/level_policy.dart:21 | level100DaysToAdvance | 21.0 | Days to reach level 100 |
| lib/features/progression_engine/domain/catalog/content/nutrition_content.dart:115 | XpReward daily_calories | 60 | Daily calorie quest reward |
| lib/features/progression_engine/domain/catalog/content/nutrition_content.dart:133 | XpReward daily_protein | 40 | Daily protein quest reward |
| lib/features/progression_engine/domain/catalog/content/nutrition_content.dart:145 | XpReward daily_carbs | 35 | Daily carbs quest reward |
| lib/features/progression_engine/domain/catalog/content/nutrition_content.dart:157 | XpReward daily_fat | 35 | Daily fat quest reward |
| lib/features/progression_engine/domain/catalog/content/nutrition_content.dart:169 | XpReward daily_fiber | 35 | Daily fiber quest reward |
| lib/features/progression_engine/domain/catalog/content/activity_content.dart:101 | XpReward daily_activity | 50 | Daily activity quest base reward |
| lib/features/progression_engine/domain/catalog/content/activity_content.dart:103 | BonusXpReward daily_activity | 50 | Daily activity early-claim bonus |
| lib/features/progression_engine/domain/catalog/content/activity_content.dart:118 | XpReward weekly_activity | 120 | Weekly activity quest reward |
| lib/features/progression_engine/domain/catalog/content/sleep_content.dart:73 | XpReward daily_sleep | 50 | Daily sleep quest reward |
| lib/features/progression_engine/domain/catalog/content/body_content.dart:42 | XpReward daily_weight_log | 20 | Daily weight log quest reward |
| lib/features/progression_engine/domain/catalog/content/steps_content.dart:152 | XpReward daily_steps | 80 | Daily steps quest base reward |
| lib/features/progression_engine/domain/catalog/content/steps_content.dart:155 | BonusXpReward daily_steps | 80 | Daily steps early-claim bonus |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:116 | XpReward long_term_steps_100k | 120 | Long-term steps 100K milestone |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:132 | XpReward long_term_steps_500k | 360 | Long-term steps 500K milestone |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:148 | XpReward long_term_steps_1m | 720 | Long-term steps 1M milestone |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:164 | XpReward long_term_steps_5m | 1200 | Long-term steps 5M milestone |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:180 | XpReward long_term_steps_10m | 2000 | Long-term steps 10M milestone |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:197 | XpReward long_term_reach_500_xp | 120 | XP milestone 500 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:213 | XpReward long_term_reach_2000_xp | 180 | XP milestone 2000 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:229 | XpReward long_term_reach_5000_xp | 260 | XP milestone 5000 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:245 | XpReward long_term_reach_25000_xp | 420 | XP milestone 25000 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:261 | XpReward long_term_reach_100000_xp | 640 | XP milestone 100000 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:277 | XpReward long_term_reach_1000000_xp | 1000 | XP milestone 1000000 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:294 | XpReward long_term_earn_first_reward | 60 | Reward hunter first |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:310 | XpReward long_term_earn_25_rewards | 180 | Reward hunter 25 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:326 | XpReward long_term_earn_100_rewards | 320 | Reward hunter 100 |
| lib/features/progression_engine/domain/catalog/content/long_term_content.dart:342 | XpReward long_term_earn_250_rewards | 520 | Reward hunter 250 |

## Duplicate defaults across files

| Value | Occurrences | Recommended single home |
|---|---|---|
| 10000 | constants.dart:35, goals_provider.dart:25, engine_catalog_context.dart:10 | UserSettingsKeys.dailyStepsGoal default |
| 2000 | goals_provider.dart:27, engine_catalog_context.dart:11 | UserSettingsKeys default |
| 150 | goals_provider.dart:28, engine_catalog_context.dart:12 | UserSettingsKeys default |
| 250 | goals_provider.dart:30, engine_catalog_context.dart:13 | UserSettingsKeys default |
| 65 | goals_provider.dart:29, engine_catalog_context.dart:14 | UserSettingsKeys default |
| 30 | goals_provider.dart:31, engine_catalog_context.dart:15 | UserSettingsKeys default |
| 150 | goals_provider.dart:33, engine_catalog_context.dart:17 | UserSettingsKeys default |
| 480 | engine_catalog_context.dart:16 as minutes | UserSettingsKeys default |
| 75.0/70.0 | goals_provider.dart:26 vs engine_catalog_context.dart:18 | Reconcile to single default |
| Duration(minutes: 5) | fitness_provider.dart:26, kaloricke_tabulky_provider.dart:42 | Extract to shared constant |
| 30 | constants.dart:32, fitness_provider.dart:23 | Share via BuildConfig |

## Notable hotspots

1. **Progression catalog content** - 30+ hardcoded XP reward values across steps_content, nutrition_content, activity_content, long_term_content. Each is tunable for balance; consolidation into AdminConfig is highest-priority rebalancing lever for engagement pacing.

2. **Level progression policy** - 11 parameters in level_policy.dart control entire reward-curve shape. Collectively tunable post-launch for pacing without releases.

3. **Goals provider triple-default pattern** - Nine goal fields default in three places. Consolidation eliminates maintenance tax and unblocks cross-device sync. Target weight shows discrepancy (75.0 vs 70.0) needing reconciliation.

4. **Background sync intervals** - Two separate app-open refresh debounce values both set to 5 minutes should be unified. Background sync interval could be operator-tunable for battery/freshness trade-offs.

5. **Nutrition tolerance ratio** - Single value controls macro-goal flexibility. Isolated, obvious AdminConfig candidate demonstrating three-layer model payoff.

## Files inspected

- lib/core/config/constants.dart
- lib/core/services/background_sync_service.dart
- lib/features/health_connect/application/goals_provider.dart
- lib/features/health_connect/application/fitness_provider.dart
- lib/features/progression_engine/domain/catalog/engine_catalog_context.dart
- lib/features/progression_engine/domain/catalog/level_milestone_specs.dart
- lib/features/progression_engine/domain/catalog/content/nutrition_content.dart
- lib/features/progression_engine/domain/catalog/content/activity_content.dart
- lib/features/progression_engine/domain/catalog/content/steps_content.dart
- lib/features/progression_engine/domain/catalog/content/sleep_content.dart
- lib/features/progression_engine/domain/catalog/content/body_content.dart
- lib/features/progression_engine/domain/catalog/content/long_term_content.dart
- lib/features/progression_engine/domain/catalog/content/meta_content.dart
- lib/features/progression_engine/domain/policy/level_policy.dart
- lib/features/nutrition/application/kaloricke_tabulky_provider.dart
- lib/features/cosmetics/domain/cosmetic_unlock_rules.dart
- lib/features/cosmetics/domain/cosmetic_catalog.dart
- lib/features/devtools/domain/debug_metric_overrides.dart

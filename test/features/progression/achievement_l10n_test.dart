import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression/domain/catalog/achievement_catalog.dart';
import 'package:forgetrack/features/progression/domain/policy/level_config.dart';
import 'package:forgetrack/features/progression/domain/progression_models.dart';
import 'package:forgetrack/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final catalog = const ProgressionAchievementCatalog().build();

  group('ProgressionAchievementCatalog — l10n closures', () {
    test('every definition resolves a non-empty title', () {
      for (final def in catalog) {
        final title = def.title(l10n);
        expect(title, isNotEmpty, reason: 'title empty for id=${def.id}');
      }
    });

    test('every definition resolves a non-empty description', () {
      for (final def in catalog) {
        final desc = def.description(l10n);
        expect(desc, isNotEmpty, reason: 'description empty for id=${def.id}');
      }
    });

    test('all IDs are unique', () {
      final ids = catalog.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('ProgressionAchievement model-localized values', () {
    test('title returns non-empty string for every known ID', () {
      for (final def in catalog) {
        final achievement = ProgressionAchievement(
          id: def.id,
          type: def.type,
          difficulty: def.difficulty,
          rarity: def.rarity,
          criterionType: def.criterionType,
          title: def.title,
          description: def.description,
          targetValue: def.targetValue,
          currentValue: 0,
          progress: 0,
          unlocked: false,
        );
        final title = achievement.title(l10n);
        expect(title, isNotEmpty, reason: 'title empty for id=${def.id}');
      }
    });

    test('description returns non-empty string for every known ID', () {
      for (final def in catalog) {
        final achievement = ProgressionAchievement(
          id: def.id,
          type: def.type,
          difficulty: def.difficulty,
          rarity: def.rarity,
          criterionType: def.criterionType,
          title: def.title,
          description: def.description,
          targetValue: def.targetValue,
          currentValue: 0,
          progress: 0,
          unlocked: false,
        );
        final desc = achievement.description(l10n);
        expect(desc, isNotEmpty, reason: 'description empty for id=${def.id}');
      }
    });

    test('achievement text falls back for an unknown ID', () {
      final achievement = ProgressionAchievement(
        id: 'unknown_future_achievement',
        type: ProgressionAchievementType.milestone,
        difficulty: ProgressionAchievementDifficulty.easy,
        rarity: Rarity.common,
        criterionType: ProgressionAchievementCriterionType.totalXpAtLeast,
        title: (_) => 'Fallback Title',
        description: (_) => 'Fallback Desc',
        targetValue: 1,
        currentValue: 0,
        progress: 0,
        unlocked: false,
      );
      expect(achievement.title(l10n), 'Fallback Title');
      expect(achievement.description(l10n), 'Fallback Desc');
    });

    test('level tier titles resolve without throwing', () {
      for (int level = 1; level <= 100; level++) {
        final title = tierForLevel(level).title(l10n);
        expect(title, isNotEmpty, reason: 'level title empty for level=$level');
      }
    });
  });
}

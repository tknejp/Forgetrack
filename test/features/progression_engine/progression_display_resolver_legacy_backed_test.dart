import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/domain/display/progression_display_models.dart';
import 'package:forgetrack/features/progression_engine/domain/display/progression_display_resolver.dart';
import 'package:forgetrack/features/progression/domain/catalog/achievement_catalog.dart';
import 'package:forgetrack/features/progression/domain/policy/level_config.dart';
import 'package:forgetrack/l10n/app_localizations_en.dart';

void main() {
  const resolver = ProgressionDisplayResolver();
  final l10n = AppLocalizationsEn();
  const locale = 'en';

  group('ProgressionDisplayResolver — levels', () {
    test('levelDisplay returns tier metadata for a known level', () {
      final display = resolver.levelDisplay(5);
      expect(display.level, 5);
      expect(display.title(l10n), isNotEmpty);
      expect(display.emoji, isNotEmpty);
      expect(display.rarity, Rarity.common);
    });

    test('levelDisplay falls back to a synthetic title for unknown levels', () {
      final display = resolver.levelDisplay(9999);
      expect(display.level, 9999);
      expect(display.title(l10n), 'Level 9999');
      expect(display.emoji, '');
      expect(display.rarity, Rarity.common);
    });

    test('levelMilestones yields one entry per tier in order', () {
      final milestones = resolver.levelMilestones().toList();
      expect(milestones, hasLength(kProgressionLevelTiers.length));
      for (var i = 0; i < milestones.length; i++) {
        expect(milestones[i].level, kProgressionLevelTiers[i].level);
        expect(milestones[i].emoji, kProgressionLevelTiers[i].emoji);
        expect(
          milestones[i].cosmeticRewardIds,
          kProgressionLevelTiers[i].cosmeticRewards,
        );
      }
    });
  });

  group('ProgressionDisplayResolver — nodes', () {
    test('nodeDisplay resolves a level milestone id', () {
      final display = resolver.nodeDisplay('level_10', l10n);
      expect(display, isNotNull);
      expect(display!.kind, NodeDisplayKind.levelMilestone);
      expect(display.title(l10n), isNotEmpty);
      expect(display.targetValue, isPositive);
    });

    test('nodeDisplay resolves a known catalog achievement id', () {
      // welcome_to_journey is the smallest, hand-authored seed achievement.
      final display = resolver.nodeDisplay('welcome_to_journey', l10n);
      expect(display, isNotNull);
      expect(display!.kind, NodeDisplayKind.achievement);
      expect(display.title(l10n), isNotEmpty);
      expect(display.description(l10n), isNotEmpty);
    });

    test('nodeDisplay populates accentColor for every catalog entry', () {
      // Smoke test: accentColor is required on NodeDisplay; if a future
      // resolver branch forgets to set it, this catches it.
      for (final def in const ProgressionAchievementCatalog().build()) {
        final display = resolver.nodeDisplay(def.id, l10n);
        expect(display, isNotNull, reason: 'no display for id=${def.id}');
        expect(display!.accentColor, isNotNull);
      }
    });

    test('nodeDisplay returns null for unknown ids', () {
      expect(
        resolver.nodeDisplay('does_not_exist_nope', l10n),
        isNull,
      );
    });

    test('unknownNodeDisplay builds a synthetic display from snapshot data', () {
      final unlockedAt = DateTime(2026, 4, 15, 10);
      final display = resolver.unknownNodeDisplay(
        nodeId: 'mystery_id_42',
        fallbackTitle: 'Mystery achievement',
        fallbackDescription: 'A test description',
        badgeEmoji: '🔮',
        unlockedAt: unlockedAt,
      );
      expect(display.nodeId, 'mystery_id_42');
      expect(display.title(l10n), 'Mystery achievement');
      expect(display.description(l10n), 'A test description');
      expect(display.badgeEmoji, '🔮');
      expect(display.unlockedAt, unlockedAt);
    });
  });

  group('ProgressionDisplayResolver — friendDisplayLabel', () {
    test('returns LEVEL N (uppercase) for level milestone ids', () {
      final display = resolver.nodeDisplay('level_25', l10n)!;
      final label = resolver.friendDisplayLabel(display, l10n);
      expect(label, equals(l10n.socialLevelLabel(25).toUpperCase()));
    });

    test('returns uppercase title for non-level ids', () {
      final display = resolver.nodeDisplay('welcome_to_journey', l10n)!;
      final label = resolver.friendDisplayLabel(display, l10n);
      expect(label, equals(display.title(l10n).toUpperCase()));
    });
  });

  group('ProgressionDisplayResolver — compactSummary', () {
    test('returns a level label for level milestone ids', () {
      expect(
        resolver.compactSummary('level_20', l10n, locale),
        equals(l10n.socialLevelLabel(20)),
      );
    });

    test('returns a non-null formatted string for every catalog achievement', () {
      // Smoke test: every real catalog entry must produce a summary so
      // friend cards never crash when rendering an unknown criterion.
      for (final def in const ProgressionAchievementCatalog().build()) {
        final summary = resolver.compactSummary(def.id, l10n, locale);
        expect(
          summary,
          isNotNull,
          reason: 'compactSummary returned null for id=${def.id} '
              '(criterion=${def.criterionType.name})',
        );
        expect(summary, isNotEmpty);
      }
    });

    test('returns null for unknown ids', () {
      expect(
        resolver.compactSummary('does_not_exist_nope', l10n, locale),
        isNull,
      );
    });
  });

  group('ProgressionDisplayResolver — domains', () {
    test('domainDisplay carries the legacy domain visuals through', () {
      final display = resolver.domainDisplay(ProgressionDomain.steps);
      expect(display.domain, ProgressionDomain.steps);
      expect(display.icon, ProgressionDomain.steps.icon);
      expect(display.color, ProgressionDomain.steps.color);
      expect(display.label(l10n), ProgressionDomain.steps.label(l10n));
    });

    test('parseDomain round-trips for every enum value', () {
      for (final domain in ProgressionDomain.values) {
        expect(resolver.parseDomain(domain.name), equals(domain));
      }
    });

    test('parseDomain returns null for unknown / null input', () {
      expect(resolver.parseDomain(null), isNull);
      expect(resolver.parseDomain('not_a_domain'), isNull);
    });
  });
}

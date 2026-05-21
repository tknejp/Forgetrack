import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/features/progression_engine/domain/progression_domain_chrome.dart';

import 'package:forgetrack/features/progression_engine/domain/catalog/level_milestone_specs.dart';
import 'package:forgetrack/features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/features/progression_engine/domain/display/progression_display_models.dart';
import 'package:forgetrack/features/progression_engine/domain/display/progression_display_resolver.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
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

    test('levelDisplay above the level cap inherits the highest milestone', () {
      // Player past the level 100 cap keeps wearing the level-100 title +
      // rarity instead of dropping to a generic "Level N" fallback.
      final display = resolver.levelDisplay(9999);
      final top = kLevelMilestones.last;
      expect(display.level, 9999);
      expect(display.title(l10n), top.titleKey(l10n));
      expect(display.emoji, top.emoji);
      expect(display.rarity, top.rarity);
    });

    test('levelDisplay between milestones inherits the governing breakpoint',
        () {
      // Levels 2-4 don't have their own milestone spec — they should keep
      // the level-1 (Pilgrim) title + common rarity until the next
      // breakpoint at level 5 fires. Regression guard for the screen
      // header showing "Level 2 ⚔ LEVEL 2" with the default accent.
      for (final mid in [2, 3, 4]) {
        final display = resolver.levelDisplay(mid);
        final governing = kLevelMilestones.first;
        expect(display.level, mid);
        expect(display.title(l10n), governing.titleKey(l10n));
        expect(display.rarity, governing.rarity);
      }
    });

    test('levelMilestones yields one entry per spec in order', () {
      final milestones = resolver.levelMilestones().toList();
      expect(milestones, hasLength(kLevelMilestones.length));
      for (var i = 0; i < milestones.length; i++) {
        expect(milestones[i].level, kLevelMilestones[i].level);
        expect(milestones[i].emoji, kLevelMilestones[i].emoji);
        expect(
          milestones[i].cosmeticRewardIds,
          kLevelMilestones[i].cosmeticRewardIds,
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

    test('nodeDisplay populates accentColor for every V2 achievement node', () {
      // Smoke test: accentColor is required on NodeDisplay; if a future
      // resolver branch forgets to set it, this catches it.
      for (final node in const ProgressionEntryCatalog().build()) {
        if (node is! Achievement) continue;
        final display = resolver.nodeDisplay(node.id, l10n);
        expect(display, isNotNull, reason: 'no display for id=${node.id}');
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
        nodeId: ProgressionEntryId('mystery_id_42'),
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

    test(
      'returns a non-null formatted string for every V2 achievement node',
      () {
        // Smoke test: every real V2 Achievement must produce a summary
        // so friend cards never crash when rendering an unknown metric.
        for (final node in const ProgressionEntryCatalog().build()) {
          if (node is! Achievement) continue;
          final summary = resolver.compactSummary(node.id, l10n, locale);
          expect(
            summary,
            isNotNull,
            reason: 'compactSummary returned null for id=${node.id}',
          );
          expect(summary, isNotEmpty);
        }
      },
    );

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
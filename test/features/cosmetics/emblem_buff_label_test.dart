import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/cosmetics/domain/emblem_buff.dart';
import 'package:forgetrack/features/cosmetics/presentation/emblem_buff_label.dart';
import 'package:forgetrack/features/health_connect/domain/player_goal.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

Future<AppLocalizations> _loadEn() async {
  return AppLocalizations.delegate.load(const Locale('en'));
}

void main() {
  group('emblemBuffLabel', () {
    test('per-target buff yields the per-target metric line', () async {
      final l10n = await _loadEn();
      final label = emblemBuffLabel(
        const PerTargetEmblemBuff(
          target: DailyGoalTarget(GoalMetric.dailyCalories),
          percent: 10,
        ),
        l10n,
      );
      expect(label, isNotNull);
      expect(label, contains('10'));
      // Metric label is the canonical localized goal label.
      expect(label, contains(l10n.goalDailyCalories));
    });

    test('combo-quest per-target uses the combo metric label', () async {
      final l10n = await _loadEn();
      final label = emblemBuffLabel(
        const PerTargetEmblemBuff(target: ComboQuestTarget(), percent: 10),
        l10n,
      );
      expect(label, isNotNull);
      expect(label, contains(l10n.emblemBuffComboTarget));
    });

    test('targetWeight per-target names the daily weight-log event, '
        'not the body-weight setting', () async {
      final l10n = await _loadEn();
      final label = emblemBuffLabel(
        const PerTargetEmblemBuff(
          target: DailyGoalTarget(GoalMetric.targetWeight),
          percent: 10,
        ),
        l10n,
      );
      expect(label, isNotNull);
      expect(label, contains('10'));
      expect(label, contains(l10n.emblemBuffWeightLogTarget));
      expect(
        label,
        isNot(contains(l10n.goalTargetWeight)),
        reason: 'Emblem-side label resolver must name the XP-earning '
            'event ("daily weight log"), not the body-weight setting '
            '("Target weight") which Settings uses.',
      );
    });

    test('blanket buff yields the blanket line', () async {
      final l10n = await _loadEn();
      final label =
          emblemBuffLabel(const BlanketEmblemBuff(percent: 5), l10n);
      expect(label, isNotNull);
      expect(label, contains('5'));
      // Sanity: blanket label differs from a per-target line for the
      // same percent — they must read as distinct sentences so the
      // dragonrock emblem doesn't look like just-another per-target
      // buff to the player.
      final perTarget = emblemBuffLabel(
        const PerTargetEmblemBuff(
          target: DailyGoalTarget(GoalMetric.dailyCalories),
          percent: 5,
        ),
        l10n,
      );
      expect(label, isNot(equals(perTarget)));
    });
  });
}

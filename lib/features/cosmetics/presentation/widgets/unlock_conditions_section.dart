import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_unlock_rule.dart';

class UnlockConditionsSection extends StatelessWidget {
  const UnlockConditionsSection({
    super.key,
    required this.rules,
    required this.color,
  });

  final List<CosmeticUnlockRule> rules;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_open_rounded,
                size: 13, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 5),
            Text(
              l10n.cosmeticUnlockConditionsHeader,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < rules.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.listOrSeparator,
                style: tt.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.4),
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _RuleBlock(rule: rules[i], color: color),
        ],
      ],
    );
  }
}

class _RuleBlock extends StatelessWidget {
  const _RuleBlock({required this.rule, required this.color});

  final CosmeticUnlockRule rule;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule.sourceId != null
                ? AppLocalizations.of(context)
                    .ruleSource(rule.sourceType, rule.sourceId!)
                : 'source: ${rule.sourceType}',
            style: tt.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.6),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          for (final cond in rule.conditions)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_box_outline_blank_rounded,
                      size: 11,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      cond.id
                          .replaceAll('_at_least_', ' ≥ ')
                          .replaceAll('_', ' '),
                      style: tt.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

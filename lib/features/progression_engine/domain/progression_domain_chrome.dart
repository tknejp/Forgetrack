import 'package:flutter/material.dart'; // lint-ignore: domain-purity — ProgressionDomainChrome maps each ProgressionDomain to its Color + IconData tokens
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';

/// Presentation chrome (design-token pairing, Material icon, localised
/// label) for the pure [ProgressionDomain] enum.
///
/// The enum itself lives in `lib/domain/progression/catalog/` and
/// carries no Flutter / Material types so [Objective] can reference it
/// without dragging UI into the domain layer. This extension lives in
/// `presentation/` because every chrome accessor pulls in
/// `package:flutter/material.dart` (IconData, Color) or
/// `AppLocalizations` (l10n closures) — both belong on the UI side of
/// the domain / presentation boundary per
/// `docs/architecture.md` §Dependency rules.
///
/// See R.1 in `docs/domain_model/follow_ups.md` and ADR
/// `r1-catalog-domain-migration` in `docs/site/data/decisions.json`.
extension ProgressionDomainChrome on ProgressionDomain {
  /// Design-token pairing (color + dim variant) for this domain.
  Domain get token {
    switch (this) {
      case ProgressionDomain.steps:
        return Tokens.steps;
      case ProgressionDomain.nutrition:
        return Tokens.calories;
      case ProgressionDomain.sleep:
        return Tokens.sleep;
      case ProgressionDomain.activity:
        return Tokens.active;
      case ProgressionDomain.body:
        return Tokens.weight;
    }
  }

  /// Material icon for this domain.
  IconData get icon {
    switch (this) {
      case ProgressionDomain.steps:
        return Icons.directions_walk_rounded;
      case ProgressionDomain.nutrition:
        return Icons.restaurant_rounded;
      case ProgressionDomain.sleep:
        return Icons.nightlight_round;
      case ProgressionDomain.activity:
        return Icons.bolt_rounded;
      case ProgressionDomain.body:
        return Icons.monitor_weight_outlined;
    }
  }

  Color get color => token.color;
  Color get dim => token.dim;

  /// Localised display label.
  String label(AppLocalizations l10n) {
    switch (this) {
      case ProgressionDomain.steps:
        return l10n.progDomainSteps;
      case ProgressionDomain.nutrition:
        return l10n.progDomainNutrition;
      case ProgressionDomain.sleep:
        return l10n.progDomainSleep;
      case ProgressionDomain.activity:
        return l10n.progDomainActivity;
      case ProgressionDomain.body:
        return l10n.screenBody;
    }
  }
}

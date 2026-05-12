import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import 'localized_text.dart';

/// Visual + localized metadata for each progression domain.
///
/// Each domain carries its design-token pair, Material icon, and
/// localised label, so callers read `domain.label(l10n)`, `domain.token`,
/// `domain.color`, `domain.dim`, or `domain.icon` directly.
///
/// Moved from `lib/features/progression/domain/models/core_models.dart`
/// during Phase 9a so the V2 stack is fully decoupled from V1. Stored
/// values serialise as `.name`, so on-disk / cloud data is unaffected.
enum ProgressionDomain {
  steps(
    token: Tokens.steps,
    icon: Icons.directions_walk_rounded,
    label: _domainStepsLabel,
  ),
  nutrition(
    token: Tokens.calories,
    icon: Icons.restaurant_rounded,
    label: _domainNutritionLabel,
  ),
  sleep(
    token: Tokens.sleep,
    icon: Icons.nightlight_round,
    label: _domainSleepLabel,
  ),
  activity(
    token: Tokens.active,
    icon: Icons.bolt_rounded,
    label: _domainActivityLabel,
  ),
  body(
    token: Tokens.weight,
    icon: Icons.monitor_weight_outlined,
    label: _domainBodyLabel,
  );

  const ProgressionDomain({
    required this.token,
    required this.icon,
    required LocalizedText label,
  }) : _label = label;

  /// Design-token pairing (color + dim variant) for this domain.
  final Domain token;

  /// Material icon for this domain.
  final IconData icon;

  final LocalizedText _label;

  Color get color => token.color;
  Color get dim => token.dim;

  /// Localised display label.
  String label(AppLocalizations l10n) => _label(l10n);
}

String _domainStepsLabel(AppLocalizations l10n) => l10n.progDomainSteps;
String _domainNutritionLabel(AppLocalizations l10n) => l10n.progDomainNutrition;
String _domainSleepLabel(AppLocalizations l10n) => l10n.progDomainSleep;
String _domainActivityLabel(AppLocalizations l10n) => l10n.progDomainActivity;
String _domainBodyLabel(AppLocalizations l10n) => l10n.screenBody;

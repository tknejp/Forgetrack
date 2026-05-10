import '../../../l10n/app_localizations.dart';

/// Closure returning a localised string. Same shape as the legacy
/// `ProgressionLocalizedText`, defined inside the new engine so domain
/// models do not have to import legacy progression types.
///
/// Catalog entries pass closures (e.g. `(l) => l.progSteps10kTitle`) so
/// strings are resolved at render time and survive locale switches.
typedef LocalizedText = String Function(AppLocalizations l10n);

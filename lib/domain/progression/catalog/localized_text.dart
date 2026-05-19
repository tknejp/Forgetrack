import '../../../l10n/app_localizations.dart';

/// Closure returning a localised string. Catalog entries pass closures
/// (e.g. `(l) => l.progSteps10kTitle`) so strings are resolved at
/// render time and survive locale switches.
///
/// **Domain purity note.** `AppLocalizations` is a generated Flutter
/// class. The pure-Dart lint rule (test/lint/lint_matchers.dart)
/// guards `package:flutter/…` imports specifically; the `l10n/`
/// relative import is allowed because the catalog needs a way to
/// reference the strings table without owning the Flutter generation
/// pipeline. Proposal §6 ratifies this: "no AppLocalizations import —
/// pouze typedef `LocalizedText`."
typedef LocalizedText = String Function(AppLocalizations l10n);

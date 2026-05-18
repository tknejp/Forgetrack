// Phase 21 — pure-Dart lint matcher functions.
//
// Each matcher is a top-level function returning a sorted list of
// `file:line :: snippet` strings. They live here (not in a separate
// `tools/lints` package) because the project's lint discipline is
// enforced through grep-based unit tests (see
// `docs/contributing.md` §Lint matchers), not custom_lint plugins —
// keeps zero dev-deps + zero build-time impact per
// `docs/domain_model/migration_plan.md` §Phase 21 Rizika.
//
// **Invariants every matcher honours:**
//
// 1. Read-only — no file mutation.
// 2. Sorted output — stable diff for baseline comparison.
// 3. POSIX `/` path separators — tests run on Windows + Linux CI.
// 4. Skip `*.g.dart`, `*.freezed.dart`, `*.config.dart` — codegen
//    files are excluded from the analyzer (analysis_options.yaml)
//    and from human review.
// 5. Skip lines containing a `// lint-ignore: <rule-name>` trailer.
//    Per-line opt-out for cases where the rule genuinely doesn't
//    apply (e.g. test fixtures, deliberate adapter boundaries).

import 'dart:io';

/// Per-line opt-out marker. Lines containing this string skip every
/// matcher. Format: `// lint-ignore: <rule-name>`. The matcher does
/// NOT check the rule name — keep the suppression scoped + obvious
/// by writing the rule name inline.
const String lintIgnoreMarker = 'lint-ignore:';

/// Forbidden import prefixes that may not appear in any file under
/// `lib/domain/`. Domain layer ships zero runtime dependency on
/// Flutter, the provider tree, persistence backends, or platform
/// plugins (see `docs/architecture.md` §Dependency rules).
const List<String> forbiddenDomainImportPrefixes = <String>[
  'package:flutter/',
  'package:flutter_test/',
  'package:provider/',
  'package:firebase_core/',
  'package:firebase_auth/',
  'package:firebase_messaging/',
  'package:firebase_storage/',
  'package:cloud_firestore/',
  'package:isar/',
  'package:isar_flutter_libs/',
  'package:flutter_secure_storage/',
  'package:shared_preferences/',
  'package:workmanager/',
  'package:google_sign_in/',
  'package:health/',
  'package:http/',
  'package:googleapis/',
  'package:googleapis_auth/',
];

/// Per-line probe — true when [line] imports one of
/// [forbiddenDomainImportPrefixes]. Used both by the directory
/// scanner and the fixture-content tests.
bool isDomainPurityViolation(String line) {
  final trimmed = line.trim();
  if (!trimmed.startsWith('import ')) return false;
  for (final prefix in forbiddenDomainImportPrefixes) {
    if (trimmed.contains(prefix)) return true;
  }
  return false;
}

/// Walks every `.dart` file under [root] and returns lines that import
/// one of [forbiddenDomainImportPrefixes].
///
/// Mirrors the existing `test/domain_purity_test.dart` rule but
/// exposed as a callable for fixture-based tests + reuse.
List<String> findDomainPurityViolations(Directory root) {
  return _scan(
    root,
    (file, lineNo, line) =>
        isDomainPurityViolation(line) ? line.trim() : null,
  );
}

/// Matches `final String <camelCase>Id;` / `String <camelCase>Id =`
/// field or local declarations.
///
/// Domain identifiers in this codebase have typed value objects
/// (`QuestId`, `AchievementId`, `CosmeticId`, `ObjectiveId`,
/// `ProgressionEntryId`, …) per `docs/domain_model/proposal.md` §Q3.
/// String-typed identifier fields in `lib/domain/` or
/// `lib/features/*/domain/` defeat the typed-id discipline.
///
/// **Whitelist:** lines tagged `// lint-ignore: untyped-id` (e.g.
/// JournalEvent fields that genuinely hold raw persisted strings at
/// the storage boundary). Constructors / setters / formal parameters
/// are not matched.
final RegExp _untypedIdDeclarationRegex = RegExp(
  // (final|const|var)? whitespace 'String' whitespace <name>Id (= or ;)
  r'^\s*(final|const|var\s)?\s*String\s+\w*[Ii]d\s*[=;]',
);

bool isUntypedIdDeclaration(String line) =>
    _untypedIdDeclarationRegex.hasMatch(line);

List<String> findUntypedIdDeclarations(Directory root) {
  return _scan(
    root,
    (file, lineNo, line) =>
        isUntypedIdDeclaration(line) ? line.trim() : null,
  );
}

/// Matches `Text('<non-empty>')` / `Text("<non-empty>")` literals
/// anywhere under `lib/features/*/presentation/`.
///
/// Every visible string in this app must flow through
/// `AppLocalizations` (gen_l10n). Hard-coded literals break the
/// Czech / English flip and accumulate untranslatable copy. See
/// `CLAUDE.md` §Localization.
///
/// **Whitelist:**
///   * `Text('')` empty placeholders.
///   * Lines tagged `// lint-ignore: l10n-literal` (debug labels,
///     unit symbols intentionally shared across locales, etc.).
///   * Asset paths (`Text('assets/...')`) — already rare; opt-out
///     individually if needed.
final RegExp _textLiteralRegex =
    RegExp(r'''\bText\(\s*(['"])([^'"\n]+?)\1''');

bool isRawTextLiteralViolation(String line) {
  final match = _textLiteralRegex.firstMatch(line);
  if (match == null) return false;
  final literal = match.group(2)!;
  if (literal.isEmpty) return false;
  // Interpolated strings (`'${expr}'`) are not hard-coded copy —
  // the value comes from a variable, often an l10n getter.
  if (literal.contains(r'$')) return false;
  return true;
}

List<String> findRawTextLiterals(Directory root) {
  return _scan(
    root,
    (file, lineNo, line) =>
        isRawTextLiteralViolation(line) ? line.trim() : null,
  );
}

/// Matches collection-logic patterns (`.where(`, `.firstWhere(`,
/// `.singleWhere(`, `.indexWhere(`) in any file under
/// `lib/features/*/presentation/`.
///
/// Per `docs/domain_model/proposal.md` §7 (anti-pattern #1 + #8):
/// widgets must not derive state inline. Filtering / searching a
/// collection in `build()` belongs in an `application/` provider or
/// `domain/` derivation, cached + invalidated on the right notifier.
///
/// **Whitelist:** `// lint-ignore: widget-no-logic` per line. Common
/// legitimate uses (style maps, theme resolution) are also caught —
/// add the marker locally rather than relaxing the pattern.
final RegExp _widgetCollectionLogicRegex = RegExp(
  r'\.(where|firstWhere|singleWhere|indexWhere)\(',
);

bool isWidgetCollectionLogicViolation(String line) =>
    _widgetCollectionLogicRegex.hasMatch(line);

List<String> findWidgetCollectionLogic(Directory root) {
  return _scan(
    root,
    (file, lineNo, line) =>
        isWidgetCollectionLogicViolation(line) ? line.trim() : null,
  );
}

// ---------------------------------------------------------------------------
// Scan plumbing
// ---------------------------------------------------------------------------

typedef _LineProbe = String? Function(File file, int lineNo, String line);

/// Walks `*.dart` files under [root] and returns sorted
/// `relativePath:lineNo :: snippet` entries for every line where
/// [probe] returns non-null.
///
/// Excludes generated files (`*.g.dart`, `*.freezed.dart`,
/// `*.config.dart`) + per-line `lint-ignore:` suppressions.
List<String> _scan(Directory root, _LineProbe probe) {
  if (!root.existsSync()) return const [];

  final violations = <String>[];

  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.endsWith('.config.dart'));

  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(lintIgnoreMarker)) continue;
      final hit = probe(file, i + 1, line);
      if (hit == null) continue;
      final relative = file.path
          .replaceAll(r'\', '/')
          .replaceFirst(RegExp(r'^.*?/(lib|test)/'), r'$1/');
      violations.add('$relative:${i + 1} :: $hit');
    }
  }

  violations.sort();
  return violations;
}

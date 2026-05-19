// Phase 21 — production-code ratchet for the grep-based lint
// matchers in `lint_matchers.dart`.
//
// Each rule has a numeric **baseline** = the count of pre-existing
// violations at the time the matcher was introduced. The test fails
// when a violation is ADDED beyond the baseline; that's the ratchet
// — you can clean up, you cannot add more.
//
// When you fix a violation: just run the suite. If the test fails
// with "below baseline", lower the constant by the same amount in
// this file and commit. This is intentional friction so the drift
// is visible in PR diffs (single-int change).
//
// When a rule is genuinely inapplicable to one specific line: add a
// trailing `// lint-ignore: <rule-name>` marker on that line. The
// matchers skip ignored lines (see lint_matchers.dart §Invariants).
//
// **Rule slugs** for `lint-ignore:` markers:
//   domain-purity, untyped-id, l10n-literal, widget-no-logic.
//
// Existing-violation cleanup tracker:
//   docs/domain_model/follow_ups.md §Phase 21 cleanup queue.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'lint_matchers.dart';

// ---------------------------------------------------------------------------
// Baselines — calibrated 2026-05-19 by `test/lint/_baseline_probe.dart`.
//
// Lower these (never raise) as cleanup PRs land.
// ---------------------------------------------------------------------------

const int _baselineDomainPurityLibDomain = 0;
const int _baselineDomainPurityFeatureDomain = 0;
const int _baselineUntypedIdLibDomain = 0;
const int _baselineUntypedIdFeatureDomain = 0;
const int _baselineRawTextLiteral = 0;
const int _baselineWidgetCollectionLogic = 0;

void main() {
  group('Lint ratchets — production scan', () {
    test(
      'lib/domain/ stays zero-violation pure (strict, no baseline drift)',
      () {
        final violations = findDomainPurityViolations(Directory('lib/domain'));
        expect(
          violations,
          isEmpty,
          reason: _buildReason('domain-purity (lib/domain/)', violations),
        );
        expect(violations.length, _baselineDomainPurityLibDomain);
      },
    );

    test('lib/features/*/domain/ purity does not grow', () {
      final violations = _sumPerFeature('domain', findDomainPurityViolations);
      _assertRatchet(
        violations: violations,
        baseline: _baselineDomainPurityFeatureDomain,
        ruleSlug: 'domain-purity',
        scope: 'lib/features/*/domain/',
      );
    });

    test('lib/domain/ untyped-id field count does not grow', () {
      final violations =
          findUntypedIdDeclarations(Directory('lib/domain'));
      _assertRatchet(
        violations: violations,
        baseline: _baselineUntypedIdLibDomain,
        ruleSlug: 'untyped-id',
        scope: 'lib/domain/',
      );
    });

    test('lib/features/*/domain/ untyped-id field count does not grow', () {
      final violations =
          _sumPerFeature('domain', findUntypedIdDeclarations);
      _assertRatchet(
        violations: violations,
        baseline: _baselineUntypedIdFeatureDomain,
        ruleSlug: 'untyped-id',
        scope: 'lib/features/*/domain/',
      );
    });

    test('lib/features/*/presentation/ raw Text() literal count does not grow',
        () {
      final violations = _sumPerFeature('presentation', findRawTextLiterals);
      _assertRatchet(
        violations: violations,
        baseline: _baselineRawTextLiteral,
        ruleSlug: 'l10n-literal',
        scope: 'lib/features/*/presentation/',
      );
    });

    test(
        'lib/features/*/presentation/ widget collection-logic count does not grow',
        () {
      final violations =
          _sumPerFeature('presentation', findWidgetCollectionLogic);
      _assertRatchet(
        violations: violations,
        baseline: _baselineWidgetCollectionLogic,
        ruleSlug: 'widget-no-logic',
        scope: 'lib/features/*/presentation/',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _sumPerFeature(
  String subfolder,
  List<String> Function(Directory) probe,
) {
  final features = Directory('lib/features')
      .listSync()
      .whereType<Directory>()
      .map((d) => Directory('${d.path}/$subfolder'))
      .where((d) => d.existsSync());

  final all = <String>[];
  for (final dir in features) {
    all.addAll(probe(dir));
  }
  all.sort();
  return all;
}

void _assertRatchet({
  required List<String> violations,
  required int baseline,
  required String ruleSlug,
  required String scope,
}) {
  if (violations.length > baseline) {
    fail(_buildGrewMessage(
      ruleSlug: ruleSlug,
      scope: scope,
      baseline: baseline,
      actual: violations,
    ));
  }
  if (violations.length < baseline) {
    fail(_buildShrankMessage(
      ruleSlug: ruleSlug,
      scope: scope,
      baseline: baseline,
      newCount: violations.length,
    ));
  }
}

String _buildReason(String label, List<String> violations) {
  if (violations.isEmpty) return '$label clean.';
  return '$label found ${violations.length} violation(s):\n'
      '${violations.join('\n')}';
}

String _buildGrewMessage({
  required String ruleSlug,
  required String scope,
  required int baseline,
  required List<String> actual,
}) {
  final preview = actual.take(20).join('\n');
  return 'Lint ratchet GREW for "$ruleSlug" in $scope:\n'
      'baseline = $baseline, actual = ${actual.length}.\n'
      'Fix the new violation(s) before merging, or — when the new '
      'occurrence is genuinely correct — append '
      '`// lint-ignore: $ruleSlug` to the offending line.\n'
      'First 20 violations:\n$preview';
}

String _buildShrankMessage({
  required String ruleSlug,
  required String scope,
  required int baseline,
  required int newCount,
}) {
  return 'Lint ratchet for "$ruleSlug" in $scope is now $newCount '
      '(baseline $baseline). Cleanup detected — lower the baseline in '
      'test/lint/production_scan_test.dart to $newCount and commit '
      'the change alongside the cleanup.';
}

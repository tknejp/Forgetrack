// Architectural guard: `lib/domain/` must stay pure Dart.
//
// The domain layer is the single source of truth for catalog +
// lifecycle types and ships zero runtime dependencies on Flutter, the
// provider tree, persistence backends, or platform plugins. Any import
// that leaks one of those concerns belongs in `application/` or
// `data/`, not in `domain/`.
//
// See:
//   - docs/architecture.md §3 (Dependency rules)
//   - docs/domain_model/proposal.md §6.1
//   - docs/domain_model/migration_plan.md Phase 0
//
// When this test fails, the violator should be moved to a lower layer
// (application / data) or refactored to receive its data through plain
// Dart parameters instead of importing the offending package.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/domain/ contains no forbidden imports', () {
    final root = Directory('lib/domain');
    if (!root.existsSync()) {
      // Phase 0 ships the skeleton; later phases populate it. An absent
      // directory is treated as a no-op rather than a hard failure so a
      // mid-refactor checkout doesn't fail the suite.
      return;
    }

    // Forbidden import prefixes. Each entry blocks any import path that
    // contains it. Keep the list explicit — broad globs would catch
    // unrelated packages (e.g. `meta`, `collection`) that domain code
    // legitimately uses.
    const forbidden = <String>[
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

    final violations = <String>[];

    final dartFiles = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index].trim();
        if (!line.startsWith('import ')) continue;
        for (final prefix in forbidden) {
          if (line.contains(prefix)) {
            final relative = file.path
                .replaceAll(r'\', '/')
                .replaceFirst(RegExp(r'^.*/lib/'), 'lib/');
            violations.add('$relative:${index + 1} :: $line');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'lib/domain/ must stay pure. Forbidden imports found:\n'
          '${violations.join('\n')}\n\n'
          'Fix: move the offending file to lib/features/<f>/application/ or '
          'lib/features/<f>/data/, or refactor the function to take plain '
          'Dart parameters instead of importing the package.',
    );
  });
}

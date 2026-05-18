// Phase 21 — fixture coverage for grep-based lint matchers.
//
// Each matcher predicate (`isXxxViolation`) is exercised against
// inline good + bad cases. This proves the matcher *detects* the
// pattern + respects the `// lint-ignore:` opt-out, independent of
// whether production code currently has any violations.
//
// See `test/lint_fixtures/*.dart.txt` for the .dart-shaped fixtures
// — they're stored with `.dart.txt` extension so the analyzer
// doesn't try to compile the deliberately-broken code. The
// fixtures here are inline strings so the test is self-contained.

import 'package:flutter_test/flutter_test.dart';
import 'lint_matchers.dart';

void main() {
  group('isDomainPurityViolation', () {
    test('detects forbidden flutter import', () {
      expect(
        isDomainPurityViolation("import 'package:flutter/material.dart';"),
        isTrue,
      );
    });

    test('detects forbidden firebase + isar imports', () {
      expect(
        isDomainPurityViolation(
          "import 'package:cloud_firestore/cloud_firestore.dart';",
        ),
        isTrue,
      );
      expect(
        isDomainPurityViolation("import 'package:isar/isar.dart';"),
        isTrue,
      );
    });

    test('allows pure-Dart imports', () {
      expect(isDomainPurityViolation("import 'package:meta/meta.dart';"),
          isFalse);
      expect(isDomainPurityViolation("import 'dart:async';"), isFalse);
      expect(
        isDomainPurityViolation("import '../foo/bar.dart';"),
        isFalse,
      );
    });

    test('ignores non-import lines', () {
      expect(
        isDomainPurityViolation('// import package:flutter/material.dart;'),
        isFalse,
      );
      expect(isDomainPurityViolation('final x = 42;'), isFalse);
    });
  });

  group('isUntypedIdDeclaration', () {
    test('detects field declaration', () {
      expect(isUntypedIdDeclaration('  final String questId;'), isTrue);
      expect(
        isUntypedIdDeclaration('  final String achievementId = "abc";'),
        isTrue,
      );
    });

    test('detects various id suffix spellings', () {
      expect(isUntypedIdDeclaration('  String nodeId;'), isTrue);
      expect(isUntypedIdDeclaration('  String userID;'), isFalse);
      // `Id` followed by something else (no = / ;) → not a decl.
      expect(isUntypedIdDeclaration('  String questIdentifier = x;'),
          isFalse);
    });

    test('allows typed id wrappers', () {
      expect(
        isUntypedIdDeclaration('  final QuestId questId;'),
        isFalse,
      );
      expect(
        isUntypedIdDeclaration('  final AchievementId id;'),
        isFalse,
      );
    });

    test('allows non-id String fields', () {
      expect(isUntypedIdDeclaration('  final String name;'), isFalse);
      expect(isUntypedIdDeclaration('  final String label = "";'), isFalse);
    });
  });

  group('isRawTextLiteralViolation', () {
    test('detects single-quoted literal', () {
      expect(
        isRawTextLiteralViolation("Text('Hard-coded copy'),"),
        isTrue,
      );
    });

    test('detects double-quoted literal', () {
      expect(
        isRawTextLiteralViolation('Text("Hard-coded copy"),'),
        isTrue,
      );
    });

    test('allows empty placeholder', () {
      expect(isRawTextLiteralViolation("Text(''),"), isFalse);
      expect(isRawTextLiteralViolation('Text(""),'), isFalse);
    });

    test('allows interpolated / variable Text() calls', () {
      expect(
        isRawTextLiteralViolation('Text(l10n.welcomeMessage),'),
        isFalse,
      );
      expect(
        isRawTextLiteralViolation("Text('\${player.name}'),"),
        isFalse,
      );
    });
  });

  group('isWidgetCollectionLogicViolation', () {
    test('detects .where, .firstWhere, .singleWhere, .indexWhere', () {
      expect(
        isWidgetCollectionLogicViolation(
            '    final big = items.where((x) => x > 10).toList();'),
        isTrue,
      );
      expect(
        isWidgetCollectionLogicViolation(
            '    final first = items.firstWhere(predicate);'),
        isTrue,
      );
      expect(
        isWidgetCollectionLogicViolation(
            '    final only = items.singleWhere(predicate);'),
        isTrue,
      );
      expect(
        isWidgetCollectionLogicViolation(
            '    final ix = items.indexWhere(predicate);'),
        isTrue,
      );
    });

    test('does not match unrelated method calls', () {
      expect(
        isWidgetCollectionLogicViolation('    final x = items.length;'),
        isFalse,
      );
      expect(
        isWidgetCollectionLogicViolation(
            "    final y = items.map((x) => x + 1).toList();"),
        isFalse,
      );
    });
  });
}

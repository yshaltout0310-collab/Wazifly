// Contract + regression guard for the deterministic content fingerprints.
//
// Two things are asserted here:
//
//  1. The digest contract callers rely on — stable across calls, sensitive to
//     the input, and 16 hex characters wide (the width persisted alongside
//     stored CVs and used for learning-interest ids).
//  2. That no source file reintroduces a 64-bit integer literal. Dart on the
//     web compiles to JavaScript, whose numbers cannot represent integers
//     above 2^53 exactly, so a literal like `0xcbf29ce484222325` is a hard
//     `flutter build web` failure — one that only surfaces on the web target
//     and therefore never on a mobile-only CI run.
import 'dart:io';

import 'package:careerbridge/core/utils/stable_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stableHash', () {
    test('is deterministic for the same input', () {
      expect(stableHash('hello world'), stableHash('hello world'));
      expect(stableHashOfUnits(const [1, 2, 3]),
          stableHashOfUnits(const [1, 2, 3]));
    });

    test('is sensitive to the input', () {
      expect(stableHash('hello world'), isNot(stableHash('hello worlD')));
      expect(stableHashOfUnits(const [1, 2, 3]),
          isNot(stableHashOfUnits(const [1, 2, 4])));
    });

    test('is order-sensitive (the reverse lane must not cancel out)', () {
      expect(stableHashOfUnits(const [1, 2, 3]),
          isNot(stableHashOfUnits(const [3, 2, 1])));
    });

    test('is 16 lowercase hex characters, including for the empty input', () {
      for (final digest in [stableHash(''), stableHash('a'), stableHash('x' * 500)]) {
        expect(digest, matches(RegExp(r'^[0-9a-f]{16}$')), reason: digest);
      }
    });
  });

  test('no Dart source uses a web-unsafe 64-bit integer literal', () {
    // Hex literals wider than 13 digits exceed 2^52 and cannot be represented
    // exactly in JavaScript. Doc comments may still *mention* one (see
    // stable_hash.dart), so only code lines are considered.
    final offenders = <String>[];
    final literal = RegExp(r'0x[0-9a-fA-F]{14,}');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (literal.hasMatch(line)) {
          offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These literals break `flutter build web`. Use the 32-bit lanes '
          'in lib/core/utils/stable_hash.dart instead:\n${offenders.join('\n')}',
    );
  });
}

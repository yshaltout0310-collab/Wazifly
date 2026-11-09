import 'package:careerbridge/core/utils/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared password rules. Both password-creation paths (sign-up and Change
/// password) validate against this and render their checklist from it, so these
/// tests pin the single definition the UI and the validators agree on.
void main() {
  group('PasswordPolicy', () {
    test('accepts a password meeting every rule', () {
      expect(PasswordPolicy.isValid('passw0rdy'), isTrue);
      expect(PasswordPolicy.unmet('passw0rdy'), isEmpty);
    });

    test('reports each unmet rule, in display order', () {
      expect(PasswordPolicy.unmet(''), PasswordRule.values);
      expect(PasswordPolicy.unmet('abc'),
          [PasswordRule.minLength, PasswordRule.digit]);
      expect(PasswordPolicy.unmet('12345678'), [PasswordRule.letter]);
      expect(PasswordPolicy.unmet('abcdefgh'), [PasswordRule.digit]);
      expect(PasswordPolicy.unmet('abc12'), [PasswordRule.minLength]);
    });

    test('is Unicode-aware, so an Arabic password is not rejected outright', () {
      // The app ships Arabic. `[A-Za-z]` and `\d` would have failed both rules
      // for a perfectly good password written in Arabic letters and
      // Arabic-Indic digits.
      expect(PasswordPolicy.satisfies(PasswordRule.letter, 'كلمةالمرور'), isTrue);
      expect(PasswordPolicy.satisfies(PasswordRule.digit, '٤٢'), isTrue);
      expect(PasswordPolicy.isValid('كلمةمرور٤٢'), isTrue);
    });

    test('counts length in code points, not UTF-16 units', () {
      // Eight astral characters look like eight to the user; `String.length`
      // would call them sixteen and wave a 4-character password through.
      expect(PasswordPolicy.satisfies(PasswordRule.minLength, '😀😀😀😀'), isFalse);
    });

    test('minLength is above Firebase\'s own minimum of 6', () {
      expect(PasswordPolicy.minLength, greaterThan(6));
      expect(PasswordPolicy.satisfies(PasswordRule.minLength, 'ab3456'), isFalse);
    });
  });
}

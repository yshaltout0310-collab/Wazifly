/// One password requirement, as enforced and as shown in the live checklist.
enum PasswordRule { minLength, letter, digit }

/// The single place the app's password requirements are defined.
///
/// Both password-creation paths — sign-up (`EmailAuthScreen`) and Change
/// password (`ChangePasswordController`) — validate against this and render
/// their checklist from it, so what the user is *shown* can never drift from
/// what is *enforced*. Each path previously hard-coded `length < 6` separately
/// and neither displayed anything, so the only way to discover the requirement
/// was to violate it.
///
/// **Sign-in deliberately does not use this.** Checking a creation-time rule at
/// sign-in reported "Password must be at least 6 characters" for a wrong
/// password shorter than six — a local validator pre-empting the credentials
/// check, telling the user the wrong thing and never sending the request.
///
/// Mirror any change here in the Firebase Console password policy
/// (Authentication → Settings → Password policy) so client and backend agree.
/// Where they disagree, Firebase still has the last word: it rejects with
/// `weak-password`, which maps to [AuthErrorCode.weakPassword].
abstract final class PasswordPolicy {
  PasswordPolicy._();

  /// Minimum length. Above Firebase's own minimum of 6 — a platform holding
  /// CVs and contact details should not accept a six-character password.
  static const int minLength = 8;

  // Unicode-aware on purpose: the app ships Arabic, and an Arabic password
  // written in Arabic letters and Arabic-Indic digits satisfies "a letter" and
  // "a number" exactly as an English one does. `[A-Za-z]` / `\d` would have
  // silently rejected it.
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);

  static bool satisfies(PasswordRule rule, String password) => switch (rule) {
        PasswordRule.minLength => password.codePointLength >= minLength,
        PasswordRule.letter => _letter.hasMatch(password),
        PasswordRule.digit => _digit.hasMatch(password),
      };

  /// The rules [password] does not meet yet, in display order.
  static List<PasswordRule> unmet(String password) => [
        for (final rule in PasswordRule.values)
          if (!satisfies(rule, password)) rule,
      ];

  static bool isValid(String password) => unmet(password).isEmpty;
}

extension on String {
  /// Length in code points, so a password containing astral characters (an
  /// emoji, say) is not counted as twice as long as it looks. Named to avoid
  /// colliding with the `characters` package's `String.characters`.
  int get codePointLength => runes.length;
}

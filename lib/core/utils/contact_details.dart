/// Validation and normalization for the contact details collected at sign-up.
///
/// Kept here, pure and Flutter-free, for the same reason as [PasswordPolicy]:
/// the rules are enforced in a controller and displayed by a form, and the two
/// must not be able to drift. It is also the only way to unit-test them.
library;

/// Full name rules.
abstract final class FullNamePolicy {
  FullNamePolicy._();

  static const int minLength = 2;

  /// Hard upper bound, **matching `firestore.rules`**: the `users/{uid}` rule
  /// asserts `capped('displayName', 120)`, and `saveProfile`/`ensureProfile`
  /// swallow write failures — so a name over 120 characters would be rejected
  /// by the backend and silently lost. Validating here keeps the client and
  /// the rule in agreement instead of discovering it as missing data.
  static const int maxLength = 120;

  /// Collapses runs of whitespace and trims, so " Sarah   Ahmed " is stored as
  /// "Sarah Ahmed" rather than preserved verbatim.
  static String normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  static bool isValid(String raw) {
    final name = normalize(raw);
    if (name.length < minLength || name.length > maxLength) return false;
    // At least one letter, so "." or "12" is not accepted as a name. Unicode
    // aware: the app ships Arabic, and an Arabic name is a name.
    return RegExp(r'\p{L}', unicode: true).hasMatch(name);
  }
}

/// Phone number rules.
///
/// The number is collected as a **national** number beside a country dial code
/// (the pattern already used by phone verification), then stored in E.164 form.
abstract final class PhonePolicy {
  PhonePolicy._();

  /// Bounds on the national part, i.e. excluding the dial code. Deliberately
  /// wide: this is a global job platform, and national number lengths vary from
  /// 6 (small national plans) to 14 digits. A stricter per-country rule would
  /// reject legitimate numbers, which is a worse failure than accepting an
  /// unusual one — nothing here is a proof of ownership anyway.
  static const int minDigits = 6;
  static const int maxDigits = 14;

  /// Everything that is not a digit removed (the field also filters input, but
  /// paste and autofill can still deliver spaces, dashes or parentheses).
  static String digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  static bool isValidNational(String raw) {
    final digits = digitsOnly(raw);
    return digits.length >= minDigits && digits.length <= maxDigits;
  }

  /// Joins a dial code and a national number into E.164 (`+97450123456`).
  ///
  /// Returns null when either part is unusable, so a caller can never persist a
  /// half-formed number like `+` or `+974`.
  static String? compose({required String dialCode, required String national}) {
    final digits = digitsOnly(national);
    final code = digitsOnly(dialCode);
    if (code.isEmpty || !isValidNational(digits)) return null;
    return '+$code$digits';
  }
}

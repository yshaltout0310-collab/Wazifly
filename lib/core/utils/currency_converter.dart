/// Offline currency conversion + dual-currency display.
///
/// The app shows amounts in **QAR by default**; when a value's original currency
/// differs, it is shown as `QAR <converted> (~ <ORIG> <amount>)`. Rates are a
/// small static table expressed as *units per 1 USD*. The Gulf currencies
/// (QAR/AED/SAR/JOD) are **pegged** to the USD, so those conversions are exact;
/// the floating ones (EGP/EUR/GBP) are approximate — hence the "~" tilde in the
/// formatted output. No network, deterministic, and cheap.
class CurrencyConverter {
  const CurrencyConverter._();

  static const String defaultCurrency = 'QAR';

  /// Units of the currency per 1 USD. Gulf pegs are exact; others approximate.
  static const Map<String, double> _perUsd = {
    'USD': 1.0,
    'QAR': 3.64, // pegged
    'AED': 3.6725, // pegged
    'SAR': 3.75, // pegged
    'JOD': 0.709, // pegged
    'EGP': 49.0, // approximate (floating)
    'EUR': 0.92, // approximate
    'GBP': 0.79, // approximate
  };

  static bool isSupported(String currency) =>
      _perUsd.containsKey(currency.trim().toUpperCase());

  /// Converts [amount] from [from] to [to]. Returns null if either currency is
  /// unknown (caller should then fall back to showing the original only).
  static double? convert(num amount, String from, String to) {
    final f = _perUsd[from.trim().toUpperCase()];
    final t = _perUsd[to.trim().toUpperCase()];
    if (f == null || t == null || f == 0) return null;
    return amount * (t / f);
  }

  /// Formats [amount] in [currency], defaulting the primary display to [target]
  /// (QAR). When [currency] already is [target], shows just `QAR 4,368`. When it
  /// differs and is convertible, shows `QAR 4,368 (~ USD 1,200)`. When the
  /// currency is unknown, shows the original untouched (`SGD 1,200`).
  static String formatDual(num amount, String currency,
      {String target = defaultCurrency}) {
    final cur = currency.trim().toUpperCase();
    final tgt = target.trim().toUpperCase();
    if (cur == tgt || !isSupported(cur)) {
      return '$cur ${_money(amount)}';
    }
    final converted = convert(amount, cur, tgt);
    if (converted == null) return '$cur ${_money(amount)}';
    return '$tgt ${_money(converted)} (~ $cur ${_money(amount)})';
  }

  /// Whole-number amount with thousands separators (e.g. 4368 → "4,368").
  static String _money(num amount) {
    final rounded = amount.round();
    final digits = rounded.abs().toString();
    final buf = StringBuffer(rounded < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

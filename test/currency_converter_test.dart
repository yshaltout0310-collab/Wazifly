import 'package:careerbridge/core/utils/currency_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyConverter', () {
    test('converts USD to QAR at the peg (3.64)', () {
      expect(CurrencyConverter.convert(100, 'USD', 'QAR'), closeTo(364, 0.01));
    });

    test('formatDual shows QAR primary + original for a differing currency', () {
      // 120 USD * 3.64 = 436.8 -> rounds to 437.
      expect(CurrencyConverter.formatDual(120, 'USD'),
          'QAR 437 (~ USD 120)');
    });

    test('formatDual shows a single value when already QAR', () {
      expect(CurrencyConverter.formatDual(4368, 'QAR'), 'QAR 4,368');
    });

    test('formatDual leaves an unknown currency untouched', () {
      expect(CurrencyConverter.formatDual(1200, 'SGD'), 'SGD 1,200');
    });

    test('is case-insensitive on the currency code', () {
      expect(CurrencyConverter.formatDual(120, 'usd'), 'QAR 437 (~ USD 120)');
    });

    test('thousands are grouped', () {
      expect(CurrencyConverter.formatDual(1000000, 'QAR'), 'QAR 1,000,000');
    });
  });
}

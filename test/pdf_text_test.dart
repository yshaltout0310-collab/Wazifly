import 'package:careerbridge/features/cv_builder/data/templates/pdf_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// The bidi-safe primitives shared by every CV template. These encode the fix
/// for the "SQL" → "LQS" class of bug: the `pdf` package runs no page-level
/// bidi, so direction is chosen per string.
void main() {
  group('hasArabic', () {
    test('is false for Latin, digits and punctuation', () {
      expect(PdfText.hasArabic('SQL'), isFalse);
      expect(PdfText.hasArabic('sarah@cb.app'), isFalse);
      expect(PdfText.hasArabic('+974 5000 0000'), isFalse);
      expect(PdfText.hasArabic(''), isFalse);
    });

    test('is true for Arabic script', () {
      expect(PdfText.hasArabic('مهندسة برمجيات'), isTrue);
      expect(PdfText.hasArabic('الدوحة'), isTrue);
    });

    test('is true for mixed text containing any Arabic', () {
      expect(PdfText.hasArabic('Flutter و Dart'), isTrue);
    });
  });

  group('txt direction', () {
    pw.TextDirection dirOf(pw.Widget w) => (w as pw.Text).textDirection!;
    pw.TextAlign alignOf(pw.Widget w) => (w as pw.Text).textAlign!;

    const style = pw.TextStyle(fontSize: 10);

    test('a Latin run stays LTR even in an RTL document', () {
      // The regression this whole helper exists for: under a page-level RTL
      // direction the pdf package would emit "SQL" as "LQS".
      final w = PdfText.txt('SQL', style, rtlDoc: true);
      expect(dirOf(w), pw.TextDirection.ltr);
      // ...while still aligning to the document language.
      expect(alignOf(w), pw.TextAlign.right);
    });

    test('an Arabic run goes RTL', () {
      final w = PdfText.txt('مهندسة برمجيات', style, rtlDoc: true);
      expect(dirOf(w), pw.TextDirection.rtl);
    });

    test('an Arabic run is still RTL inside an LTR document', () {
      final w = PdfText.txt('الدوحة', style, rtlDoc: false);
      expect(dirOf(w), pw.TextDirection.rtl);
      expect(alignOf(w), pw.TextAlign.left);
    });

    test('a mixed line goes RTL but keeps its Latin runs readable', () {
      // The contact line: an Arabic city makes it RTL, and the email must not
      // come out reversed. Under RTL the pdf package reverses every run's
      // letters, so PdfText pre-reverses the Latin ones to cancel that out.
      const line = 'sarah@cb.app · الدوحة';
      final w = PdfText.txt(line, style, rtlDoc: true) as pw.Text;
      expect(w.textDirection, pw.TextDirection.rtl);
      expect(w.text.toPlainText(), contains('ppa.bc@haras')); // pre-reversed
      expect(w.text.toPlainText(), contains('الدوحة')); // Arabic left alone
    });

    test('a pure-Latin string is passed through untouched', () {
      // No Arabic => LTR => the pdf package applies no conversion, so the text
      // must NOT be pre-reversed.
      final w = PdfText.txt('Flutter · SQL', style, rtlDoc: false) as pw.Text;
      expect(w.textDirection, pw.TextDirection.ltr);
      expect(w.text.toPlainText(), 'Flutter · SQL');
    });

    test('digits inside a lettered run keep their order (regression: Bug #4)', () {
      // pdf reverses a lettered word's characters but treats a number as
      // atomic. Pre-reversing the digits too printed "yshaltout79@gmail.com" as
      // "yshaltout97@gmail.com" — a plausible-looking WRONG email on a real CV.
      const line = 'yshaltout79@gmail.com · الدوحة';
      final w = PdfText.txt(line, style, rtlDoc: true) as pw.Text;
      final out = w.text.toPlainText();
      // Letters reversed (so pdf restores them) but "79" stays "79".
      expect(out, contains('79'));
      expect(out, isNot(contains('97')));
      expect(out, contains('moc.liamg@79tuotlahsy'));
    });

    test('a multi-digit number inside a word is not transposed', () {
      const line = 'Python3 و COVID19 و الدوحة';
      final out =
          (PdfText.txt(line, style, rtlDoc: true) as pw.Text).text.toPlainText();
      expect(out, contains('3nohtyP')); // single digit: order irrelevant
      expect(out, contains('19DIVOC')); // "19" preserved, letters reversed
      expect(out, isNot(contains('91DIVOC')));
    });

    test('letterSpacing is dropped for Arabic but kept for Latin (Bug #5)', () {
      // Arabic is cursive — tracking shatters the joins ("الخبرات" as
      // "ا ل خ ب ر ا ت").
      const tracked = pw.TextStyle(fontSize: 10, letterSpacing: 1.8);
      final ar = PdfText.txt('الخبرات', tracked, rtlDoc: true) as pw.Text;
      expect((ar.text as pw.TextSpan).style!.letterSpacing, 0);

      final en = PdfText.txt('EXPERIENCE', tracked, rtlDoc: false) as pw.Text;
      expect((en.text as pw.TextSpan).style!.letterSpacing, 1.8);
    });

    test('align overrides the language-derived alignment', () {
      final w = PdfText.txt('Sarah Ahmed', style,
          rtlDoc: true, align: pw.TextAlign.center);
      expect(alignOf(w), pw.TextAlign.center);
    });
  });

  group('cleanUrl', () {
    test('strips scheme, www and any trailing slash', () {
      expect(PdfText.cleanUrl('https://www.github.com/sarah/'),
          startsWith('github.com'));
      expect(PdfText.cleanUrl('http://sarah.dev'), 'sarah.dev');
      expect(PdfText.cleanUrl('  https://sarah.dev/  '), 'sarah.dev');
    });

    test('keeps the path intact and inserts no zero-width spaces', () {
      // U+200B is not a break opportunity for the pdf package (it splits on
      // \s) and has no glyph in the bundled fonts, so it printed as a visible
      // .notdef box. Guard against it coming back.
      final cleaned = PdfText.cleanUrl('https://github.com/sarah/career-bridge');
      expect(cleaned, 'github.com/sarah/career-bridge');
      expect(cleaned, isNot(contains('​')));
    });
  });

  group('period', () {
    test('uses the localized "present" for a current role', () {
      expect(PdfText.period('2021', '', true, 'Present'), '2021 – Present');
      expect(PdfText.period('2021', '2024', false, 'Present'), '2021 – 2024');
    });

    test('drops empty parts', () {
      expect(PdfText.period('', '', false, 'Present'), '');
      expect(PdfText.period('2021', '', false, 'Present'), '2021');
    });
  });

  group('titleLine', () {
    test('joins the non-empty parts', () {
      expect(PdfText.titleLine(['Engineer', 'Northwind']),
          'Engineer — Northwind');
      expect(PdfText.titleLine(['Engineer', '']), 'Engineer');
      expect(PdfText.titleLine(['', '']), '');
    });
  });
}

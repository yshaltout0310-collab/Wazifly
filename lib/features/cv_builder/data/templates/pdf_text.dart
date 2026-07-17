import 'package:pdf/widgets.dart' as pw;

/// Bidi-safe text primitives shared by every CV template.
///
/// **Why this exists.** The `pdf` package gives you two directions and neither
/// one renders a mixed Arabic + Latin line correctly on its own:
///
/// * `TextDirection.ltr` emits the string as-is — fine for Latin, but Arabic is
///   left unshaped and unordered, i.e. broken.
/// * `TextDirection.rtl` reverses each lettered word's characters and places the
///   words right-to-left. That is exactly what Arabic needs — but it does the
///   same to Latin, so "Flutter" prints as "rettulF" and the phrase "Northwind
///   Apps" prints as "Apps Northwind".
///
/// So [txt] picks the direction per string, and for RTL strings additionally
/// pre-compensates the Latin runs so they survive that pass (see
/// [_preReverseLtrRuns]). A page-level direction is never set: it would force
/// one of the two behaviours onto every string on the page.
///
/// Structural RTL (which side a section/row starts on) is driven by the
/// surrounding layout — `crossAxisAlignment`, column order — never by a page
/// direction.
///
/// **Verify changes here by RENDERING, not by extracting text.** An RTL PDF's
/// text layer is stored in visual order, so `pdftotext` reports Latin reversed
/// whether or not it actually is — it will mislead you in both directions.
class PdfText {
  const PdfText._();

  /// True if [s] contains any Arabic-script character.
  static bool hasArabic(String s) {
    for (final r in s.runes) {
      if ((r >= 0x0600 && r <= 0x06FF) || // Arabic
          (r >= 0x0750 && r <= 0x077F) || // Arabic Supplement
          (r >= 0x08A0 && r <= 0x08FF) || // Arabic Extended-A
          (r >= 0xFB50 && r <= 0xFDFF) || // Arabic Presentation Forms-A
          (r >= 0xFE70 && r <= 0xFEFF)) {
        // Arabic Presentation Forms-B
        return true;
      }
    }
    return false;
  }

  /// Matches a left-to-right run: alphanumerics plus the punctuation and inner
  /// spaces that hold one together, so "Flutter", "Node.js", "sarah@cb.app",
  /// "+974 5000 0000" and the multi-word "Northwind Apps" are each ONE run.
  /// Anchored on alphanumerics at both ends so it never swallows the spaces or
  /// separators that sit between an LTR run and neighbouring Arabic.
  static final RegExp _ltrRun =
      RegExp(r'[A-Za-z0-9+][A-Za-z0-9 .@_+\-/:%#&?=~]*[A-Za-z0-9]|[A-Za-z0-9]');

  static final RegExp _latinLetter = RegExp(r'[A-Za-z]');
  static final RegExp _digitRun = RegExp(r'[0-9]+');

  /// Reverses [word]'s characters while keeping each digit sequence in its
  /// original order.
  ///
  /// `pdf` reverses a lettered word's characters but treats a number as an
  /// atomic unit and leaves it alone. So a run holding BOTH — an email like
  /// "yshaltout79@gmail.com" — must not have its digits pre-reversed: `pdf`
  /// would never reverse them back and they would print transposed
  /// ("yshaltout97@gmail.com"). Reversing token-wise, with each digit run as one
  /// token, cancels `pdf` exactly for letters and leaves numbers untouched.
  static String _reverseWordPreservingNumbers(String word) {
    final tokens = <String>[];
    var i = 0;
    while (i < word.length) {
      final m = _digitRun.matchAsPrefix(word, i);
      if (m != null) {
        tokens.add(m.group(0)!);
        i = m.end;
      } else {
        tokens.add(word[i]);
        i++;
      }
    }
    return tokens.reversed.join();
  }

  /// Pre-compensates each left-to-right run for what the `pdf` package does to
  /// it under a right-to-left direction, leaving Arabic untouched.
  ///
  /// Rendering an RTL line, `pdf` reverses the characters of each *lettered*
  /// word and places those words right-to-left. That is exactly how it positions
  /// Arabic — but it does the same to Latin, so untreated "Flutter" prints as
  /// "rettulF" and "Northwind Apps" as "Apps Northwind". Reversing a lettered
  /// run's word order *and* each word's characters cancels both passes exactly,
  /// leaving it reading normally inside the RTL line.
  ///
  /// Runs with no Latin letter (a phone, a year) are left ALONE: `pdf` resolves
  /// numbers correctly by itself, so compensating them would break them. Digits
  /// *inside* a lettered run are likewise preserved — see
  /// [_reverseWordPreservingNumbers].
  ///
  /// Verified by rendering (not by text extraction — an RTL PDF's text layer is
  /// stored in visual order, so extraction alone is misleading here).
  static String _preReverseLtrRuns(String s) =>
      s.replaceAllMapped(_ltrRun, (m) {
        final run = m.group(0)!;
        if (!_latinLetter.hasMatch(run)) return run;
        return run
            .split(' ')
            .reversed
            .map(_reverseWordPreservingNumbers)
            .join(' ');
      });

  /// A content [pw.Text] whose direction follows the text itself: a string with
  /// Arabic in it is laid out RTL (with its Latin runs kept readable — see
  /// [_preReverseLtrRuns]), anything else stays LTR untouched. The paragraph
  /// aligns to the document language ([rtlDoc]).
  ///
  /// Pass [align] to override the language-derived paragraph alignment (e.g. a
  /// centred academic header).
  ///
  /// Any `letterSpacing` on [style] is dropped for Arabic text: Arabic is
  /// cursive, so tracking pulls the joined letters apart and shatters the word
  /// ("الخبرات" printed as "ا ل خ ب ر ا ت"). Latin keeps its tracking.
  static pw.Widget txt(
    String text,
    pw.TextStyle style, {
    required bool rtlDoc,
    pw.TextAlign? align,
  }) {
    final rtl = hasArabic(text);
    return pw.Text(
      rtl ? _preReverseLtrRuns(text) : text,
      style: rtl ? style.copyWith(letterSpacing: 0) : style,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      textAlign: align ?? (rtlDoc ? pw.TextAlign.right : pw.TextAlign.left),
    );
  }

  /// Strips the scheme / `www.` / trailing slash so a long profile URL is short
  /// enough to fit on one line. Templates additionally give each link its own
  /// line — together that is what keeps links inside the page width.
  ///
  /// NOTE: this deliberately inserts no zero-width spaces after the slashes.
  /// They looked like free break opportunities but were harmful on both counts:
  /// `pdf` breaks lines on whitespace (`\s`), which excludes U+200B, so they
  /// added no break at all — and neither bundled font has a glyph for U+200B, so
  /// each one printed as a visible .notdef box ("sarah.dev/▯portfolio").
  static String cleanUrl(String url) {
    var u = url.trim();
    u = u.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    u = u.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    u = u.replaceFirst(RegExp(r'/+$'), '');
    return u;
  }

  /// The period line for an experience entry ("2021 – Present").
  static String period(
    String start,
    String end,
    bool current,
    String present,
  ) {
    final e = current ? present : end;
    return [start, e].where((s) => s.isNotEmpty).join(' – ');
  }

  /// Joins the non-empty parts of a title line ("Role — Company").
  static String titleLine(List<String> parts) =>
      parts.where((s) => s.isNotEmpty).join(' — ');
}

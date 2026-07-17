import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// The font set a template draws with: a Latin pair (LTR) and an Arabic pair
/// (RTL). Kept as an injected value so templates are deterministic and unit
/// tests can pass the built-in fonts (no network).
class CvFonts {
  const CvFonts({
    required this.base,
    required this.baseBold,
    required this.arabic,
    required this.arabicBold,
    this.preferArabic = false,
  });

  final pw.Font base;
  final pw.Font baseBold;
  final pw.Font arabic;
  final pw.Font arabicBold;

  /// Forces [regular]/[bold] to the Arabic face even when the document language
  /// is not Arabic — set when the CV's *content* contains Arabic.
  ///
  /// The document's base font drives `pdf`'s Arabic shaping and bidi pass, and
  /// picking it from the app language alone meant an Arabic CV written while the
  /// app was in English got a Latin base font and rendered garbled. The choice
  /// has to follow the text, not the locale.
  final bool preferArabic;

  pw.Font regular(bool rtl) => (rtl || preferArabic) ? arabic : base;
  pw.Font bold(bool rtl) => (rtl || preferArabic) ? arabicBold : baseBold;

  /// Ensures glyphs from the *other* script still render (e.g. a Latin email in
  /// an Arabic CV, or an Arabic name in an English CV). Unaffected by
  /// [preferArabic] — both faces stay reachable either way.
  List<pw.Font> get fallback => [base, arabic];

  CvFonts withPreferArabic(bool value) => CvFonts(
        base: base,
        baseBold: baseBold,
        arabic: arabic,
        arabicBold: arabicBold,
        preferArabic: value,
      );

  /// Built-in standard fonts — no network. Latin-only (used as a resilient
  /// fallback and in tests).
  factory CvFonts.builtIn() {
    final r = pw.Font.helvetica();
    final b = pw.Font.helveticaBold();
    return CvFonts(base: r, baseBold: b, arabic: r, arabicBold: b);
  }

  /// Loads Noto Sans (+ Arabic) via the `printing` Google-Fonts cache. Falls
  /// back to the built-in fonts if fetching fails (offline), so export never
  /// hard-fails — Latin CVs still render.
  static Future<CvFonts> load() async {
    try {
      final fonts = await Future.wait([
        PdfGoogleFonts.notoSansRegular(),
        PdfGoogleFonts.notoSansBold(),
        PdfGoogleFonts.notoSansArabicRegular(),
        PdfGoogleFonts.notoSansArabicBold(),
      ]);
      return CvFonts(
        base: fonts[0],
        baseBold: fonts[1],
        arabic: fonts[2],
        arabicBold: fonts[3],
      );
    } catch (_) {
      return CvFonts.builtIn();
    }
  }
}

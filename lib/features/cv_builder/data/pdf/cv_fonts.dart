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
  });

  final pw.Font base;
  final pw.Font baseBold;
  final pw.Font arabic;
  final pw.Font arabicBold;

  pw.Font regular(bool rtl) => rtl ? arabic : base;
  pw.Font bold(bool rtl) => rtl ? arabicBold : baseBold;

  /// Ensures glyphs from the *other* script still render (e.g. a Latin email in
  /// an Arabic CV, or an Arabic name in an English CV).
  List<pw.Font> get fallback => [base, arabic];

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

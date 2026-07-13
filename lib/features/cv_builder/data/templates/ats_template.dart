import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../pdf/cv_fonts.dart';
import 'pdf_template.dart';

/// ATS-friendly single-column CV: standard fonts, clear text section headers,
/// no tables/columns/graphics — maximally parseable by applicant-tracking
/// systems while staying clean and professional.
///
/// **Bidirectional text:** the `pdf` package does NOT run the Unicode bidi
/// algorithm — under a right-to-left page direction it simply emits glyphs
/// right-to-left, which reverses pure-Latin runs (e.g. "SQL" → "LQS"). So rather
/// than set one page-level direction, every content string is rendered through
/// [_txt], which picks the direction from the text itself (Latin stays LTR,
/// Arabic goes RTL) while aligning the paragraph to the document language. This
/// keeps English technical terms, URLs and emails correct inside an Arabic CV.
class AtsTemplate implements PdfTemplate {
  const AtsTemplate();

  static const PdfColor _accent = PdfColor.fromInt(0xFF0E9F6E); // emerald brand
  static const PdfColor _muted = PdfColor.fromInt(0xFF555555);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _rule = PdfColor.fromInt(0xFFDDDDDD);

  // Shared text styles (const so the whole tree stays allocation-light).
  static const _nameStyle =
      pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _ink);
  static const _headlineStyle = pw.TextStyle(fontSize: 12, color: _accent);
  static const _metaStyle = pw.TextStyle(fontSize: 9.5, color: _muted);
  static const _italicMeta = pw.TextStyle(
      fontSize: 9.5, color: _muted, fontStyle: pw.FontStyle.italic);
  static const _sectionStyle = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      color: _accent,
      letterSpacing: 0.6);
  static const _titleStyle =
      pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink);
  static const _bodyStyle =
      pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 1.6);
  static const _bodyTight =
      pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 1.4);
  static const _bulletMark = pw.TextStyle(fontSize: 10, color: _accent);

  @override
  pw.Document build(
    CvData data, {
    required CvLabels labels,
    required CvFonts fonts,
    required bool rtl,
  }) {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular(rtl),
        bold: fonts.bold(rtl),
        fontFallback: fonts.fallback,
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // NOTE: no page-level textDirection — direction is decided per string by
        // [_txt] so Latin runs are never reversed. Structural RTL (which side a
        // section/row starts on) is driven by crossAxisAlignment below.
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) => [
          _header(data, rtl: rtl),
          if (data.summary.trim().isNotEmpty)
            _section(labels.summary, [_paragraph(data.summary, rtl: rtl)],
                rtl: rtl),
          if (data.experiences.any((e) => !e.isBlank))
            _section(
              labels.experience,
              data.experiences
                  .where((e) => !e.isBlank)
                  .map((e) => _experience(e, labels, rtl))
                  .toList(),
              rtl: rtl,
            ),
          if (data.education.any((e) => !e.isBlank))
            _section(
              labels.education,
              data.education
                  .where((e) => !e.isBlank)
                  .map((e) => _education(e, rtl))
                  .toList(),
              rtl: rtl,
            ),
          if (data.skills.isNotEmpty)
            _section(labels.skills,
                [_paragraph(data.skills.join('  ·  '), rtl: rtl)],
                rtl: rtl),
          if (data.projects.any((p) => !p.isBlank))
            _section(
              labels.projects,
              data.projects
                  .where((p) => !p.isBlank)
                  .map((p) => _project(p, rtl))
                  .toList(),
              rtl: rtl,
            ),
        ],
      ),
    );
    return doc;
  }

  // --- Bidi-safe text ---

  /// True if [s] contains any Arabic-script character.
  static bool _hasArabic(String s) {
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

  /// A content [pw.Text] whose glyph order follows the text (Latin → LTR so
  /// "SQL" never reverses; Arabic → RTL) while the paragraph aligns to the
  /// document language ([rtlDoc]). Pass [forceLtr] for predominantly-Latin lines
  /// that may contain an Arabic token (e.g. a contact line with an Arabic city)
  /// so the Latin email/phone are not reordered.
  static pw.Widget _txt(
    String text,
    pw.TextStyle style, {
    required bool rtlDoc,
    bool forceLtr = false,
  }) {
    final ltr = forceLtr || !_hasArabic(text);
    return pw.Text(
      text,
      style: style,
      textDirection: ltr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
      textAlign: rtlDoc ? pw.TextAlign.right : pw.TextAlign.left,
    );
  }

  /// Strips the scheme / `www.` / trailing slash so a long profile URL is short
  /// enough to fit on one line, and adds zero-width break points after slashes
  /// so any remaining long path can still wrap instead of overflowing.
  static String _cleanUrl(String url) {
    var u = url.trim();
    u = u.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    u = u.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
    u = u.replaceFirst(RegExp(r'/+$'), '');
    // Zero-width space after each slash gives long paths a break opportunity so
    // they wrap instead of overflowing the page width.
    return u.replaceAll('/', '/​');
  }

  // --- Header (name, headline, contact, links) ---

  pw.Widget _header(CvData data, {required bool rtl}) {
    final align =
        rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final contact = [
      if (data.email.isNotEmpty) data.email,
      if (data.phone.isNotEmpty) data.phone,
      if (data.location.isNotEmpty) data.location,
    ].join('  ·  ');
    final links = [
      if (data.portfolioUrl.isNotEmpty) _cleanUrl(data.portfolioUrl),
      if (data.githubUrl.isNotEmpty) _cleanUrl(data.githubUrl),
      if (data.linkedinUrl.isNotEmpty) _cleanUrl(data.linkedinUrl),
    ];

    return pw.Column(
      crossAxisAlignment: align,
      children: [
        _txt(data.fullName.isEmpty ? ' ' : data.fullName, _nameStyle,
            rtlDoc: rtl),
        if (data.headline.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          _txt(data.headline, _headlineStyle, rtlDoc: rtl),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          // Contact is Latin-dominant (email/phone); force LTR so those are not
          // reordered even when an Arabic city name is present.
          _txt(contact, _metaStyle, rtlDoc: rtl, forceLtr: true),
        ],
        // Each profile link on its own line (scheme-stripped) instead of one
        // long joined line that overflowed the page width.
        if (links.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          for (final link in links) _txt(link, _metaStyle, rtlDoc: rtl),
        ],
        pw.SizedBox(height: 10),
      ],
    );
  }

  // --- Generic section wrapper (heading + rule + content) ---

  pw.Widget _section(String title, List<pw.Widget> children,
      {required bool rtl}) {
    return pw.Column(
      crossAxisAlignment:
          rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 6),
        _txt(title.toUpperCase(), _sectionStyle, rtlDoc: rtl),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 3, bottom: 6),
          height: 1,
          color: _rule,
        ),
        ...children,
      ],
    );
  }

  pw.Widget _paragraph(String text, {required bool rtl}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: _txt(text, _bodyStyle, rtlDoc: rtl),
      );

  // --- Experience entry ---

  pw.Widget _experience(CvExperience e, CvLabels labels, bool rtl) {
    final period = _period(e.startDate, e.endDate, e.current, labels.present);
    final titleLine = [e.role, e.company].where((s) => s.isNotEmpty).join(' — ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _txt(titleLine, _titleStyle, rtlDoc: rtl)),
              if (period.isNotEmpty) _txt(period, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (e.location.isNotEmpty) _txt(e.location, _italicMeta, rtlDoc: rtl),
          pw.SizedBox(height: 2),
          for (final b in e.bullets.where((b) => b.trim().isNotEmpty))
            _bullet(b, rtl),
        ],
      ),
    );
  }

  pw.Widget _bullet(String text, bool rtl) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5, top: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  ', style: _bulletMark),
            pw.Expanded(child: _txt(text, _bodyTight, rtlDoc: rtl)),
          ],
        ),
      );

  // --- Education entry ---

  pw.Widget _education(CvEducation e, bool rtl) {
    final years =
        [e.startYear, e.endYear].where((s) => s.isNotEmpty).join(' – ');
    final titleLine =
        [e.degree, e.institution].where((s) => s.isNotEmpty).join(' — ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: _txt(titleLine, _titleStyle, rtlDoc: rtl)),
              if (years.isNotEmpty) _txt(years, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (e.details.isNotEmpty) _txt(e.details, _bodyTight, rtlDoc: rtl),
        ],
      ),
    );
  }

  // --- Project entry ---

  pw.Widget _project(CvProject p, bool rtl) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment:
              rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
          children: [
            _txt(p.name, _titleStyle, rtlDoc: rtl),
            if (p.description.isNotEmpty)
              _txt(p.description, _bodyTight, rtlDoc: rtl),
            if (p.link.isNotEmpty) _txt(_cleanUrl(p.link), _metaStyle, rtlDoc: rtl),
          ],
        ),
      );

  String _period(String start, String end, bool current, String present) {
    final e = current ? present : end;
    return [start, e].where((s) => s.isNotEmpty).join(' – ');
  }
}

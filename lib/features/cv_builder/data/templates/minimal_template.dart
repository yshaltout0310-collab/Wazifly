import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../pdf/cv_fonts.dart';
import 'pdf_template.dart';
import 'pdf_text.dart';

/// Minimal single-column CV: monochrome, no rules or fills, wide margins and
/// generous whitespace. Hierarchy comes from weight, size and letter-spacing
/// alone — section headings are small, light and widely tracked.
///
/// **Bidirectional text:** every content string goes through [PdfText.txt] —
/// see [PdfText] for why a page-level direction is never set.
class MinimalTemplate implements PdfTemplate {
  const MinimalTemplate();

  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _muted = PdfColor.fromInt(0xFF707070);
  static const PdfColor _faint = PdfColor.fromInt(0xFF9A9A9A);

  static const _nameStyle = pw.TextStyle(
      fontSize: 20, fontWeight: pw.FontWeight.bold, color: _ink, letterSpacing: 0.4);
  static const _headlineStyle =
      pw.TextStyle(fontSize: 10.5, color: _muted, letterSpacing: 0.2);
  static const _metaStyle = pw.TextStyle(fontSize: 9, color: _muted);
  // NOTE: no italic anywhere in this template. The document theme carries only
  // a regular + bold Arabic face, so `FontStyle.italic` falls back to a Latin
  // oblique font that cannot shape Arabic (and bypasses the RTL text path).
  static const _faintMeta = pw.TextStyle(fontSize: 9, color: _faint);
  static const _sectionStyle = pw.TextStyle(
      fontSize: 8.5, color: _faint, letterSpacing: 1.8);
  static const _titleStyle =
      pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _ink);
  static const _bodyStyle =
      pw.TextStyle(fontSize: 9.5, color: _ink, lineSpacing: 2.0);
  static const _bodyTight =
      pw.TextStyle(fontSize: 9.5, color: _ink, lineSpacing: 1.8);
  static const _bulletMark = pw.TextStyle(fontSize: 9.5, color: _faint);

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
        // Wide margins are the whole point of this template.
        margin: const pw.EdgeInsets.symmetric(horizontal: 64, vertical: 56),
        build: (context) => [
          _header(data, rtl: rtl),
          if (data.summary.trim().isNotEmpty)
            _section(labels.summary, [
              PdfText.txt(data.summary, _bodyStyle, rtlDoc: rtl),
            ], rtl),
          if (data.experiences.any((e) => !e.isBlank))
            _section(
              labels.experience,
              data.experiences
                  .where((e) => !e.isBlank)
                  .map((e) => _experience(e, labels, rtl))
                  .toList(),
              rtl,
            ),
          if (data.education.any((e) => !e.isBlank))
            _section(
              labels.education,
              data.education
                  .where((e) => !e.isBlank)
                  .map((e) => _education(e, rtl))
                  .toList(),
              rtl,
            ),
          if (data.skills.isNotEmpty)
            _section(labels.skills, [
              PdfText.txt(data.skills.join('   ·   '), _bodyTight, rtlDoc: rtl),
            ], rtl),
          if (data.projects.any((p) => !p.isBlank))
            _section(
              labels.projects,
              data.projects
                  .where((p) => !p.isBlank)
                  .map((p) => _project(p, rtl))
                  .toList(),
              rtl,
            ),
        ],
      ),
    );
    return doc;
  }

  // --- Header ---

  pw.Widget _header(CvData data, {required bool rtl}) {
    final contact = [
      if (data.email.isNotEmpty) data.email,
      if (data.phone.isNotEmpty) data.phone,
      if (data.location.isNotEmpty) data.location,
    ].join('   ·   ');
    final links = [
      if (data.portfolioUrl.isNotEmpty) PdfText.cleanUrl(data.portfolioUrl),
      if (data.githubUrl.isNotEmpty) PdfText.cleanUrl(data.githubUrl),
      if (data.linkedinUrl.isNotEmpty) PdfText.cleanUrl(data.linkedinUrl),
    ];

    return pw.Column(
      crossAxisAlignment:
          rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        _fullWidth,
        PdfText.txt(data.fullName.isEmpty ? ' ' : data.fullName, _nameStyle,
            rtlDoc: rtl),
        if (data.headline.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          PdfText.txt(data.headline, _headlineStyle, rtlDoc: rtl),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          // Direction follows the text: an Arabic city makes this line RTL with
          // the email/phone kept readable; a pure-Latin line stays LTR.
          PdfText.txt(contact, _metaStyle, rtlDoc: rtl),
        ],
        // One link per line — a joined line of long URLs overflows the width.
        if (links.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          for (final l in links) PdfText.txt(l, _metaStyle, rtlDoc: rtl),
        ],
        pw.SizedBox(height: 8),
      ],
    );
  }

  /// A zero-height full-width child. This template draws no rules or fills, so
  /// without it a section Column shrink-wraps to its widest line and its
  /// `crossAxisAlignment` then aligns within *that* box rather than the page —
  /// headings would drift instead of sitting on the page edge (very visible in
  /// RTL). Kept as a child rather than a wrapping Container so the Column stays
  /// a spanning widget and can still break across pages.
  static final pw.Widget _fullWidth =
      pw.SizedBox(width: double.infinity, height: 0);

  // --- Section (heading + content, no rule) ---

  pw.Widget _section(String title, List<pw.Widget> children, bool rtl) =>
      pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          _fullWidth,
          pw.SizedBox(height: 16),
          PdfText.txt(title.toUpperCase(), _sectionStyle, rtlDoc: rtl),
          pw.SizedBox(height: 8),
          ...children,
        ],
      );

  // --- Entries ---

  pw.Widget _experience(CvExperience e, CvLabels labels, bool rtl) {
    final period =
        PdfText.period(e.startDate, e.endDate, e.current, labels.present);
    final titleLine = PdfText.titleLine([e.role, e.company]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child: PdfText.txt(titleLine, _titleStyle, rtlDoc: rtl)),
              if (period.isNotEmpty)
                PdfText.txt(period, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (e.location.isNotEmpty)
            PdfText.txt(e.location, _faintMeta, rtlDoc: rtl),
          pw.SizedBox(height: 3),
          for (final b in e.bullets.where((b) => b.trim().isNotEmpty))
            _bullet(b, rtl),
        ],
      ),
    );
  }

  pw.Widget _bullet(String text, bool rtl) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2, top: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('–  ', style: _bulletMark),
            pw.Expanded(child: PdfText.txt(text, _bodyTight, rtlDoc: rtl)),
          ],
        ),
      );

  pw.Widget _education(CvEducation e, bool rtl) {
    final years =
        [e.startYear, e.endYear].where((s) => s.isNotEmpty).join(' – ');
    final titleLine = PdfText.titleLine([e.degree, e.institution]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                  child: PdfText.txt(titleLine, _titleStyle, rtlDoc: rtl)),
              if (years.isNotEmpty) PdfText.txt(years, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (e.details.isNotEmpty)
            PdfText.txt(e.details, _bodyTight, rtlDoc: rtl),
        ],
      ),
    );
  }

  pw.Widget _project(CvProject p, bool rtl) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment:
              rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
          children: [
            PdfText.txt(p.name, _titleStyle, rtlDoc: rtl),
            if (p.description.isNotEmpty)
              PdfText.txt(p.description, _bodyTight, rtlDoc: rtl),
            if (p.link.isNotEmpty)
              PdfText.txt(PdfText.cleanUrl(p.link), _metaStyle, rtlDoc: rtl),
          ],
        ),
      );
}

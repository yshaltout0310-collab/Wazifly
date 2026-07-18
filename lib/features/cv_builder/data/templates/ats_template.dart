import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../pdf/cv_fonts.dart';
import 'pdf_template.dart';
import 'pdf_text.dart';

/// ATS-friendly single-column CV: standard fonts, clear text section headers,
/// no tables/columns/graphics — maximally parseable by applicant-tracking
/// systems while staying clean and professional.
///
/// **Bidirectional text:** every content string goes through [PdfText.txt],
/// which picks the direction from the text itself so English technical terms,
/// URLs and emails stay correct inside an Arabic CV — see [PdfText] for why a
/// page-level direction is never set.
class AtsTemplate implements PdfTemplate {
  const AtsTemplate();

  static const PdfColor _accent =
      PdfColor.fromInt(0xFF1677FF); // Wazifly Royal Blue
  static const PdfColor _muted = PdfColor.fromInt(0xFF555555);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _rule = PdfColor.fromInt(0xFFDDDDDD);

  // Shared text styles (const so the whole tree stays allocation-light).
  static const _nameStyle =
      pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _ink);
  static const _headlineStyle = pw.TextStyle(fontSize: 12, color: _accent);
  // NOTE: no italic anywhere in this template. The document theme carries only a
  // regular + bold Arabic face, so `FontStyle.italic` falls back to a Latin
  // oblique that cannot shape Arabic and bypasses the RTL text path — an Arabic
  // location printed as reversed, disconnected letters ("الدوحة" → "ةحودلا").
  static const _metaStyle = pw.TextStyle(fontSize: 9.5, color: _muted);
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
        // [PdfText.txt] so Latin runs are never reversed. Structural RTL (which
        // side a section/row starts on) is driven by crossAxisAlignment below.
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
      if (data.portfolioUrl.isNotEmpty) PdfText.cleanUrl(data.portfolioUrl),
      if (data.githubUrl.isNotEmpty) PdfText.cleanUrl(data.githubUrl),
      if (data.linkedinUrl.isNotEmpty) PdfText.cleanUrl(data.linkedinUrl),
    ];

    return pw.Column(
      crossAxisAlignment: align,
      children: [
        PdfText.txt(data.fullName.isEmpty ? ' ' : data.fullName, _nameStyle,
            rtlDoc: rtl),
        if (data.headline.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          PdfText.txt(data.headline, _headlineStyle, rtlDoc: rtl),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          // Direction follows the text: an Arabic city makes this line RTL with
          // the email/phone kept readable; a pure-Latin line stays LTR.
          PdfText.txt(contact, _metaStyle, rtlDoc: rtl),
        ],
        // Each profile link on its own line (scheme-stripped) instead of one
        // long joined line that overflowed the page width.
        if (links.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          for (final link in links) PdfText.txt(link, _metaStyle, rtlDoc: rtl),
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
        PdfText.txt(title.toUpperCase(), _sectionStyle, rtlDoc: rtl),
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
        child: PdfText.txt(text, _bodyStyle, rtlDoc: rtl),
      );

  // --- Experience entry ---

  pw.Widget _experience(CvExperience e, CvLabels labels, bool rtl) {
    final period =
        PdfText.period(e.startDate, e.endDate, e.current, labels.present);
    final titleLine = PdfText.titleLine([e.role, e.company]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: PdfText.txt(titleLine, _titleStyle, rtlDoc: rtl)),
              if (period.isNotEmpty) PdfText.txt(period, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (e.location.isNotEmpty)
            PdfText.txt(e.location, _metaStyle, rtlDoc: rtl),
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
            pw.Expanded(child: PdfText.txt(text, _bodyTight, rtlDoc: rtl)),
          ],
        ),
      );

  // --- Education entry ---

  pw.Widget _education(CvEducation e, bool rtl) {
    final years =
        [e.startYear, e.endYear].where((s) => s.isNotEmpty).join(' – ');
    final titleLine = PdfText.titleLine([e.degree, e.institution]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: PdfText.txt(titleLine, _titleStyle, rtlDoc: rtl)),
              if (years.isNotEmpty) PdfText.txt(years, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (e.details.isNotEmpty) PdfText.txt(e.details, _bodyTight, rtlDoc: rtl),
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
            PdfText.txt(p.name, _titleStyle, rtlDoc: rtl),
            if (p.description.isNotEmpty)
              PdfText.txt(p.description, _bodyTight, rtlDoc: rtl),
            if (p.link.isNotEmpty)
              PdfText.txt(PdfText.cleanUrl(p.link), _metaStyle, rtlDoc: rtl),
          ],
        ),
      );
}

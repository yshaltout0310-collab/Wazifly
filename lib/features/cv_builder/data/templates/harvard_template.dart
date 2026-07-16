import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../pdf/cv_fonts.dart';
import 'pdf_template.dart';
import 'pdf_text.dart';

/// Classic academic ("Harvard") CV: a centred name and contact block, then
/// full-width ruled section headings, monochrome throughout. **Education leads**
/// — the convention this format is known for — followed by experience, projects
/// and skills. Dates sit on the far edge of each entry line.
///
/// **Bidirectional text:** every content string goes through [PdfText.txt] —
/// see [PdfText] for why a page-level direction is never set. The centred
/// header passes an explicit alignment override rather than inheriting the
/// language alignment.
class HarvardTemplate implements PdfTemplate {
  const HarvardTemplate();

  static const PdfColor _ink = PdfColor.fromInt(0xFF000000);
  static const PdfColor _muted = PdfColor.fromInt(0xFF333333);
  static const PdfColor _rule = PdfColor.fromInt(0xFF000000);

  static const _nameStyle = pw.TextStyle(
      fontSize: 19, fontWeight: pw.FontWeight.bold, color: _ink, letterSpacing: 1.2);
  static const _headlineStyle = pw.TextStyle(fontSize: 10, color: _muted);
  static const _metaStyle = pw.TextStyle(fontSize: 9, color: _muted);
  static const _sectionStyle = pw.TextStyle(
      fontSize: 10.5,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
      letterSpacing: 1.4);
  static const _titleStyle =
      pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _ink);
  // NOTE: the role/degree line is NOT italic. The document theme carries only a
  // regular + bold Arabic face, so `FontStyle.italic` falls back to a Latin
  // oblique font that cannot shape Arabic and bypasses the RTL text path
  // (Arabic came out disjointed and Latin reversed). Weight and colour carry
  // the hierarchy instead.
  static const _roleStyle = pw.TextStyle(fontSize: 10, color: _muted);
  static const _bodyStyle =
      pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 1.6);
  static const _bodyTight =
      pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 1.4);
  static const _bulletMark = pw.TextStyle(fontSize: 10, color: _ink);

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
        margin: const pw.EdgeInsets.symmetric(horizontal: 52, vertical: 44),
        build: (context) => [
          _header(data, rtl: rtl),
          if (data.summary.trim().isNotEmpty)
            _section(labels.summary, [
              PdfText.txt(data.summary, _bodyStyle, rtlDoc: rtl),
            ], rtl),
          // Education first — the defining trait of the academic format.
          if (data.education.any((e) => !e.isBlank))
            _section(
              labels.education,
              data.education
                  .where((e) => !e.isBlank)
                  .map((e) => _education(e, rtl))
                  .toList(),
              rtl,
            ),
          if (data.experiences.any((e) => !e.isBlank))
            _section(
              labels.experience,
              data.experiences
                  .where((e) => !e.isBlank)
                  .map((e) => _experience(e, labels, rtl))
                  .toList(),
              rtl,
            ),
          if (data.projects.any((p) => !p.isBlank))
            _section(
              labels.projects,
              data.projects
                  .where((p) => !p.isBlank)
                  .map((p) => _project(p, rtl))
                  .toList(),
              rtl,
            ),
          if (data.skills.isNotEmpty)
            _section(labels.skills, [
              PdfText.txt(data.skills.join(', '), _bodyTight, rtlDoc: rtl),
            ], rtl),
        ],
      ),
    );
    return doc;
  }

  // --- Centred header ---

  pw.Widget _header(CvData data, {required bool rtl}) {
    final contact = [
      if (data.email.isNotEmpty) data.email,
      if (data.phone.isNotEmpty) data.phone,
      if (data.location.isNotEmpty) data.location,
    ].join('  |  ');
    final links = [
      if (data.portfolioUrl.isNotEmpty) PdfText.cleanUrl(data.portfolioUrl),
      if (data.githubUrl.isNotEmpty) PdfText.cleanUrl(data.githubUrl),
      if (data.linkedinUrl.isNotEmpty) PdfText.cleanUrl(data.linkedinUrl),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Without a full-width child the header Column shrink-wraps to its
        // widest line and "centred" would only centre within that box, leaving
        // the block visibly off-centre on the page.
        pw.SizedBox(width: double.infinity, height: 0),
        PdfText.txt(data.fullName.isEmpty ? ' ' : data.fullName, _nameStyle,
            rtlDoc: rtl, align: pw.TextAlign.center),
        if (data.headline.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          PdfText.txt(data.headline, _headlineStyle,
              rtlDoc: rtl, align: pw.TextAlign.center),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          // Direction follows the text: an Arabic city makes this line RTL with
          // the email/phone kept readable; a pure-Latin line stays LTR.
          PdfText.txt(contact, _metaStyle,
              rtlDoc: rtl, align: pw.TextAlign.center),
        ],
        // One link per line — a joined line of long URLs overflows the width.
        if (links.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          for (final l in links)
            PdfText.txt(l, _metaStyle, rtlDoc: rtl, align: pw.TextAlign.center),
        ],
        pw.SizedBox(height: 6),
      ],
    );
  }

  // --- Section (ruled full-width heading) ---

  pw.Widget _section(String title, List<pw.Widget> children, bool rtl) =>
      pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 10),
          PdfText.txt(title.toUpperCase(), _sectionStyle, rtlDoc: rtl),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 2, bottom: 6),
            height: 0.8,
            width: double.infinity,
            color: _rule,
          ),
          ...children,
        ],
      );

  // --- Entries: institution/company bold, role italic, dates on the far edge ---

  pw.Widget _education(CvEducation e, bool rtl) {
    final years =
        [e.startYear, e.endYear].where((s) => s.isNotEmpty).join(' – ');
    final place = PdfText.titleLine([e.institution, e.location]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child: PdfText.txt(
                      place.isEmpty ? e.degree : place, _titleStyle,
                      rtlDoc: rtl)),
              if (years.isNotEmpty) PdfText.txt(years, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (place.isNotEmpty && e.degree.isNotEmpty)
            PdfText.txt(e.degree, _roleStyle, rtlDoc: rtl),
          if (e.details.isNotEmpty)
            PdfText.txt(e.details, _bodyTight, rtlDoc: rtl),
        ],
      ),
    );
  }

  pw.Widget _experience(CvExperience e, CvLabels labels, bool rtl) {
    final period =
        PdfText.period(e.startDate, e.endDate, e.current, labels.present);
    final place = PdfText.titleLine([e.company, e.location]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child: PdfText.txt(
                      place.isEmpty ? e.role : place, _titleStyle,
                      rtlDoc: rtl)),
              if (period.isNotEmpty)
                PdfText.txt(period, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (place.isNotEmpty && e.role.isNotEmpty)
            PdfText.txt(e.role, _roleStyle, rtlDoc: rtl),
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

  pw.Widget _project(CvProject p, bool rtl) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
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

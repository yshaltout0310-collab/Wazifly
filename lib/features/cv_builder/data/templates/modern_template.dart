import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../pdf/cv_fonts.dart';
import 'pdf_template.dart';
import 'pdf_text.dart';

/// Modern two-column CV: a full-width emerald header band, then a narrow side
/// column (contact, links, skills) beside the main flow (summary, experience,
/// education, projects).
///
/// The body uses [pw.Partitions] rather than a plain [pw.Row] because
/// Partitions is a *spanning* widget — a long CV keeps flowing onto the next
/// page instead of overflowing the page box (a `Row` cannot be split). Under
/// RTL the partition order is reversed so the side column sits on the right.
///
/// **Bidirectional text:** every content string goes through [PdfText.txt] —
/// see [PdfText] for why a page-level direction is never set.
class ModernTemplate implements PdfTemplate {
  const ModernTemplate();

  static const PdfColor _accent = PdfColor.fromInt(0xFF0E9F6E); // emerald brand
  static const PdfColor _accentDark = PdfColor.fromInt(0xFF0B7D57);
  static const PdfColor _tint = PdfColor.fromInt(0xFFEAF7F1);
  static const PdfColor _onAccent = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _onAccentSoft = PdfColor.fromInt(0xFFD8F0E5);
  static const PdfColor _muted = PdfColor.fromInt(0xFF555555);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1A1A);

  static const double _sideWidth = 148;
  static const double _gutter = 20;

  static const _nameStyle = pw.TextStyle(
      fontSize: 24, fontWeight: pw.FontWeight.bold, color: _onAccent);
  static const _headlineStyle = pw.TextStyle(fontSize: 11.5, color: _onAccentSoft);
  static const _sideHeadStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: _accentDark,
      letterSpacing: 0.8);
  static const _sideBody = pw.TextStyle(fontSize: 9, color: _muted, lineSpacing: 1.5);
  static const _chipStyle =
      pw.TextStyle(fontSize: 8.5, color: _accentDark, fontWeight: pw.FontWeight.bold);
  static const _sectionStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: _accentDark,
      letterSpacing: 0.4);
  static const _titleStyle =
      pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink);
  static const _metaStyle = pw.TextStyle(fontSize: 9, color: _muted);
  static const _italicMeta =
      pw.TextStyle(fontSize: 9, color: _muted, fontStyle: pw.FontStyle.italic);
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

    final side = _sideColumn(data, labels, rtl);
    final main = _mainColumn(data, labels, rtl);

    // Side / gutter / main — mirrored under RTL so the side column is on the
    // right. The gutter is its own partition (rather than padding) so both
    // content columns stay plain Columns, which is what lets them span pages.
    final partitions = <pw.Partition>[
      pw.Partition(width: _sideWidth, child: side),
      pw.Partition(width: _gutter, child: pw.Column(children: const [])),
      pw.Partition(child: main),
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // the header band bleeds to the page edges
        build: (context) => [
          _headerBand(data, rtl: rtl),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(36, 18, 36, 32),
            child: pw.Partitions(
              children: rtl ? partitions.reversed.toList() : partitions,
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  // --- Header band (name + headline reversed out on emerald) ---

  pw.Widget _headerBand(CvData data, {required bool rtl}) => pw.Container(
        width: double.infinity,
        color: _accent,
        padding: const pw.EdgeInsets.fromLTRB(36, 30, 36, 26),
        child: pw.Column(
          crossAxisAlignment:
              rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
          children: [
            PdfText.txt(
                data.fullName.isEmpty ? ' ' : data.fullName, _nameStyle,
                rtlDoc: rtl),
            if (data.headline.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              PdfText.txt(data.headline, _headlineStyle, rtlDoc: rtl),
            ],
          ],
        ),
      );

  // --- Side column (contact, links, skills) ---

  pw.Column _sideColumn(CvData data, CvLabels labels, bool rtl) {
    final align =
        rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final contact = [
      if (data.email.isNotEmpty) data.email,
      if (data.phone.isNotEmpty) data.phone,
      if (data.location.isNotEmpty) data.location,
    ];
    final links = [
      if (data.portfolioUrl.isNotEmpty) PdfText.cleanUrl(data.portfolioUrl),
      if (data.githubUrl.isNotEmpty) PdfText.cleanUrl(data.githubUrl),
      if (data.linkedinUrl.isNotEmpty) PdfText.cleanUrl(data.linkedinUrl),
    ];

    return pw.Column(
      crossAxisAlignment: align,
      children: [
        if (contact.isNotEmpty) ...[
          _sideHead(labels.contact, rtl),
          // Direction follows the text: an Arabic city makes a line RTL with the
          // email/phone kept readable; a pure-Latin line stays LTR.
          for (final c in contact)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: PdfText.txt(c, _sideBody, rtlDoc: rtl),
            ),
          pw.SizedBox(height: 12),
        ],
        if (links.isNotEmpty) ...[
          _sideHead(labels.links, rtl),
          for (final l in links)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: PdfText.txt(l, _sideBody, rtlDoc: rtl),
            ),
          pw.SizedBox(height: 12),
        ],
        if (data.skills.isNotEmpty) ...[
          _sideHead(labels.skills, rtl),
          pw.Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: rtl ? pw.WrapAlignment.end : pw.WrapAlignment.start,
            children: [for (final s in data.skills) _chip(s, rtl)],
          ),
        ],
      ],
    );
  }

  pw.Widget _sideHead(String title, bool rtl) => pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          PdfText.txt(title.toUpperCase(), _sideHeadStyle, rtlDoc: rtl),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 3, bottom: 5),
            height: 2,
            width: 22,
            color: _accent,
          ),
        ],
      );

  pw.Widget _chip(String label, bool rtl) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
        decoration: const pw.BoxDecoration(
          color: _tint,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: PdfText.txt(label, _chipStyle, rtlDoc: rtl),
      );

  // --- Main column (summary, experience, education, projects) ---

  pw.Column _mainColumn(CvData data, CvLabels labels, bool rtl) {
    final align =
        rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    return pw.Column(
      crossAxisAlignment: align,
      children: [
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
    );
  }

  pw.Widget _section(String title, List<pw.Widget> children, bool rtl) =>
      pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          PdfText.txt(title, _sectionStyle, rtlDoc: rtl),
          pw.SizedBox(height: 6),
          ...children,
          pw.SizedBox(height: 12),
        ],
      );

  pw.Widget _experience(CvExperience e, CvLabels labels, bool rtl) {
    final period =
        PdfText.period(e.startDate, e.endDate, e.current, labels.present);
    final titleLine = PdfText.titleLine([e.role, e.company]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment:
            rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: PdfText.txt(titleLine, _titleStyle, rtlDoc: rtl)),
              if (period.isNotEmpty)
                PdfText.txt(period, _metaStyle, rtlDoc: rtl),
            ],
          ),
          if (e.location.isNotEmpty)
            PdfText.txt(e.location, _italicMeta, rtlDoc: rtl),
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

  pw.Widget _education(CvEducation e, bool rtl) {
    final years =
        [e.startYear, e.endYear].where((s) => s.isNotEmpty).join(' – ');
    final titleLine = PdfText.titleLine([e.degree, e.institution]);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
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
          if (e.details.isNotEmpty)
            PdfText.txt(e.details, _bodyTight, rtlDoc: rtl),
        ],
      ),
    );
  }

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

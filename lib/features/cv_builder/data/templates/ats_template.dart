import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/cv_data.dart';
import '../../domain/cv_pdf_generator.dart';
import '../pdf/cv_fonts.dart';
import 'pdf_template.dart';

/// ATS-friendly single-column CV: standard fonts, clear text section headers,
/// no tables/columns/graphics — maximally parseable by applicant-tracking
/// systems while staying clean and professional.
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
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) => [
          _header(data),
          if (data.summary.trim().isNotEmpty)
            _section(labels.summary, [_paragraph(data.summary)]),
          if (data.experiences.any((e) => !e.isBlank))
            _section(
              labels.experience,
              data.experiences
                  .where((e) => !e.isBlank)
                  .map((e) => _experience(e, labels))
                  .toList(),
            ),
          if (data.education.any((e) => !e.isBlank))
            _section(
              labels.education,
              data.education.where((e) => !e.isBlank).map(_education).toList(),
            ),
          if (data.skills.isNotEmpty)
            _section(labels.skills, [_paragraph(data.skills.join('  ·  '))]),
          if (data.projects.any((p) => !p.isBlank))
            _section(
              labels.projects,
              data.projects.where((p) => !p.isBlank).map(_project).toList(),
            ),
        ],
      ),
    );
    return doc;
  }

  // --- Header (name, headline, contact, links) ---

  pw.Widget _header(CvData data) {
    final contact = [
      if (data.email.isNotEmpty) data.email,
      if (data.phone.isNotEmpty) data.phone,
      if (data.location.isNotEmpty) data.location,
    ].join('  ·  ');
    final links = [
      if (data.portfolioUrl.isNotEmpty) data.portfolioUrl,
      if (data.githubUrl.isNotEmpty) data.githubUrl,
      if (data.linkedinUrl.isNotEmpty) data.linkedinUrl,
    ].join('  ·  ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(data.fullName.isEmpty ? ' ' : data.fullName, style: _nameStyle),
        if (data.headline.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(data.headline, style: _headlineStyle),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(contact, style: _metaStyle),
        ],
        if (links.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(links, style: _metaStyle),
        ],
        pw.SizedBox(height: 10),
      ],
    );
  }

  // --- Generic section wrapper (heading + rule + content) ---

  pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 6),
        pw.Text(title.toUpperCase(), style: _sectionStyle),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 3, bottom: 6),
          height: 1,
          color: _rule,
        ),
        ...children,
      ],
    );
  }

  pw.Widget _paragraph(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(text, style: _bodyStyle),
      );

  // --- Experience entry ---

  pw.Widget _experience(CvExperience e, CvLabels labels) {
    final period = _period(e.startDate, e.endDate, e.current, labels.present);
    final titleLine = [e.role, e.company].where((s) => s.isNotEmpty).join(' — ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(titleLine, style: _titleStyle)),
              if (period.isNotEmpty) pw.Text(period, style: _metaStyle),
            ],
          ),
          if (e.location.isNotEmpty) pw.Text(e.location, style: _italicMeta),
          pw.SizedBox(height: 2),
          for (final b in e.bullets.where((b) => b.trim().isNotEmpty))
            _bullet(b),
        ],
      ),
    );
  }

  pw.Widget _bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5, top: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('•  ', style: _bulletMark),
            pw.Expanded(child: pw.Text(text, style: _bodyTight)),
          ],
        ),
      );

  // --- Education entry ---

  pw.Widget _education(CvEducation e) {
    final years =
        [e.startYear, e.endYear].where((s) => s.isNotEmpty).join(' – ');
    final titleLine =
        [e.degree, e.institution].where((s) => s.isNotEmpty).join(' — ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text(titleLine, style: _titleStyle)),
              if (years.isNotEmpty) pw.Text(years, style: _metaStyle),
            ],
          ),
          if (e.details.isNotEmpty) pw.Text(e.details, style: _bodyTight),
        ],
      ),
    );
  }

  // --- Project entry ---

  pw.Widget _project(CvProject p) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(p.name, style: _titleStyle),
            if (p.description.isNotEmpty)
              pw.Text(p.description, style: _bodyTight),
            if (p.link.isNotEmpty) pw.Text(p.link, style: _metaStyle),
          ],
        ),
      );

  String _period(String start, String end, bool current, String present) {
    final e = current ? present : end;
    return [start, e].where((s) => s.isNotEmpty).join(' – ');
  }
}

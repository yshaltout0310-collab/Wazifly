/// The CV templates the app offers. Every id ships an implemented layout —
/// the PDF generator maps each one to a `PdfTemplate`.
enum CvTemplateId { ats, modern, minimal, harvard }

/// Display metadata for a template, used to build the picker. Kept vendor-neutral
/// (l10n keys only) so the presentation layer never touches the PDF library.
class CvTemplateMeta {
  const CvTemplateMeta({
    required this.id,
    required this.nameKey,
    required this.descKey,
  });

  final CvTemplateId id;

  /// l10n keys resolved by the picker.
  final String nameKey;
  final String descKey;
}

/// The registry that drives the template picker. **Adding a template =
/// implement a `PdfTemplate`, register it in the generator, add an entry here.**
const List<CvTemplateMeta> cvTemplateCatalog = [
  CvTemplateMeta(
    id: CvTemplateId.ats,
    nameKey: 'cvTemplateAts',
    descKey: 'cvTemplateAtsDesc',
  ),
  CvTemplateMeta(
    id: CvTemplateId.modern,
    nameKey: 'cvTemplateModern',
    descKey: 'cvTemplateModernDesc',
  ),
  CvTemplateMeta(
    id: CvTemplateId.minimal,
    nameKey: 'cvTemplateMinimal',
    descKey: 'cvTemplateMinimalDesc',
  ),
  CvTemplateMeta(
    id: CvTemplateId.harvard,
    nameKey: 'cvTemplateHarvard',
    descKey: 'cvTemplateHarvardDesc',
  ),
];

/// The default template.
const CvTemplateId kDefaultCvTemplate = CvTemplateId.ats;

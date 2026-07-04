/// The CV templates the app knows about. Only [ats] is implemented this
/// milestone; the rest are registered as "coming soon" so adding them later is
/// purely additive — no controller/screen/generator changes.
enum CvTemplateId { ats, modern, minimal, harvard }

/// Display metadata for a template, used to build the picker. Kept vendor-neutral
/// (l10n keys + an availability flag) so the presentation layer never touches the
/// PDF library.
class CvTemplateMeta {
  const CvTemplateMeta({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.available,
  });

  final CvTemplateId id;

  /// l10n keys resolved by the picker.
  final String nameKey;
  final String descKey;

  /// False → shown with a "Coming soon" badge and not selectable for export.
  final bool available;
}

/// The registry that drives the template picker. **Adding a template later =
/// flip `available` + register the builder in the PDF generator — nothing else.**
const List<CvTemplateMeta> cvTemplateCatalog = [
  CvTemplateMeta(
    id: CvTemplateId.ats,
    nameKey: 'cvTemplateAts',
    descKey: 'cvTemplateAtsDesc',
    available: true,
  ),
  CvTemplateMeta(
    id: CvTemplateId.modern,
    nameKey: 'cvTemplateModern',
    descKey: 'cvTemplateModernDesc',
    available: false,
  ),
  CvTemplateMeta(
    id: CvTemplateId.minimal,
    nameKey: 'cvTemplateMinimal',
    descKey: 'cvTemplateMinimalDesc',
    available: false,
  ),
  CvTemplateMeta(
    id: CvTemplateId.harvard,
    nameKey: 'cvTemplateHarvard',
    descKey: 'cvTemplateHarvardDesc',
    available: false,
  ),
];

/// The default (and only implemented) template.
const CvTemplateId kDefaultCvTemplate = CvTemplateId.ats;

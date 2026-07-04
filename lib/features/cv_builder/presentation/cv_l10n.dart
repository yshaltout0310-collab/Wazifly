import '../../../core/localization/generated/app_localizations.dart';
import '../application/cv_builder_controller.dart';
import '../domain/cv_pdf_generator.dart';
import '../domain/cv_template.dart';

/// Builds the localized section labels handed to the PDF templates.
CvLabels cvLabels(AppLocalizations l10n) => CvLabels(
      summary: l10n.cvSummarySection,
      experience: l10n.cvExperienceSection,
      education: l10n.cvEducationSection,
      skills: l10n.cvSkillsSection,
      projects: l10n.cvProjectsSection,
      links: l10n.cvLinksSection,
      present: l10n.cvPresent,
    );

String cvTemplateName(AppLocalizations l10n, CvTemplateId id) => switch (id) {
      CvTemplateId.ats => l10n.cvTemplateAts,
      CvTemplateId.modern => l10n.cvTemplateModern,
      CvTemplateId.minimal => l10n.cvTemplateMinimal,
      CvTemplateId.harvard => l10n.cvTemplateHarvard,
    };

String cvTemplateDesc(AppLocalizations l10n, CvTemplateId id) => switch (id) {
      CvTemplateId.ats => l10n.cvTemplateAtsDesc,
      CvTemplateId.modern => l10n.cvTemplateModernDesc,
      CvTemplateId.minimal => l10n.cvTemplateMinimalDesc,
      CvTemplateId.harvard => l10n.cvTemplateHarvardDesc,
    };

String cvFailureMessage(AppLocalizations l10n, CvBuilderFailure failure) =>
    switch (failure) {
      CvBuilderFailure.network => l10n.cvErrNetwork,
      CvBuilderFailure.quota => l10n.cvErrQuota,
      CvBuilderFailure.emptyEnhancement => l10n.cvErrEmpty,
      CvBuilderFailure.notConfigured ||
      CvBuilderFailure.invalidResponse ||
      CvBuilderFailure.unknown =>
        l10n.cvEnhanceFailed,
    };

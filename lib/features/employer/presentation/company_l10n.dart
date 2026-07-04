import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/company.dart';
import '../domain/company_failure.dart';
import '../domain/company_size.dart';
import '../domain/industry.dart';

/// Localized labels for company enums, kept in one place so the dashboard,
/// profile, and edit screens read the same strings.
extension IndustryL10n on Industry {
  String label(AppLocalizations l10n) => switch (this) {
        Industry.technology => l10n.industryTechnology,
        Industry.finance => l10n.industryFinance,
        Industry.healthcare => l10n.industryHealthcare,
        Industry.education => l10n.industryEducation,
        Industry.retail => l10n.industryRetail,
        Industry.manufacturing => l10n.industryManufacturing,
        Industry.construction => l10n.industryConstruction,
        Industry.hospitality => l10n.industryHospitality,
        Industry.media => l10n.industryMedia,
        Industry.energy => l10n.industryEnergy,
        Industry.transportation => l10n.industryTransportation,
        Industry.government => l10n.industryGovernment,
        Industry.nonprofit => l10n.industryNonprofit,
        Industry.other => l10n.industryOther,
      };
}

extension CompanySizeL10n on CompanySize {
  String label(AppLocalizations l10n) => switch (this) {
        CompanySize.size1_10 => l10n.companySize1to10,
        CompanySize.size11_50 => l10n.companySize11to50,
        CompanySize.size51_200 => l10n.companySize51to200,
        CompanySize.size201_500 => l10n.companySize201to500,
        CompanySize.size501_1000 => l10n.companySize501to1000,
        CompanySize.size1000plus => l10n.companySize1000plus,
      };
}

extension CompanyFieldL10n on CompanyField {
  String label(AppLocalizations l10n) => switch (this) {
        CompanyField.name => l10n.companyNameLabel,
        CompanyField.logo => l10n.companyLogoLabel,
        CompanyField.industry => l10n.companyIndustryLabel,
        CompanyField.size => l10n.companySizeLabel,
        CompanyField.website => l10n.companyWebsiteLabel,
        CompanyField.headquarters => l10n.companyHqLabel,
        CompanyField.description => l10n.companyDescriptionLabel,
        CompanyField.contactEmail => l10n.companyContactEmailLabel,
      };
}

String companyFailureMessage(AppLocalizations l10n, CompanyFailure f) =>
    switch (f) {
      CompanyFailure.notSignedIn => l10n.companyErrNotSignedIn,
      CompanyFailure.logoUploadFailed => l10n.companyLogoUploadFailed,
      CompanyFailure.saveFailed ||
      CompanyFailure.unknown =>
        l10n.companyErrGeneric,
    };

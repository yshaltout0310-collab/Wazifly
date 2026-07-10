import '../../core/localization/generated/app_localizations.dart';
import 'internship_details.dart';

/// Maps the internship enums to their localized labels. Lives in `shared` (next
/// to [InternshipDetails]) so both the shared `JobDetailView` and the seeker/
/// employer features render the same labels without a feature-to-feature or a
/// shared→feature dependency. Depends only on the generated core l10n.
extension InternshipFundingL10n on InternshipFunding {
  String label(AppLocalizations l) => switch (this) {
        InternshipFunding.paid => l.internshipFundingPaid,
        InternshipFunding.unpaid => l.internshipFundingUnpaid,
      };
}

extension InternshipCategoryL10n on InternshipCategory {
  String label(AppLocalizations l) => switch (this) {
        InternshipCategory.software => l.internshipCategorySoftware,
        InternshipCategory.design => l.internshipCategoryDesign,
        InternshipCategory.data => l.internshipCategoryData,
        InternshipCategory.marketing => l.internshipCategoryMarketing,
        InternshipCategory.business => l.internshipCategoryBusiness,
        InternshipCategory.engineering => l.internshipCategoryEngineering,
        InternshipCategory.other => l.internshipCategoryOther,
      };
}

extension InternshipLevelL10n on InternshipLevel {
  String label(AppLocalizations l) => switch (this) {
        InternshipLevel.highSchool => l.internshipLevelHighSchool,
        InternshipLevel.undergraduate => l.internshipLevelUndergraduate,
        InternshipLevel.graduate => l.internshipLevelGraduate,
        InternshipLevel.bootcamp => l.internshipLevelBootcamp,
        InternshipLevel.careerSwitcher => l.internshipLevelCareerSwitcher,
      };
}

extension InternshipDurationL10n on InternshipDuration {
  String label(AppLocalizations l) => switch (this) {
        InternshipDuration.upTo1Month => l.internshipDurationUpTo1Month,
        InternshipDuration.oneToThreeMonths => l.internshipDurationOneToThree,
        InternshipDuration.threeToSixMonths => l.internshipDurationThreeToSix,
        InternshipDuration.sixToTwelveMonths => l.internshipDurationSixToTwelve,
      };
}

extension WorkModeL10n on WorkMode {
  String label(AppLocalizations l) => switch (this) {
        WorkMode.onsite => l.internshipWorkModeOnsite,
        WorkMode.remote => l.internshipWorkModeRemote,
        WorkMode.hybrid => l.internshipWorkModeHybrid,
      };
}

extension InternshipEligibilityL10n on InternshipEligibility {
  String label(AppLocalizations l) => switch (this) {
        InternshipEligibility.universityStudents =>
          l.internshipEligibilityUniversity,
        InternshipEligibility.freshGraduates => l.internshipEligibilityFreshGrad,
        InternshipEligibility.openToEveryone => l.internshipEligibilityEveryone,
      };
}

extension InternshipScheduleL10n on InternshipSchedule {
  String label(AppLocalizations l) => switch (this) {
        InternshipSchedule.fullTime => l.internshipScheduleFullTime,
        InternshipSchedule.partTime => l.internshipSchedulePartTime,
        InternshipSchedule.flexible => l.internshipScheduleFlexible,
      };
}

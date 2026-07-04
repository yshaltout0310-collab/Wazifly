import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/user_profile.dart';
import '../../user_type/domain/user_type.dart';
import '../domain/experience_level.dart';

/// Localized labels for profile enums, kept in one place so the profile, edit,
/// and settings screens read the same strings.
extension ExperienceLevelL10n on ExperienceLevel {
  String label(AppLocalizations l10n) => switch (this) {
        ExperienceLevel.entry => l10n.experienceEntry,
        ExperienceLevel.junior => l10n.experienceJunior,
        ExperienceLevel.mid => l10n.experienceMid,
        ExperienceLevel.senior => l10n.experienceSenior,
        ExperienceLevel.lead => l10n.experienceLead,
      };
}

extension ProfileFieldL10n on ProfileField {
  String label(AppLocalizations l10n) => switch (this) {
        ProfileField.displayName => l10n.profileNameLabel,
        ProfileField.photo => l10n.profileChangePhoto,
        ProfileField.headline => l10n.profileHeadlineLabel,
        ProfileField.location => l10n.profileLocationLabel,
        ProfileField.bio => l10n.profileBioLabel,
        ProfileField.role => l10n.profileRoleLabel,
        ProfileField.skills => l10n.profileSkillsLabel,
        ProfileField.experienceLevel => l10n.profileExperienceLabel,
        ProfileField.preferredJobTitles => l10n.profilePreferredTitlesLabel,
        ProfileField.links => l10n.profileLinksLabel,
      };
}

String userTypeLabel(AppLocalizations l10n, UserType type) => switch (type) {
      UserType.jobSeeker => l10n.jobSeeker,
      UserType.employer => l10n.employer,
    };

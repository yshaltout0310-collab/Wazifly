import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/learning_profile.dart';

/// Maps the learning-interest categories to their localized section titles.
extension LearningCategoryL10n on LearningCategory {
  String label(AppLocalizations l) => switch (this) {
        LearningCategory.careerPaths => l.learningCatCareerPaths,
        LearningCategory.skillsToLearn => l.learningCatSkills,
        LearningCategory.technologies => l.learningCatTechnologies,
        LearningCategory.industries => l.learningCatIndustries,
        LearningCategory.goals => l.learningCatGoals,
      };
}

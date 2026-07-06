import 'recruiter_insights.dart';
import 'recruiter_insights_context.dart';

/// Generates AI "Recruiter Insights" from an employer's hiring analytics.
///
/// Provider-agnostic (backed by the bound `AiService`); the implementation stays
/// pure (takes a primitive [RecruiterInsightsContext], returns a parsed model)
/// so the controller owns clock + signature stamping. Mirrors
/// `RecommendationsRepository`.
abstract interface class RecruiterInsightsRepository {
  Future<RecruiterInsights> generate({
    required RecruiterInsightsContext context,
    required String languageCode,
  });
}

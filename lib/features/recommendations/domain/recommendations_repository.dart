import 'recommendation_context.dart';
import 'recommendation_models.dart';

/// Generates a personalized "For You" plan from the reused user signals.
///
/// Provider-agnostic: implementations depend only on the `AiService` interface,
/// so the AI backend (Firebase AI Logic / Gemini today) can be swapped by
/// rebinding a single Riverpod provider. A single holistic call produces all six
/// sections so they cross-reference (skills align with the recommended jobs and
/// roadmap). Throws [RecommendationsException] / `AiException` on failure.
abstract interface class RecommendationsRepository {
  Future<Recommendations> generate({
    required RecommendationContext context,
    required String languageCode,
  });
}

import '../../../shared/models/job.dart';
import '../../resume_analyzer/domain/resume_analysis.dart';
import 'job_match.dart';

/// Ranks available jobs against an analyzed resume.
///
/// Feature code depends on this interface only; the implementation fetches jobs
/// (via a `JobsRepository`) and ranks them with the `AiService`.
abstract interface class JobMatchingRepository {
  /// Returns jobs ranked best-first for the candidate described by [analysis].
  ///
  /// [languageCode] (`en` / `ar`) asks the model to write the per-job
  /// explanation in the user's language.
  ///
  /// Throws `JobMatchingException(noJobs)` if there are no jobs to rank, and
  /// `AiException` if the AI call fails or returns an unusable result.
  /// [country], when set, is the seeker's location context (Qatar by default) —
  /// the model gently prefers roles there or remote, all else equal.
  Future<List<JobMatch>> matchJobs({
    required ResumeAnalysis analysis,
    required String languageCode,
    String? country,
  });

  /// Scores a single [job] against [analysis] — used by the Jobs platform's
  /// detail screen for an on-demand "why it matches" without ranking the whole
  /// list. Throws `AiException` on failure.
  Future<JobMatch> matchJob({
    required ResumeAnalysis analysis,
    required Job job,
    required String languageCode,
    String? country,
  });
}

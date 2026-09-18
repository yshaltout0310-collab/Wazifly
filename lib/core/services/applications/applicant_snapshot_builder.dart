import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/applicant_snapshot.dart';
import '../resume_store/resume_analysis_store.dart';
import '../user_profile/user_profile_repository.dart';

/// Assembles the [ApplicantSnapshot] stored on an application at apply time.
///
/// **Why a snapshot rather than a cross-user read.** `firestore.rules` keeps
/// `users/{uid}` readable only by that user, so an employer can never read an
/// applicant's profile document. Everything the employer's applicant list and
/// detail screens render is therefore captured here, once, by the seeker — who
/// *is* allowed to read their own data — and written onto the application.
///
/// Only data the seeker already holds is copied, and only the fields the
/// employer UI actually shows. Anything unavailable is simply omitted; the
/// snapshot's defensive `fromJson` and the employer widgets both degrade.
ApplicantSnapshot buildApplicantSnapshot(Ref ref, {String? fallbackName}) {
  final profile = ref.read(userProfileProvider).valueOrNull;
  final analysis = ref.read(lastResumeAnalysisProvider);

  final name = (profile?.displayName ?? '').trim().isNotEmpty
      ? profile!.displayName!.trim()
      : (fallbackName ?? '').trim();

  return ApplicantSnapshot(
    // --- profile ---
    name: name,
    headline: profile?.headline,
    location: profile?.location,
    photoUrl: profile?.photoUrl,
    skills: profile?.skills ?? const [],
    // Denormalized to its canonical string: `shared/` must not import a feature
    // enum (that would invert the dependency direction).
    experienceLevel: profile?.experienceLevel?.name,
    portfolioUrl: profile?.portfolioUrl,
    githubUrl: profile?.githubUrl,
    linkedinUrl: profile?.linkedinUrl,
    // --- resume (present only once the seeker has run the analyzer) ---
    atsScore: analysis?.atsScore,
    resumeSummary: analysis?.summary,
    resumeStrengths: analysis?.strengths ?? const [],
  );
}

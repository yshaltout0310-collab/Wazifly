// The applicant snapshot is the ONLY way an employer ever sees anything about a
// candidate: firestore.rules keeps users/{uid} private to that user, so whatever
// is not captured here at apply time is invisible to the employer forever.
// These tests pin what gets captured.
import 'package:careerbridge/core/services/applications/applicant_snapshot_builder.dart';
import 'package:careerbridge/core/services/resume_store/resume_analysis_store.dart';
import 'package:careerbridge/core/services/user_profile/user_profile_repository.dart';
import 'package:careerbridge/features/profile/domain/experience_level.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:careerbridge/shared/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A store pre-seeded with an analysis, so the controller hydrates with it.
class _SeededResumeStore implements ResumeAnalysisStore {
  _SeededResumeStore(this._seed);

  ResumeAnalysis? _seed;

  @override
  ResumeAnalysis? read() => _seed;

  @override
  Future<void> write(ResumeAnalysis analysis) async => _seed = analysis;

  @override
  Future<void> clear() async => _seed = null;
}

const _analysis = ResumeAnalysis(
  atsScore: 82,
  summary: 'Strong Flutter background.',
  strengths: ['Dart', 'Testing'],
  weaknesses: [],
  missingSkills: [],
  grammarIssues: [],
  improvementSuggestions: [],
);

ProviderContainer _container({UserProfile? profile, ResumeAnalysis? analysis}) {
  return ProviderContainer(overrides: [
    userProfileProvider.overrideWith((ref) => Stream.value(profile)),
    resumeAnalysisStoreProvider
        .overrideWithValue(_SeededResumeStore(analysis)),
  ]);
}

void main() {
  test('captures profile + resume analysis through a real container', () async {
    final container = _container(
      profile: const UserProfile(
        uid: 'seeker1',
        displayName: 'Sara Zewail',
        headline: 'Flutter Engineer',
        location: 'Doha',
        skills: ['Dart', 'Firebase'],
        experienceLevel: ExperienceLevel.mid,
      ),
      analysis: _analysis,
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    // Exercise the builder exactly the way the app does: from inside a provider.
    final probe = Provider((ref) => buildApplicantSnapshot(ref));
    final snap = container.read(probe);

    expect(snap.name, 'Sara Zewail');
    expect(snap.headline, 'Flutter Engineer');
    expect(snap.location, 'Doha');
    expect(snap.skills, ['Dart', 'Firebase']);
    expect(snap.experienceLevel, 'mid');
    expect(snap.atsScore, 82);
    expect(snap.resumeSummary, 'Strong Flutter background.');
    expect(snap.resumeStrengths, ['Dart', 'Testing']);
    expect(snap.hasResumeAnalysis, isTrue);
  });

  test('degrades to the auth display name when there is no profile', () async {
    final container = _container();
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    final probe = Provider(
        (ref) => buildApplicantSnapshot(ref, fallbackName: 'Youssef'));
    final snap = container.read(probe);

    expect(snap.name, 'Youssef');
    expect(snap.skills, isEmpty);
    expect(snap.hasResumeAnalysis, isFalse,
        reason: 'no analyzer run yet — the employer simply sees no ATS data');
  });

  test('omits resume data when the seeker has not run the analyzer', () async {
    final container = _container(
      profile: const UserProfile(uid: 'seeker1', displayName: 'Sara'),
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);

    final probe = Provider((ref) => buildApplicantSnapshot(ref));
    final snap = container.read(probe);

    expect(snap.name, 'Sara');
    expect(snap.atsScore, isNull);
    expect(snap.resumeSummary, isNull);
  });
}

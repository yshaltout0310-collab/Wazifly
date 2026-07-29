import 'package:careerbridge/core/providers/app_providers.dart';
import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_providers.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/core/services/applications/employer_applicants_repository.dart';
import 'package:careerbridge/core/services/storage/local_storage_service.dart';
import 'package:careerbridge/features/employer/application/candidate_match_controller.dart';
import 'package:careerbridge/features/employer/data/candidate_match_repository_impl.dart';
import 'package:careerbridge/features/employer/domain/candidate_match.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAi implements AiService {
  _FakeAi({this.json, this.error});
  final Map<String, dynamic>? json;
  final Object? error;
  String? lastPrompt;

  @override
  Future<Map<String, dynamic>> generateJson(String prompt,
      {String? systemInstruction}) async {
    lastPrompt = prompt;
    if (error != null) throw error!;
    return json ?? const {};
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async => '';
  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) =>
      const Stream.empty();
  @override
  Stream<String> streamChat(List<AiMessage> history, {String? systemInstruction}) =>
      const Stream.empty();
}

const _shortlistJson = {
  'summary': 'Two strong candidates for the role.',
  'candidates': [
    {
      'name': 'Alice',
      'headline': 'Senior Flutter Engineer',
      'matchScore': 91,
      'matchingSkills': ['Dart', 'Flutter'],
      'experienceSummary': '6 years building mobile apps.',
      'recommendation': 'Strong fit — interview soon.'
    },
  ],
};

Application _app(String uid, ApplicantSnapshot? snap) => Application(
      id: 'app-$uid',
      jobId: 'j1',
      jobTitle: 'Engineer',
      company: 'Acme',
      location: 'Doha',
      status: ApplicationStatus.pending,
      appliedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      history: const [],
      applicantUid: uid,
      applicant: snap,
    );

Future<ProviderContainer> _container({
  required List<Application> apps,
  Map<String, dynamic>? json,
  Object? error,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorageService.create();
  final c = ProviderContainer(overrides: [
    localStorageProvider.overrideWithValue(storage),
    aiServiceProvider.overrideWithValue(_FakeAi(json: json, error: error)),
    employerApplicantsProvider.overrideWith((ref) => Stream.value(apps)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('CandidateMatchRepositoryImpl', () {
    test('parses a ranked shortlist and stamps the role', () async {
      final ai = _FakeAi(json: _shortlistJson);
      final shortlist = await CandidateMatchRepositoryImpl(ai: ai).rank(
        role: 'Flutter Engineer',
        candidates: const [CandidateProfile(id: 'u1', name: 'Alice')],
        languageCode: 'en',
      );
      expect(shortlist.role, 'Flutter Engineer');
      expect(shortlist.candidates.single.name, 'Alice');
      expect(shortlist.candidates.single.matchScore, 91);
      expect(shortlist.candidates.single.matchingSkills, contains('Flutter'));
      expect(ai.lastPrompt, contains('Alice')); // grounded in the real pool
    });

    test('throws when the model returns no candidates', () async {
      expect(
        () => CandidateMatchRepositoryImpl(ai: _FakeAi(json: const {}))
            .rank(role: 'X', candidates: const [CandidateProfile(id: 'u1', name: 'A')], languageCode: 'en'),
        throwsA(isA<CandidateMatchException>()),
      );
    });
  });

  group('employerCandidatePoolProvider', () {
    test('flattens applicants, drops snapshot-less, dedupes keeping the richer',
        () async {
      final c = await _container(apps: [
        _app('u1', const ApplicantSnapshot(name: 'Alice', skills: ['Dart', 'Flutter'])),
        _app('u1', const ApplicantSnapshot(name: 'Alice', skills: ['Dart'])), // dup, fewer skills
        _app('u2', const ApplicantSnapshot(name: 'Bob', skills: ['Go'])),
        _app('u3', null), // no snapshot → skipped
      ]);
      await c.read(employerApplicantsProvider.future);

      final pool = c.read(employerCandidatePoolProvider);
      expect(pool.length, 2);
      expect(pool.firstWhere((p) => p.id == 'u1').skills.length, 2);
    });
  });

  group('CandidateMatchController', () {
    test('generate → ready with the ranked shortlist', () async {
      final c = await _container(
        apps: [_app('u1', const ApplicantSnapshot(name: 'Alice', skills: ['Flutter']))],
        json: _shortlistJson,
      );
      await c.read(employerApplicantsProvider.future);
      await c.read(candidateMatchControllerProvider.notifier).generate('Engineer');
      final state = c.read(candidateMatchControllerProvider);
      expect(state.phase, CandidateMatchPhase.ready);
      expect(state.shortlist?.candidates.single.name, 'Alice');
    });

    test('maps an AI quota error to a quota failure', () async {
      final c = await _container(
        apps: [_app('u1', const ApplicantSnapshot(name: 'Alice'))],
        error: const AiException(AiErrorCode.quota),
      );
      await c.read(employerApplicantsProvider.future);
      await c.read(candidateMatchControllerProvider.notifier).generate('Engineer');
      final state = c.read(candidateMatchControllerProvider);
      expect(state.phase, CandidateMatchPhase.error);
      expect(state.failure, CandidateMatchFailure.quota);
    });
  });
}

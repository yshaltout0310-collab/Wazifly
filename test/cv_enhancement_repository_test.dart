import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/features/cv_builder/data/cv_enhancement_repository_impl.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_builder_exception.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake AiService that returns a scripted JSON (or throws) and records the
/// prompt for assertions.
class FakeAiService implements AiService {
  FakeAiService({this.json, this.error});
  final Map<String, dynamic>? json;
  final Object? error;
  String? lastPrompt;

  @override
  Future<Map<String, dynamic>> generateJson(String prompt,
      {String? systemInstruction}) async {
    lastPrompt = prompt;
    if (error != null) throw error!;
    return json ?? {};
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) =>
      throw UnimplementedError();
  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) =>
      throw UnimplementedError();
  @override
  Stream<String> streamChat(List<AiMessage> history,
          {String? systemInstruction}) =>
      throw UnimplementedError();
}

const _cv = CvData(
  fullName: 'Sarah',
  headline: 'Flutter Engineer',
  summary: 'old summary',
  skills: ['Flutter'],
  experiences: [
    CvExperience(role: 'Engineer', company: 'Acme', bullets: ['did stuff']),
    CvExperience(role: 'Intern', company: 'Beta', bullets: ['helped out']),
  ],
  targetRole: 'Senior Flutter Engineer',
);

void main() {
  test('merges summary, per-experience bullets, and skills', () async {
    final ai = FakeAiService(json: {
      'summary': 'Polished summary',
      'skills': ['Flutter', 'Dart', 'Firebase'],
      'experiences': [
        {'bullets': ['Led migration to Riverpod', 'Cut cold-start 35%']},
        {'bullets': ['Built onboarding flow']},
      ],
    });
    final repo = CvEnhancementRepositoryImpl(ai: ai);
    final out = await repo.enhance(_cv, languageCode: 'en');

    expect(out.summary, 'Polished summary');
    expect(out.skills, ['Flutter', 'Dart', 'Firebase']);
    expect(out.experiences[0].bullets, ['Led migration to Riverpod', 'Cut cold-start 35%']);
    expect(out.experiences[1].bullets, ['Built onboarding flow']);
    // Factual fields are preserved.
    expect(out.experiences[0].role, 'Engineer');
    expect(out.experiences[0].company, 'Acme');
  });

  test('keeps original bullets when the model omits an experience', () async {
    final ai = FakeAiService(json: {
      'summary': 'S',
      'experiences': [
        {'bullets': ['Rewrote first']},
        // second omitted
      ],
    });
    final out = await CvEnhancementRepositoryImpl(ai: ai)
        .enhance(_cv, languageCode: 'en');
    expect(out.experiences[0].bullets, ['Rewrote first']);
    expect(out.experiences[1].bullets, ['helped out']); // untouched
  });

  test('passes the language into the prompt', () async {
    final ai = FakeAiService(json: {'summary': 'ملخص'});
    await CvEnhancementRepositoryImpl(ai: ai).enhance(_cv, languageCode: 'ar');
    expect(ai.lastPrompt, contains('Arabic'));
  });

  test('an empty response throws emptyEnhancement', () async {
    final ai = FakeAiService(json: {});
    expect(
      () => CvEnhancementRepositoryImpl(ai: ai).enhance(_cv, languageCode: 'en'),
      throwsA(isA<CvBuilderException>().having(
          (e) => e.code, 'code', CvErrorCode.emptyEnhancement)),
    );
  });

  test('propagates AI errors', () async {
    final ai = FakeAiService(error: const AiException(AiErrorCode.network));
    expect(
      () => CvEnhancementRepositoryImpl(ai: ai).enhance(_cv, languageCode: 'en'),
      throwsA(isA<AiException>()),
    );
  });
}

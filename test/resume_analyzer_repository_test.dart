import 'dart:typed_data';

import 'package:careerbridge/core/services/ai/ai_exception.dart';
import 'package:careerbridge/core/services/ai/ai_message.dart';
import 'package:careerbridge/core/services/ai/ai_service.dart';
import 'package:careerbridge/features/resume_analyzer/data/resume_analyzer_repository_impl.dart';
import 'package:careerbridge/features/resume_analyzer/domain/pdf_text_extractor.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analyzer_exception.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_ocr.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a fixed text regardless of the bytes.
class _FakeExtractor implements PdfTextExtractor {
  _FakeExtractor(this.text);
  final String text;
  @override
  Future<String> extract(Uint8List bytes) async => text;
}

/// Fake OCR: returns a fixed transcription (or throws) and records whether it ran.
class _FakeOcr implements ResumeOcr {
  _FakeOcr({this.text = '', this.error});
  final String text;
  final Object? error;
  bool called = false;
  @override
  Future<String> extractText(Uint8List bytes) async {
    called = true;
    if (error != null) throw error!;
    return text;
  }
}

/// Records the prompt and returns a canned JSON map (or throws).
class _FakeAi implements AiService {
  _FakeAi({this.json, this.error});
  final Map<String, dynamic>? json;
  final Object? error;
  String? lastPrompt;
  String? lastSystem;

  @override
  Future<Map<String, dynamic>> generateJson(String prompt,
      {String? systemInstruction}) async {
    lastPrompt = prompt;
    lastSystem = systemInstruction;
    if (error != null) throw error!;
    return json!;
  }

  @override
  Future<String> generateText(String prompt, {String? systemInstruction}) async => '';

  @override
  Stream<String> streamText(String prompt, {String? systemInstruction}) =>
      const Stream.empty();

  @override
  Stream<String> streamChat(List<AiMessage> history,
          {String? systemInstruction}) =>
      const Stream.empty();
}

const _longResume =
    'Experienced software engineer with a strong background in building '
    'scalable mobile applications using Flutter, Dart, and Firebase. '
    'Led teams and shipped production apps for millions of users.';

final _fullJson = <String, dynamic>{
  'atsScore': 88,
  'summary': 'Strong mobile engineering profile.',
  'strengths': ['Clear structure', 'Quantified impact'],
  'weaknesses': ['Missing summary'],
  'missingSkills': ['Kotlin'],
  'grammarIssues': [
    {'issue': 'Run-on', 'suggestion': 'Split it'},
  ],
  'improvementSuggestions': ['Add metrics'],
};

void main() {
  final bytes = Uint8List(0);

  test('analyze extracts text, calls AI, and maps the result', () async {
    final ai = _FakeAi(json: _fullJson);
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: ai, extractor: _FakeExtractor(_longResume));

    final result =
        await repo.analyze(pdfBytes: bytes, languageCode: 'en');

    expect(result.atsScore, 88);
    expect(result.strengths, contains('Clear structure'));
    expect(result.grammarIssues.single.suggestion, 'Split it');
    // Prompt carried the resume text and asked for English.
    expect(ai.lastPrompt, contains('Flutter'));
    expect(ai.lastPrompt, contains('English'));
    expect(ai.lastSystem, isNotNull);
  });

  test('prompt instructs field-first evaluation, a rubric, and date rules',
      () async {
    final ai = _FakeAi(json: _fullJson);
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: ai, extractor: _FakeExtractor(_longResume));

    await repo.analyze(pdfBytes: bytes, languageCode: 'en');
    final prompt = ai.lastPrompt!;
    final system = ai.lastSystem!;

    // Detects the field before evaluating.
    expect(prompt, contains('IDENTIFY THE FIELD'));
    expect(prompt, contains('careerField'));
    // Constrains recommendations to that field / bans unrelated domains.
    expect(prompt, contains('EVALUATE WITHIN THAT FIELD ONLY'));
    expect(prompt.toLowerCase(), contains('unrelated domain'));
    expect(system.toLowerCase(), contains('never recommend skills'));
    // Explicit 0-100 rubric.
    expect(prompt, contains('SCORING RUBRIC'));
    expect(prompt, contains('0-100'));
    // Logical date validation instead of hallucinated errors.
    expect(prompt, contains('DATE VALIDATION'));
    expect(prompt.toLowerCase(), contains('do not invent date'));
  });

  test('careerField from the model flows into the analysis', () async {
    final ai = _FakeAi(json: {
      ..._fullJson,
      'careerField': 'Computer Science — Cybersecurity',
    });
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: ai, extractor: _FakeExtractor(_longResume));

    final result = await repo.analyze(pdfBytes: bytes, languageCode: 'en');
    expect(result.careerField, 'Computer Science — Cybersecurity');
  });

  test('asks the model to respond in Arabic for the ar locale', () async {
    final ai = _FakeAi(json: _fullJson);
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: ai, extractor: _FakeExtractor(_longResume));

    await repo.analyze(pdfBytes: bytes, languageCode: 'ar');
    expect(ai.lastPrompt, contains('Arabic'));
  });

  test('throws noText when the PDF has no usable text and no OCR is available',
      () async {
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: _FakeAi(json: _fullJson), extractor: _FakeExtractor('   '));

    expect(
      () => repo.analyze(pdfBytes: bytes, languageCode: 'en'),
      throwsA(isA<ResumeAnalyzerException>()
          .having((e) => e.code, 'code', ResumeErrorCode.noText)),
    );
  });

  test('falls back to OCR when the PDF has no text layer (scanned CV)',
      () async {
    final ai = _FakeAi(json: _fullJson);
    final ocr = _FakeOcr(text: _longResume); // OCR recovers the text
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: ai, extractor: _FakeExtractor(''), ocr: ocr);

    final result = await repo.analyze(pdfBytes: bytes, languageCode: 'en');

    expect(ocr.called, isTrue, reason: 'OCR should run when no text extracted');
    expect(result.atsScore, 88); // analysis continued on the OCR result
    expect(ai.lastPrompt, contains('Flutter')); // OCR text reached the model
  });

  test('does NOT run OCR when the text layer is already usable', () async {
    final ocr = _FakeOcr(text: 'should not be used');
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: _FakeAi(json: _fullJson),
        extractor: _FakeExtractor(_longResume),
        ocr: ocr);

    await repo.analyze(pdfBytes: bytes, languageCode: 'en');
    expect(ocr.called, isFalse);
  });

  test('throws noText when both extraction and OCR come up empty', () async {
    final ocr = _FakeOcr(text: '   '); // OCR also fails to read anything
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: _FakeAi(json: _fullJson), extractor: _FakeExtractor(''), ocr: ocr);

    await expectLater(
      () => repo.analyze(pdfBytes: bytes, languageCode: 'en'),
      throwsA(isA<ResumeAnalyzerException>()
          .having((e) => e.code, 'code', ResumeErrorCode.noText)),
    );
    expect(ocr.called, isTrue);
  });

  test('propagates an OCR AI error (e.g. network) instead of masking it',
      () async {
    final repo = ResumeAnalyzerRepositoryImpl(
      ai: _FakeAi(json: _fullJson),
      extractor: _FakeExtractor(''),
      ocr: _FakeOcr(error: const AiException(AiErrorCode.network)),
    );

    expect(
      () => repo.analyze(pdfBytes: bytes, languageCode: 'en'),
      throwsA(isA<AiException>()
          .having((e) => e.code, 'code', AiErrorCode.network)),
    );
  });

  test('throws invalidResponse when the AI returns an empty analysis',
      () async {
    final repo = ResumeAnalyzerRepositoryImpl(
        ai: _FakeAi(json: const {}), extractor: _FakeExtractor(_longResume));

    expect(
      () => repo.analyze(pdfBytes: bytes, languageCode: 'en'),
      throwsA(isA<AiException>()
          .having((e) => e.code, 'code', AiErrorCode.invalidResponse)),
    );
  });

  test('propagates AI errors (e.g. network)', () async {
    final repo = ResumeAnalyzerRepositoryImpl(
      ai: _FakeAi(error: const AiException(AiErrorCode.network)),
      extractor: _FakeExtractor(_longResume),
    );

    expect(
      () => repo.analyze(pdfBytes: bytes, languageCode: 'en'),
      throwsA(isA<AiException>()
          .having((e) => e.code, 'code', AiErrorCode.network)),
    );
  });
}

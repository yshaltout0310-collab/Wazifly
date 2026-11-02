// The client-side CV size cap must stay in step with the backend's.
//
// `ResumeErrorCode.tooLarge` and its localized message existed from the start,
// but nothing ever raised it: an oversized PDF was read fully into memory and
// then rasterized page by page, which on the web build can stall or kill the
// tab. The controller now refuses the file up front — and it must refuse
// exactly what Cloud Storage would, or the two limits drift and a user gets a
// confusing backend rejection after a long upload.
import 'dart:io';

import 'package:careerbridge/features/resume_analyzer/application/resume_analyzer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client CV cap is 10 MB', () {
    expect(ResumeAnalyzerController.maxFileBytes, 10 * 1024 * 1024);
  });

  test('client CV cap matches the Cloud Storage rule for resume uploads', () {
    final rules = File('storage.rules').readAsStringSync();

    // The resumes/** block caps PDF uploads; parse the literal rather than
    // trusting a comment, so a change to either side fails this test.
    final match = RegExp(r'request\.resource\.size\s*<\s*(\d+)\s*\*\s*1024\s*\*\s*1024')
        .allMatches(rules)
        .map((m) => int.parse(m.group(1)!))
        .toList();

    expect(match, isNotEmpty,
        reason: 'storage.rules no longer declares a MB size cap');
    expect(
      match.contains(ResumeAnalyzerController.maxFileBytes ~/ (1024 * 1024)),
      isTrue,
      reason: 'client cap (${ResumeAnalyzerController.maxFileBytes ~/ (1024 * 1024)} MB) '
          'is not among the storage.rules caps $match — the client would accept '
          'a file the backend rejects, or vice versa',
    );
  });
}

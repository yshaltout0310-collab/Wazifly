import 'package:careerbridge/core/services/interview_store/in_memory_interview_history_repository.dart';
import 'package:careerbridge/features/interview_prep/domain/interview_models.dart';
import 'package:flutter_test/flutter_test.dart';

InterviewSession _session(String id, {int overall = 0}) => InterviewSession(
      id: id,
      type: InterviewType.hr,
      status: InterviewStatus.completed,
      createdAt: DateTime(2026, 7, 4),
      summary: InterviewSummary(scores: InterviewScores(overall: overall)),
    );

void main() {
  test('watchSessions emits current value then updates on save', () async {
    final repo = InMemoryInterviewHistoryRepository();
    final emissions = <List<InterviewSession>>[];
    final sub = repo.watchSessions().listen(emissions.add);

    await Future<void>.delayed(Duration.zero);
    expect(emissions.first, isEmpty);

    await repo.saveSession(_session('s1', overall: 70));
    await Future<void>.delayed(Duration.zero);
    expect(emissions.last.length, 1);
    expect(emissions.last.first.overallScore, 70);

    await sub.cancel();
  });

  test('save upserts by id (newest first for new inserts)', () async {
    final repo = InMemoryInterviewHistoryRepository();
    await repo.saveSession(_session('s1', overall: 50));
    await repo.saveSession(_session('s2', overall: 60));
    // Replace s1 in place.
    await repo.saveSession(_session('s1', overall: 90));

    final found = await repo.findById('s1');
    expect(found?.overallScore, 90);
    // s2 was inserted after s1, so newest-first order puts s2 at the front.
    final all = await repo.watchSessions().first;
    expect(all.length, 2);
    expect(all.first.id, 's2');
  });

  test('delete removes a session', () async {
    final repo = InMemoryInterviewHistoryRepository(seed: [_session('s1')]);
    await repo.delete('s1');
    expect(await repo.findById('s1'), isNull);
    expect(await repo.watchSessions().first, isEmpty);
  });
}

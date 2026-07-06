import 'package:careerbridge/features/employer/domain/applicant_status_flow.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending can move to any later stage', () {
    final next = ApplicationStatus.pending.allowedNext;
    expect(next, contains(ApplicationStatus.reviewed));
    expect(next, contains(ApplicationStatus.interview));
    expect(next, contains(ApplicationStatus.accepted));
    expect(next, contains(ApplicationStatus.rejected));
  });

  test('reviewed cannot go back to reviewed but can advance', () {
    expect(
        ApplicationStatus.reviewed.canMoveTo(ApplicationStatus.reviewed), isFalse);
    expect(
        ApplicationStatus.reviewed.canMoveTo(ApplicationStatus.interview), isTrue);
  });

  test('interview can only accept or reject', () {
    expect(ApplicationStatus.interview.allowedNext,
        {ApplicationStatus.accepted, ApplicationStatus.rejected});
  });

  test('terminal statuses can only reopen to reviewed', () {
    expect(ApplicationStatus.accepted.isTerminal, isTrue);
    expect(ApplicationStatus.rejected.isTerminal, isTrue);
    expect(ApplicationStatus.accepted.allowedNext, {ApplicationStatus.reviewed});
    expect(ApplicationStatus.rejected.canMoveTo(ApplicationStatus.reviewed),
        isTrue);
    expect(ApplicationStatus.rejected.canMoveTo(ApplicationStatus.accepted),
        isFalse);
  });

  test('non-terminal statuses are not terminal', () {
    expect(ApplicationStatus.pending.isTerminal, isFalse);
    expect(ApplicationStatus.interview.isTerminal, isFalse);
  });
}

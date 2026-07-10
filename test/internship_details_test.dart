import 'package:careerbridge/shared/models/internship_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enum tolerant parse', () {
    test('WorkMode accepts name + on-site aliases', () {
      expect(WorkMode.fromName('remote'), WorkMode.remote);
      expect(WorkMode.fromName('HYBRID'), WorkMode.hybrid);
      expect(WorkMode.fromName('on-site'), WorkMode.onsite);
      expect(WorkMode.fromName('on_site'), WorkMode.onsite);
      expect(WorkMode.fromName('nope'), isNull);
      expect(WorkMode.fromName(null), isNull);
    });

    test('funding/schedule aliases', () {
      expect(InternshipFunding.fromName('stipend'), InternshipFunding.paid);
      expect(InternshipSchedule.fromName('full-time'),
          InternshipSchedule.fullTime);
      expect(InternshipSchedule.fromName('flexible'),
          InternshipSchedule.flexible);
    });

    test('isRemoteish is true for remote + hybrid only', () {
      expect(WorkMode.onsite.isRemoteish, false);
      expect(WorkMode.remote.isRemoteish, true);
      expect(WorkMode.hybrid.isRemoteish, true);
    });
  });

  test('JSON round-trips all fields', () {
    final d = InternshipDetails(
      funding: InternshipFunding.paid,
      category: InternshipCategory.software,
      level: InternshipLevel.undergraduate,
      duration: InternshipDuration.threeToSixMonths,
      workMode: WorkMode.hybrid,
      eligibility: InternshipEligibility.universityStudents,
      schedule: InternshipSchedule.fullTime,
      certificateProvided: true,
      stipendAmount: 1200,
      currency: 'USD',
      startDate: DateTime(2026, 8, 1),
      applicationDeadline: DateTime(2026, 7, 15),
    );
    final back = InternshipDetails.fromJson(d.toJson());
    expect(back, d);
  });

  test('empty / partial JSON degrades without throwing', () {
    final empty = InternshipDetails.fromJson(const {});
    expect(empty.isEmpty, true);
    expect(empty.currency, 'USD');

    final partial = InternshipDetails.fromJson(const {
      'funding': 'paid',
      'certificate_provided': true,
      'work_mode': 'remote',
    });
    expect(partial.funding, InternshipFunding.paid);
    expect(partial.certificateProvided, true);
    expect(partial.workMode, WorkMode.remote);
    expect(partial.isEmpty, false);
  });

  test('copyWith clear flags null out fields', () {
    const d = InternshipDetails(
      funding: InternshipFunding.paid,
      workMode: WorkMode.remote,
      startDate: null,
    );
    final cleared = d.copyWith(clearFunding: true, clearWorkMode: true);
    expect(cleared.funding, isNull);
    expect(cleared.workMode, isNull);
  });

  test('isPaid reflects funding', () {
    expect(const InternshipDetails(funding: InternshipFunding.paid).isPaid, true);
    expect(
        const InternshipDetails(funding: InternshipFunding.unpaid).isPaid, false);
    expect(const InternshipDetails().isPaid, false);
  });
}

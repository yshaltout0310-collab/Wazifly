import 'package:careerbridge/features/employer/domain/analytics/analytics_calculator.dart';
import 'package:careerbridge/features/employer/domain/analytics/employer_analytics.dart';
import 'package:careerbridge/features/employer/domain/job_status.dart';
import 'package:careerbridge/shared/models/applicant_snapshot.dart';
import 'package:careerbridge/shared/models/application.dart';
import 'package:careerbridge/shared/models/employer_activity.dart';
import 'package:careerbridge/shared/models/job_posting.dart';
import 'package:flutter_test/flutter_test.dart';

JobPosting _job(String id, JobStatus status, {bool deleted = false}) =>
    JobPosting(
      id: id,
      companyId: 'c',
      ownerUid: 'c',
      title: 'Job $id',
      status: status,
      deletedAt: deleted ? DateTime(2026, 1, 1) : null,
    );

Application _app({
  required String id,
  String jobId = 'j1',
  String jobTitle = 'Flutter Engineer',
  required ApplicationStatus status,
  required DateTime appliedAt,
  DateTime? updatedAt,
  List<ApplicationEvent>? history,
  int? matchScore,
  int? atsScore,
  List<String> skills = const [],
}) =>
    Application(
      id: id,
      jobId: jobId,
      jobTitle: jobTitle,
      company: 'Acme',
      location: 'Doha',
      status: status,
      appliedAt: appliedAt,
      updatedAt: updatedAt ?? appliedAt,
      history: history ??
          [ApplicationEvent(status: ApplicationStatus.pending, at: appliedAt)],
      ownerUid: 'c',
      applicant: (matchScore != null || atsScore != null || skills.isNotEmpty)
          ? ApplicantSnapshot(
              name: 'A $id',
              matchScore: matchScore,
              atsScore: atsScore,
              skills: skills,
            )
          : null,
    );

final _now = DateTime(2026, 7, 15, 12);

void main() {
  group('empty / degenerate', () {
    test('no data yields empty analytics', () {
      final a = AnalyticsCalculator.compute(
          jobs: const [], applicants: const [], now: _now);
      expect(a.hasApplicants, isFalse);
      expect(a.hasJobs, isFalse);
      expect(a.overview.totalApplicants, 0);
      expect(a.funnel.isEmpty, isTrue);
      expect(a.timeToHire.hasHires, isFalse);
      expect(a.quality.hasMatchData, isFalse);
      expect(a.jobPerformance, isEmpty);
    });
  });

  group('overview', () {
    test('active jobs count only published, non-deleted', () {
      final a = AnalyticsCalculator.compute(
        jobs: [
          _job('1', JobStatus.published),
          _job('2', JobStatus.published),
          _job('3', JobStatus.draft),
          _job('4', JobStatus.archived),
          _job('5', JobStatus.published, deleted: true),
        ],
        applicants: const [],
        now: _now,
      );
      expect(a.overview.totalJobs, 4); // deleted excluded
      expect(a.overview.activeJobs, 2);
      expect(a.hasJobs, isTrue);
    });

    test('avg match score averages only applicants that carry one', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          _app(id: '1', status: ApplicationStatus.pending, appliedAt: _now, matchScore: 90),
          _app(id: '2', status: ApplicationStatus.pending, appliedAt: _now, matchScore: 70),
          _app(id: '3', status: ApplicationStatus.pending, appliedAt: _now), // no snapshot
        ],
        now: _now,
      );
      expect(a.overview.totalApplicants, 3);
      expect(a.overview.avgMatchScore, 80); // (90+70)/2
    });
  });

  group('funnel', () {
    test('reached-stage counts are monotonic and use history', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          // pending only
          _app(id: '1', status: ApplicationStatus.pending, appliedAt: _now),
          // reviewed
          _app(
            id: '2',
            status: ApplicationStatus.reviewed,
            appliedAt: _now,
            history: [
              ApplicationEvent(status: ApplicationStatus.pending, at: _now),
              ApplicationEvent(status: ApplicationStatus.reviewed, at: _now),
            ],
          ),
          // interviewed
          _app(
            id: '3',
            status: ApplicationStatus.interview,
            appliedAt: _now,
            history: [
              ApplicationEvent(status: ApplicationStatus.pending, at: _now),
              ApplicationEvent(status: ApplicationStatus.interview, at: _now),
            ],
          ),
          // accepted directly (skips reviewed/interview events)
          _app(
            id: '4',
            status: ApplicationStatus.accepted,
            appliedAt: _now,
            history: [
              ApplicationEvent(status: ApplicationStatus.pending, at: _now),
              ApplicationEvent(status: ApplicationStatus.accepted, at: _now),
            ],
          ),
        ],
        now: _now,
      );
      final f = a.funnel;
      expect(f.applied, 4);
      expect(f.reviewed, 3); // #2,#3,#4 all reached at least reviewed
      expect(f.interview, 2); // #3,#4
      expect(f.accepted, 1); // #4
      expect(f.rejected, 0);
      // monotonic
      expect(f.reviewed >= f.interview, isTrue);
      expect(f.interview >= f.accepted, isTrue);
    });

    test('rejection keeps prior funnel progress and counts rejected', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          _app(
            id: '1',
            status: ApplicationStatus.rejected,
            appliedAt: _now,
            history: [
              ApplicationEvent(status: ApplicationStatus.pending, at: _now),
              ApplicationEvent(status: ApplicationStatus.interview, at: _now),
              ApplicationEvent(status: ApplicationStatus.rejected, at: _now),
            ],
          ),
          // rejected at the pending stage
          _app(
            id: '2',
            status: ApplicationStatus.rejected,
            appliedAt: _now,
            history: [
              ApplicationEvent(status: ApplicationStatus.pending, at: _now),
              ApplicationEvent(status: ApplicationStatus.rejected, at: _now),
            ],
          ),
        ],
        now: _now,
      );
      final f = a.funnel;
      expect(f.applied, 2);
      expect(f.reviewed, 1); // only #1 progressed
      expect(f.interview, 1);
      expect(f.accepted, 0);
      expect(f.rejected, 2);
      expect(f.interviewShare, 0.5);
    });
  });

  group('time to hire', () {
    test('averages, median and fastest from accepted history timestamps', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          _app(
            id: '1',
            status: ApplicationStatus.accepted,
            appliedAt: DateTime(2026, 7, 1),
            history: [
              ApplicationEvent(status: ApplicationStatus.pending, at: DateTime(2026, 7, 1)),
              ApplicationEvent(status: ApplicationStatus.accepted, at: DateTime(2026, 7, 3)),
            ],
          ), // 2 days
          _app(
            id: '2',
            status: ApplicationStatus.accepted,
            appliedAt: DateTime(2026, 7, 1),
            history: [
              ApplicationEvent(status: ApplicationStatus.pending, at: DateTime(2026, 7, 1)),
              ApplicationEvent(status: ApplicationStatus.accepted, at: DateTime(2026, 7, 11)),
            ],
          ), // 10 days
        ],
        now: _now,
      );
      final t = a.timeToHire;
      expect(t.hiresConsidered, 2);
      expect(t.avgDaysToHire, 6); // (2+10)/2
      expect(t.medianDaysToHire, 6); // (2+10)/2
      expect(t.fastestDaysToHire, 2);
    });

    test('avg wait derives from open (non-terminal) applicants and now', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          _app(id: '1', status: ApplicationStatus.pending, appliedAt: DateTime(2026, 7, 5)), // 10 days
          _app(id: '2', status: ApplicationStatus.reviewed, appliedAt: DateTime(2026, 7, 11)), // 4 days
          _app(id: '3', status: ApplicationStatus.rejected, appliedAt: DateTime(2026, 7, 1)), // terminal, excluded
        ],
        now: _now,
      );
      final t = a.timeToHire;
      expect(t.openApplicants, 2);
      // now is 2026-07-15 12:00, applied at midnights → 10.5 and 4.5 days.
      expect(t.avgDaysInPipeline, closeTo(7.5, 0.01));
      expect(t.hasHires, isFalse); // no accepted applicants
    });
  });

  group('applicant quality', () {
    test('match bands bucket scores and are always four in order', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          _app(id: '1', status: ApplicationStatus.pending, appliedAt: _now, matchScore: 85), // strong
          _app(id: '2', status: ApplicationStatus.pending, appliedAt: _now, matchScore: 65), // good
          _app(id: '3', status: ApplicationStatus.pending, appliedAt: _now, matchScore: 45), // fair
          _app(id: '4', status: ApplicationStatus.pending, appliedAt: _now, matchScore: 20), // weak
          _app(id: '5', status: ApplicationStatus.pending, appliedAt: _now, matchScore: 95), // strong
        ],
        now: _now,
      );
      final q = a.quality;
      expect(q.withMatchCount, 5);
      expect(q.bands.map((b) => b.band).toList(),
          [MatchBand.strong, MatchBand.good, MatchBand.fair, MatchBand.weak]);
      expect(q.bands[0].count, 2); // strong
      expect(q.bands[1].count, 1);
      expect(q.bands[2].count, 1);
      expect(q.bands[3].count, 1);
    });

    test('top skills count once per applicant, case-insensitively, sorted', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          _app(id: '1', status: ApplicationStatus.pending, appliedAt: _now, skills: ['Flutter', 'Dart']),
          _app(id: '2', status: ApplicationStatus.pending, appliedAt: _now, skills: ['flutter', 'Go']),
          _app(id: '3', status: ApplicationStatus.pending, appliedAt: _now, skills: ['Flutter', 'Flutter']),
          _app(id: '4', status: ApplicationStatus.pending, appliedAt: _now, atsScore: 70),
        ],
        now: _now,
      );
      final q = a.quality;
      expect(q.topSkills.first.skill, 'Flutter');
      expect(q.topSkills.first.count, 3); // once per applicant despite dup in #3
      expect(q.avgAtsScore, 70);
      expect(q.withResumeCount, 1);
    });
  });

  group('job performance', () {
    test('sorts by applicants desc and includes live jobs with zero', () {
      final a = AnalyticsCalculator.compute(
        jobs: [
          _job('j1', JobStatus.published),
          _job('j2', JobStatus.published),
          _job('j3', JobStatus.published), // no applicants
        ],
        applicants: [
          _app(id: '1', jobId: 'j2', status: ApplicationStatus.pending, appliedAt: _now),
          _app(id: '2', jobId: 'j1', status: ApplicationStatus.pending, appliedAt: _now),
          _app(id: '3', jobId: 'j1', status: ApplicationStatus.accepted, appliedAt: _now, history: [
            ApplicationEvent(status: ApplicationStatus.pending, at: _now),
            ApplicationEvent(status: ApplicationStatus.accepted, at: _now),
          ]),
        ],
        now: _now,
      );
      expect(a.jobPerformance.length, 3);
      expect(a.jobPerformance.first.jobId, 'j1');
      expect(a.jobPerformance.first.applicants, 2);
      expect(a.jobPerformance.first.hires, 1);
      expect(a.jobPerformance.first.conversion, 0.5);
      expect(a.jobPerformance.first.status, JobStatus.published);
      expect(a.jobPerformance.last.applicants, 0); // j3
    });

    test('a job referenced only by applications has a null status', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [], // employer has no matching posting
        applicants: [
          _app(id: '1', jobId: 'ghost', status: ApplicationStatus.pending, appliedAt: _now),
        ],
        now: _now,
      );
      expect(a.jobPerformance.single.jobId, 'ghost');
      expect(a.jobPerformance.single.status, isNull);
      expect(a.jobPerformance.single.applicants, 1);
    });
  });

  group('activity trend', () {
    test('buckets applications into weekly windows and counts last 7 days', () {
      final a = AnalyticsCalculator.compute(
        jobs: const [],
        applicants: [
          _app(id: '1', status: ApplicationStatus.pending, appliedAt: DateTime(2026, 7, 14)), // this week
          _app(id: '2', status: ApplicationStatus.pending, appliedAt: DateTime(2026, 7, 10)), // this week
          _app(id: '3', status: ApplicationStatus.pending, appliedAt: DateTime(2026, 7, 2)), // ~2 weeks ago
        ],
        activity: [
          EmployerActivity(
            id: 'act1',
            ownerUid: 'c',
            type: EmployerActivityType.statusInterview,
            applicationId: '1',
            at: DateTime(2026, 7, 14),
          ),
        ],
        now: _now,
      );
      final t = a.trend;
      expect(t.points.length, AnalyticsCalculator.trendWeeks);
      expect(t.points.last.count, 2); // newest bucket = this week
      expect(t.applicationsLast7Days, 2);
      expect(t.actionsLast7Days, 1);
      expect(t.totalActions, 1);
      expect(t.hasActivity, isTrue);
    });
  });
}

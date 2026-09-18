// Regression guard for the security properties the marketplace depends on.
//
// Rule *enforcement* can only be executed against the Firestore emulator or the
// live backend, which this suite has no access to. What a unit test CAN do is
// stop the guarantees from being quietly deleted — every clause asserted below
// is load-bearing, and removing one would silently open a hole that no other
// test would notice. This mirrors android_manifest_test.dart, which pins the
// permission surface the same way.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final rules = File('firestore.rules').readAsStringSync();
  final storage = File('storage.rules').readAsStringSync();

  /// The text of one `match /<collection>/{...}` block.
  String block(String collection) {
    final start = rules.indexOf('match /$collection/');
    expect(start, greaterThan(-1), reason: 'no rule block for $collection');
    final next = rules.indexOf('match /', start + 1);
    return rules.substring(start, next == -1 ? rules.length : next);
  }

  group('applications — the collection both sides of the marketplace share', () {
    late String app;
    setUp(() => app = block('applications'));

    test('an applicant can only file an application as themselves', () {
      expect(
        app.contains(
            "request.resource.data.applicantUid == request.auth.uid"),
        isTrue,
        reason: 'create must pin applicantUid to the caller',
      );
    });

    test('the claimed employer is corroborated against the referenced job', () {
      // Without this, any signed-in user could inject documents into an
      // arbitrary employer's applicant pipeline just by setting ownerUid.
      expect(app.contains('ownerMatchesJob()'), isTrue);
      expect(app.contains('get(jobPath(jobId)).data.ownerUid == claimed'),
          isTrue);
      expect(app.contains("!exists(jobPath(jobId)) && claimed == ''"), isTrue,
          reason: 'demo-catalogue jobs may only be applied to with no employer');
    });

    test('a new application cannot start anywhere but pending', () {
      expect(app.contains("request.resource.data.status == 'pending'"), isTrue,
          reason: 'an applicant must not be able to self-advance the pipeline');
    });

    test('only the job owner may update, and identity stays immutable', () {
      expect(app.contains('resource.data.ownerUid == request.auth.uid'), isTrue);
      for (final field in ['applicantUid', 'ownerUid', 'companyId', 'jobId']) {
        expect(app.contains("unchanged('$field')"), isTrue,
            reason: '$field must be immutable on update');
      }
    });

    test('reads are limited to the two parties', () {
      expect(app.contains('resource.data.applicantUid == request.auth.uid'),
          isTrue);
      expect(app.contains('resource.data.ownerUid == request.auth.uid'), isTrue);
    });

    test('only the applicant may withdraw', () {
      final delete = app.substring(app.indexOf('allow delete'));
      expect(delete.contains('resource.data.applicantUid == request.auth.uid'),
          isTrue);
    });

    test('free text is size-capped', () {
      for (final field in ['jobTitle', 'company', 'location', 'note']) {
        expect(app.contains("capped('$field'"), isTrue,
            reason: '$field must be capped');
      }
    });
  });

  group('jobs — the employer-owned catalogue seekers read', () {
    late String jobs;
    setUp(() => jobs = block('jobs'));

    test('a seeker can read published postings', () {
      expect(jobs.contains("resource.data.status == 'published'"), isTrue,
          reason: 'this clause is what makes the public catalogue readable');
    });

    test('an unpublished posting is visible only to its owner', () {
      expect(jobs.contains('resource.data.ownerUid == request.auth.uid'),
          isTrue);
    });

    test('only the owner may create, update or delete a posting', () {
      expect(jobs.contains('request.resource.data.ownerUid == request.auth.uid'),
          isTrue, reason: 'create pins ownership');
      expect(jobs.contains("unchanged('ownerUid')"), isTrue,
          reason: 'a posting can never be repointed to another employer');
      final delete = jobs.substring(jobs.indexOf('allow delete'));
      expect(delete.contains('resource.data.ownerUid == request.auth.uid'),
          isTrue);
    });

    test('posting text stays size-capped', () {
      for (final field in ['title', 'description', 'status']) {
        expect(jobs.contains("capped('$field'"), isTrue);
      }
    });
  });

  group('pre-existing protections are still intact', () {
    test('a user profile is private to that user', () {
      final users = block('users');
      expect(users.contains('request.auth.uid == uid'), isTrue);
    });

    test('CVs are owner-scoped and ownership is immutable', () {
      final resumes = block('resumes');
      expect(resumes.contains('resource.data.ownerUid == request.auth.uid'),
          isTrue);
      expect(resumes.contains("unchanged('ownerUid')"), isTrue);
    });

    test('employer notes never leak to the applicant', () {
      final notes = block('applicationNotes');
      expect(notes.contains('resource.data.ownerUid == request.auth.uid'),
          isTrue);
      expect(notes.contains('applicantUid'), isFalse,
          reason: 'notes are employer-private by construction');
    });

    test('the employer activity trail stays append-only', () {
      final activity = block('employerActivity');
      expect(activity.contains('allow update'), isFalse);
      expect(activity.contains('allow delete'), isFalse);
    });

    test('storage keeps its content-type and size caps', () {
      expect(storage.contains('isImageUnder(5)'), isTrue);
      expect(storage.contains("contentType == 'application/pdf'"), isTrue);
      expect(storage.contains('match /b/{bucket}/o/{allPaths=**}'), isFalse,
          reason: 'a catch-all would bypass every cap above it');
    });
  });
}

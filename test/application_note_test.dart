import 'package:careerbridge/shared/models/application_note.dart';
import 'package:careerbridge/shared/models/employer_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApplicationNote', () {
    test('round-trips through toJson/fromJson', () {
      final note = ApplicationNote(
        id: 'n1',
        applicationId: 'a1',
        ownerUid: 'emp1',
        authorUid: 'emp1',
        text: 'Strong candidate',
        createdAt: DateTime(2026, 7, 6, 10),
        updatedAt: DateTime(2026, 7, 6, 10),
      );
      expect(ApplicationNote.fromJson(note.toJson()), note);
    });

    test('copyWith updates text + updatedAt, keeps identity', () {
      final note = ApplicationNote(
        id: 'n1',
        applicationId: 'a1',
        ownerUid: 'emp1',
        text: 'first',
        createdAt: DateTime(2026, 7, 6, 10),
        updatedAt: DateTime(2026, 7, 6, 10),
      );
      final edited =
          note.copyWith(text: 'second', updatedAt: DateTime(2026, 7, 6, 11));
      expect(edited.text, 'second');
      expect(edited.id, 'n1');
      expect(edited.ownerUid, 'emp1');
      expect(edited.createdAt, note.createdAt);
    });

    test('fromJson tolerates snake_case + missing updatedAt', () {
      final note = ApplicationNote.fromJson({
        'id': 'n2',
        'application_id': 'a2',
        'owner_uid': 'emp2',
        'text': 'note',
        'created_at': DateTime(2026, 7, 6).millisecondsSinceEpoch,
      });
      expect(note.applicationId, 'a2');
      expect(note.ownerUid, 'emp2');
      expect(note.updatedAt, note.createdAt);
    });
  });

  group('EmployerActivity', () {
    test('round-trips and parses type defensively', () {
      final act = EmployerActivity(
        id: 'act1',
        ownerUid: 'emp1',
        actorUid: 'emp1',
        type: EmployerActivityType.statusAccept,
        applicationId: 'a1',
        at: DateTime(2026, 7, 6, 12),
        from: 'interview',
        to: 'accepted',
      );
      expect(EmployerActivity.fromJson(act.toJson()), act);
      expect(employerActivityTypeFromName('noteAdded'),
          EmployerActivityType.noteAdded);
      expect(employerActivityTypeFromName('???'),
          EmployerActivityType.statusReview);
    });
  });
}

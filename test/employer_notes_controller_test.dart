import 'package:careerbridge/core/services/activity/employer_activity_repository.dart';
import 'package:careerbridge/core/services/activity/in_memory_employer_activity_repository.dart';
import 'package:careerbridge/core/services/notes/employer_notes_repository.dart';
import 'package:careerbridge/core/services/notes/in_memory_employer_notes_repository.dart';
import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/employer/application/employer_notes_controller.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:careerbridge/shared/models/application_note.dart';
import 'package:careerbridge/shared/models/employer_activity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

const _user = AppUser(uid: 'emp1', method: AuthMethod.email, email: 'e@b.co');

class _ThrowingNotesRepo implements EmployerNotesRepository {
  @override
  Future<ApplicationNote> addNote(ApplicationNote n) async => throw 'boom';
  @override
  Future<void> updateNote(ApplicationNote n) async => throw 'boom';
  @override
  Future<void> deleteNote(String id) async => throw 'boom';
  @override
  Stream<List<ApplicationNote>> watchNotes(String a, String o) =>
      Stream.value(const []);
}

({ProviderContainer container, InMemoryEmployerActivityRepository activity})
    _make(EmployerNotesRepository repo) {
  final activity = InMemoryEmployerActivityRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: _user)),
    employerNotesRepositoryProvider.overrideWithValue(repo),
    employerActivityRepositoryProvider.overrideWithValue(activity),
  ]);
  addTearDown(container.dispose);
  return (container: container, activity: activity);
}

void main() {
  test('add persists a note (owned by the employer) and logs activity', () async {
    final repo = InMemoryEmployerNotesRepository();
    final (:container, :activity) = _make(repo);
    await container
        .read(employerNotesControllerProvider.notifier)
        .add('a1', 'Great candidate');

    final notes = await repo.watchNotes('a1', 'emp1').first;
    expect(notes.length, 1);
    expect(notes.single.text, 'Great candidate');
    expect(notes.single.ownerUid, 'emp1');
    expect(notes.single.authorUid, 'emp1');
    expect(container.read(employerNotesControllerProvider).failure, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(activity.logged.map((e) => e.type),
        contains(EmployerActivityType.noteAdded));
  });

  test('blank text is ignored', () async {
    final repo = InMemoryEmployerNotesRepository();
    final (:container, :activity) = _make(repo);
    await container
        .read(employerNotesControllerProvider.notifier)
        .add('a1', '   ');
    expect(await repo.watchNotes('a1', 'emp1').first, isEmpty);
  });

  test('edit updates text; delete removes', () async {
    final repo = InMemoryEmployerNotesRepository();
    final (:container, :activity) = _make(repo);
    final ctrl = container.read(employerNotesControllerProvider.notifier);
    await ctrl.add('a1', 'first');
    final note = (await repo.watchNotes('a1', 'emp1').first).single;

    await ctrl.edit(note, 'second');
    expect((await repo.watchNotes('a1', 'emp1').first).single.text, 'second');

    await ctrl.delete(note);
    expect(await repo.watchNotes('a1', 'emp1').first, isEmpty);
  });

  test('a write failure rolls back and surfaces a failure', () async {
    final (:container, :activity) = _make(_ThrowingNotesRepo());
    await container
        .read(employerNotesControllerProvider.notifier)
        .add('a1', 'x');
    final state = container.read(employerNotesControllerProvider);
    expect(state.failure, NotesActionFailure.unknown);
    expect(state.added, isEmpty); // optimistic add rolled back
    expect(state.pending, isEmpty);
  });
}

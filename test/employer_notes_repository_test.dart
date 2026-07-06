import 'package:careerbridge/core/services/notes/in_memory_employer_notes_repository.dart';
import 'package:careerbridge/shared/models/application_note.dart';
import 'package:flutter_test/flutter_test.dart';

ApplicationNote _note(String id,
        {String owner = 'emp1', String app = 'a1', DateTime? created}) =>
    ApplicationNote(
      id: id,
      applicationId: app,
      ownerUid: owner,
      text: 'note $id',
      createdAt: created ?? DateTime(2026, 7, 6),
      updatedAt: created ?? DateTime(2026, 7, 6),
    );

void main() {
  test('watchNotes filters by owner + application, oldest-first', () async {
    final repo = InMemoryEmployerNotesRepository(seed: [
      _note('n2', created: DateTime(2026, 7, 6, 12)),
      _note('n1', created: DateTime(2026, 7, 6, 9)),
      _note('n3', owner: 'other'),
      _note('n4', app: 'a2'),
    ]);
    final first = await repo.watchNotes('a1', 'emp1').first;
    expect(first.map((n) => n.id), ['n1', 'n2']);
  });

  test('add / update / delete re-emit', () async {
    final repo = InMemoryEmployerNotesRepository();
    final emissions = <List<String>>[];
    final sub = repo
        .watchNotes('a1', 'emp1')
        .listen((notes) => emissions.add(notes.map((n) => n.id).toList()));

    await repo.addNote(_note('n1'));
    await repo.updateNote(_note('n1').copyWith(text: 'edited'));
    await repo.deleteNote('n1');
    await Future<void>.delayed(Duration.zero);

    expect(emissions.last, isEmpty);
    await sub.cancel();
  });
}

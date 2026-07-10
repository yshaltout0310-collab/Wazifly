import 'package:careerbridge/core/services/cv_repository/cv_document.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 1, 1);
  final t1 = DateTime(2026, 1, 2);

  CvDocument make({String name = 'CV', CvData? content}) => CvDocument.create(
        id: 'cv1',
        ownerUid: 'u1',
        name: name,
        content: content ?? const CvData(fullName: 'Ada', summary: 'Engineer'),
        now: t0,
      );

  group('CvDocument lifecycle', () {
    test('create defaults: active, version 1, not deleted', () {
      final cv = make();
      expect(cv.status, CvStatus.active);
      expect(cv.isActive, isTrue);
      expect(cv.version, 1);
      expect(cv.isDeleted, isFalse);
      expect(cv.atsScore, isNull);
    });

    test('renamed / withTags update fields + updatedAt', () {
      final cv = make().renamed('New name', t1).withTags(['Flutter', 'flutter', ' Backend '], t1);
      expect(cv.name, 'New name');
      // tags de-duplicated (case-insensitive) + trimmed
      expect(cv.tags, ['Flutter', 'Backend']);
      expect(cv.updatedAt, t1);
    });

    test('archive clears default; restore reactivates', () {
      final cv = make().asDefault(t0);
      final archived = cv.archived(t1);
      expect(archived.isArchived, isTrue);
      expect(archived.isDefault, isFalse);
      expect(archived.restored(t1).isActive, isTrue);
    });

    test('withContent bumps the version', () {
      final cv = make();
      final edited = cv.withContent(const CvData(fullName: 'Grace'), t1);
      expect(edited.version, 2);
      expect(edited.content.fullName, 'Grace');
    });

    test('markUsed records last-used info', () {
      final cv = make().markUsed(t1, jobTitle: 'Engineer', company: 'Acme');
      expect(cv.lastUsedAt, t1);
      expect(cv.lastAppliedJobTitle, 'Engineer');
      expect(cv.lastAppliedCompany, 'Acme');
    });

    test('softDeleted excludes from active + clears default', () {
      final cv = make().asDefault(t0).softDeleted(t1);
      expect(cv.isDeleted, isTrue);
      expect(cv.isActive, isFalse);
      expect(cv.isDefault, isFalse);
    });

    test('duplicatedAs copies content/tags, resets default + version', () {
      final cv = make().withTags(['A'], t0).asDefault(t0);
      final dup = cv.duplicatedAs(id: 'cv2', name: 'CV (copy)', now: t1);
      expect(dup.id, 'cv2');
      expect(dup.isDefault, isFalse);
      expect(dup.version, 1);
      expect(dup.tags, ['A']);
      expect(dup.content, cv.content);
    });
  });

  group('CvDocument serialization + hashing', () {
    test('round-trips through JSON', () {
      final cv = make(name: 'Alpha')
          .withTags(['X', 'Y'], t0)
          .markUsed(t1, jobTitle: 'Dev', company: 'Co');
      final back = CvDocument.fromJson(cv.toJson());
      expect(back.id, cv.id);
      expect(back.name, cv.name);
      expect(back.tags, cv.tags);
      expect(back.lastAppliedJobTitle, 'Dev');
      expect(back.content.fullName, 'Ada');
    });

    test('contentHash is deterministic and content-sensitive', () {
      final a = make(content: const CvData(fullName: 'Ada'));
      final b = make(content: const CvData(fullName: 'Ada'));
      final c = make(content: const CvData(fullName: 'Bob'));
      expect(a.contentHash, b.contentHash);
      expect(a.contentHash, isNot(c.contentHash));
    });

    test('hashBytes is stable for identical bytes', () {
      expect(CvDocument.hashBytes([1, 2, 3]), CvDocument.hashBytes([1, 2, 3]));
      expect(CvDocument.hashBytes([1, 2, 3]),
          isNot(CvDocument.hashBytes([1, 2, 4])));
    });
  });
}

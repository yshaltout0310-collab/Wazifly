import 'package:careerbridge/core/services/cv_repository/cv_document.dart';
import 'package:careerbridge/core/services/cv_repository/cv_repository.dart';
import 'package:careerbridge/core/services/cv_repository/in_memory_cv_repository.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:careerbridge/features/cv_repository/application/cv_library_controller.dart';
import 'package:careerbridge/features/cv_repository/domain/cv_sort.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

void main() {
  const user = AppUser(uid: 'u1', method: AuthMethod.email, email: 'a@b.com');
  final now = DateTime(2026, 1, 1);

  CvDocument cv(String id, String name,
          {List<String> tags = const [],
          int? ats,
          bool archived = false,
          int minutes = 0}) {
    var d = CvDocument.create(
      id: id,
      ownerUid: 'u1',
      name: name,
      content: const CvData(),
      now: now.add(Duration(minutes: minutes)),
      tags: tags,
    );
    if (ats != null) {
      d = d.withAnalysis(
        ResumeAnalysis(
          atsScore: ats,
          summary: '',
          strengths: const [],
          weaknesses: const [],
          missingSkills: const [],
          grammarIssues: const [],
          improvementSuggestions: const [],
        ),
        now,
      );
    }
    if (archived) d = d.archived(now);
    return d;
  }

  Future<ProviderContainer> seeded(List<CvDocument> docs) async {
    final repo = InMemoryCvRepository(seed: docs);
    final c = ProviderContainer(overrides: [
      fakeAuthOverride(user: user),
      cvRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    c.listen(cvDocumentsProvider, (_, __) {}); // keep the stream alive
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return c;
  }

  test('search matches name and tags', () async {
    final c = await seeded([
      cv('a', 'Backend CV', tags: ['Go']),
      cv('b', 'Frontend CV', tags: ['Flutter', 'Dart']),
    ]);
    c.read(cvLibraryControllerProvider.notifier).setQuery('flutter');
    final visible = c.read(visibleCvsProvider);
    expect(visible.map((d) => d.id), ['b']);

    c.read(cvLibraryControllerProvider.notifier).setQuery('cv');
    expect(c.read(visibleCvsProvider).length, 2);
  });

  test('status filter splits active vs archived', () async {
    final c = await seeded([
      cv('a', 'Active'),
      cv('b', 'Old', archived: true),
    ]);
    expect(c.read(visibleCvsProvider).map((d) => d.id), ['a']);
    c.read(cvLibraryControllerProvider.notifier).setFilter(CvStatusFilter.archived);
    expect(c.read(visibleCvsProvider).map((d) => d.id), ['b']);
  });

  test('sort by name / ATS', () async {
    final c = await seeded([
      cv('a', 'Zebra', ats: 50, minutes: 2),
      cv('b', 'Alpha', ats: 90, minutes: 1),
    ]);
    c.read(cvLibraryControllerProvider.notifier).setSort(CvSortOption.nameAsc);
    expect(c.read(visibleCvsProvider).map((d) => d.name), ['Alpha', 'Zebra']);
    c.read(cvLibraryControllerProvider.notifier).setSort(CvSortOption.atsDesc);
    expect(c.read(visibleCvsProvider).map((d) => d.id), ['b', 'a']);
  });
}

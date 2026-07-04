import 'package:careerbridge/features/cv_builder/application/cv_builder_controller.dart';
import 'package:careerbridge/core/services/cv_store/cv_draft_store.dart';
import 'package:careerbridge/features/cv_builder/data/cv_enhancement_repository_impl.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_builder_exception.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_data.dart';
import 'package:careerbridge/features/cv_builder/domain/cv_enhancement_repository.dart';
import 'package:careerbridge/features/resume_analyzer/domain/resume_analysis.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

class _FakeEnhancement implements CvEnhancementRepository {
  _FakeEnhancement(this.result);
  final Object result; // CvData or a thrown error
  @override
  Future<CvData> enhance(CvData data,
      {required String languageCode, ResumeAnalysis? analysis}) async {
    if (result is CvData) return result as CvData;
    throw result;
  }
}

const _user = AppUser(uid: 'u1', method: AuthMethod.email, displayName: 'Sarah');
const _draft = CvData(fullName: 'Sarah Ahmed', headline: 'Flutter Engineer');

ProviderContainer _container({
  AppUser? user = _user,
  CvData? draft,
  Object? enhancement,
}) {
  final store = InMemoryCvDraftStore();
  if (draft != null) store.write(draft);
  final container = ProviderContainer(
    overrides: [
      fakeAuthOverride(user: user),
      cvDraftStoreProvider.overrideWithValue(store),
      if (enhancement != null)
        cvEnhancementRepositoryProvider
            .overrideWithValue(_FakeEnhancement(enhancement)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('signed-out users land on needsProfile', () {
    final c = _container(user: null);
    expect(c.read(cvBuilderControllerProvider).status,
        CvBuilderStatus.needsProfile);
  });

  test('resumes an in-progress draft when present', () {
    final c = _container(draft: _draft);
    final state = c.read(cvBuilderControllerProvider);
    expect(state.status, CvBuilderStatus.editing);
    expect(state.data.fullName, 'Sarah Ahmed');
  });

  test('updateData writes through to the draft store', () {
    final c = _container(draft: _draft);
    c.read(cvBuilderControllerProvider.notifier).updateData(
          const CvData(fullName: 'Edited'),
        );
    expect(c.read(cvBuilderControllerProvider).data.fullName, 'Edited');
    expect(c.read(cvDraftStoreProvider).read()?.fullName, 'Edited');
  });

  test('enhance applies the AI result', () async {
    const enhanced = CvData(fullName: 'Sarah Ahmed', summary: 'AI summary');
    final c = _container(draft: _draft, enhancement: enhanced);
    await c
        .read(cvBuilderControllerProvider.notifier)
        .enhance(languageCode: 'en');
    final state = c.read(cvBuilderControllerProvider);
    expect(state.status, CvBuilderStatus.editing);
    expect(state.data.summary, 'AI summary');
    expect(state.failure, isNull);
  });

  test('enhance maps an empty-enhancement error to a failure', () async {
    final c = _container(
      draft: _draft,
      enhancement: const CvBuilderException(CvErrorCode.emptyEnhancement),
    );
    await c
        .read(cvBuilderControllerProvider.notifier)
        .enhance(languageCode: 'en');
    final state = c.read(cvBuilderControllerProvider);
    expect(state.status, CvBuilderStatus.editing);
    expect(state.failure, CvBuilderFailure.emptyEnhancement);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/learning/learning_profile_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/learning_profile.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/status_view.dart';
import '../application/learning_controller.dart';
import 'widgets/interest_category_card.dart';
import 'widgets/interest_editor_sheet.dart';

/// Maintain the seeker's learning interests across five categories, each with
/// Add / Edit / Delete, plus a search that filters across all categories.
class LearningInterestsScreen extends ConsumerWidget {
  const LearningInterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(learningProfileProvider);
    final query = ref.watch(learningControllerProvider).query;
    final controller = ref.read(learningControllerProvider.notifier);

    ref.listen(learningControllerProvider.select((s) => s.failure),
        (prev, next) {
      if (next != null) {
        final msg = switch (next) {
          LearningFailure.notSignedIn => l10n.learningNotSignedIn,
          LearningFailure.saveFailed => l10n.learningSaveFailed,
        };
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
        controller.clearFailure();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learningTitle)),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                    AppSpacing.sm, context.horizontalGutter, AppSpacing.sm),
                child: SearchField(
                  hintText: l10n.learningSearchHint,
                  onChanged: controller.setSearch,
                ),
              ),
              Expanded(
                child: profileAsync.when(
                  loading: () => const StatusView.loading(),
                  error: (_, __) => StatusView.error(
                    message: l10n.learningSaveFailed,
                    onRetry: () => ref.invalidate(learningProfileProvider),
                  ),
                  data: (profile) =>
                      _Body(profile: profile, query: query.trim()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile, required this.query});

  final LearningProfile profile;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(learningControllerProvider.notifier);
    final searching = query.isNotEmpty;

    // Per-category items, filtered by the search query when present.
    final matchIds = searching
        ? profile.search(query).map((i) => i.id).toSet()
        : const <String>{};

    List<LearningInterest> itemsFor(LearningCategory c) {
      final all = profile.byCategory(c);
      return searching
          ? all.where((i) => matchIds.contains(i.id)).toList(growable: false)
          : all;
    }

    if (searching && matchIds.isEmpty) {
      return StatusView.empty(
        icon: Icons.search_off_rounded,
        title: l10n.learningNoResults,
      );
    }

    if (!searching && profile.isEmpty) {
      // Still render the category cards (each with an add button) beneath a hint.
      return ListView(
        padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.xs,
            context.horizontalGutter, AppSpacing.xl),
        children: [
          _Intro(title: l10n.learningEmptyTitle, body: l10n.learningEmptyBody),
          const SizedBox(height: AppSpacing.md),
          for (final c in LearningCategory.values)
            InterestCategoryCard(
              category: c,
              items: itemsFor(c),
              onAdd: () => InterestEditorSheet.show(context, category: c),
              onEdit: (i) =>
                  InterestEditorSheet.show(context, category: c, existing: i),
              onDelete: controller.deleteInterest,
            ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.xs,
          context.horizontalGutter, AppSpacing.xl),
      children: [
        for (final c in LearningCategory.values)
          if (!searching || itemsFor(c).isNotEmpty)
            InterestCategoryCard(
              category: c,
              items: itemsFor(c),
              onAdd: () => InterestEditorSheet.show(context, category: c),
              onEdit: (i) =>
                  InterestEditorSheet.show(context, category: c, existing: i),
              onDelete: controller.deleteInterest,
            ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(body,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.4)),
      ],
    );
  }
}

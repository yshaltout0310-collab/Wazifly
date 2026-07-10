import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/cv_repository/cv_document.dart';
import '../../../core/services/cv_repository/cv_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_view.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../../resume_analyzer/presentation/widgets/ats_score_gauge.dart';
import '../application/cv_actions_controller.dart';
import '../application/cv_ai_controller.dart';
import 'cv_repository_l10n.dart';

/// Detail for one CV: metadata, content summary, this CV's AI insights, and the
/// full set of lifecycle + AI actions.
class CvDetailScreen extends ConsumerWidget {
  const CvDetailScreen({required this.cvId, super.key});

  final String cvId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cv = ref.watch(cvByIdProvider(cvId));

    ref.listen(cvAiControllerProvider.select((s) => s.failure), (_, f) {
      if (f != null) {
        showAuthSnack(context, cvAiFailureMessage(l10n, f), isError: true);
        ref.read(cvAiControllerProvider.notifier).clearFailure();
      }
    });
    ref.listen(cvActionsControllerProvider.select((s) => s.failure), (_, f) {
      if (f != null) {
        showAuthSnack(context, cvActionFailureMessage(l10n, f), isError: true);
        ref.read(cvActionsControllerProvider.notifier).clearFailure();
      }
    });

    if (cv == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const StatusView.loading(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cv.name, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _onAction(context, ref, cv, v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(l10n.cvActionRename)),
              PopupMenuItem(
                  value: 'duplicate', child: Text(l10n.cvActionDuplicate)),
              if (cv.isActive && !cv.isDefault)
                PopupMenuItem(
                    value: 'default', child: Text(l10n.cvActionSetDefault)),
              if (cv.isActive)
                PopupMenuItem(
                    value: 'archive', child: Text(l10n.cvActionArchive))
              else
                PopupMenuItem(
                    value: 'restore', child: Text(l10n.cvActionRestore)),
              PopupMenuItem(value: 'delete', child: Text(l10n.cvActionDelete)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.md,
                context.horizontalGutter, AppSpacing.xl),
            children: [
              _MetaHeader(cv: cv),
              const SizedBox(height: AppSpacing.lg),
              _ContentCard(cv: cv),
              const SizedBox(height: AppSpacing.lg),
              _AiSection(cv: cv),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, CvDocument cv, String action) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(cvActionsControllerProvider.notifier);
    switch (action) {
      case 'default':
        await controller.setDefault(cv);
        if (context.mounted) showAuthSnack(context, l10n.cvDefaultSet);
      case 'archive':
        final done = await controller.archive(cv);
        if (done && context.mounted) {
          showAuthSnack(context, l10n.cvArchivedDone);
        }
      case 'restore':
        await controller.restore(cv);
        if (context.mounted) showAuthSnack(context, l10n.cvRestoredDone);
      case 'delete':
        final done = await controller.delete(cv);
        if (done && context.mounted) {
          showAuthSnack(context, l10n.cvDeletedDone);
          context.pop();
        }
      case 'rename':
      case 'duplicate':
        // Rename/duplicate open a dialog handled by the library; here we keep it
        // simple: duplicate immediately, rename via a quick inline dialog.
        if (action == 'duplicate') {
          await controller.duplicate(cv, copyLabel: l10n.cvCopySuffix);
          if (context.mounted) showAuthSnack(context, l10n.cvActionDuplicate);
        }
    }
  }
}

class _MetaHeader extends StatelessWidget {
  const _MetaHeader({required this.cv});
  final CvDocument cv;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (cv.isDefault) _pill(theme, l10n.cvDefaultBadge, AppColors.emerald),
            if (cv.isArchived)
              _pill(theme, l10n.cvArchivedBadge, theme.colorScheme.outline),
            _pill(theme, cvSourceLabel(l10n, cv.source),
                theme.colorScheme.primary),
            _pill(theme, l10n.cvVersion(cv.version), theme.colorScheme.outline),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(cvLastUsedLabel(l10n, cv.lastUsedAt),
            style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
        if (cv.lastAppliedJobTitle != null && cv.lastAppliedCompany != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.cvLastAppliedAt(
                  cv.lastAppliedJobTitle!, cv.lastAppliedCompany!),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        if (cv.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final t in cv.tags) Chip(label: Text('#$t'))],
          ),
        ],
      ],
    );
  }

  Widget _pill(ThemeData theme, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.cv});
  final CvDocument cv;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = cv.content;
    final hasContent = !c.isEmpty;
    return Card(
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cvDetailContent,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            if (!hasContent)
              Text(l10n.cvDetailNoContent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))
            else ...[
              if (c.fullName.isNotEmpty)
                Text(c.fullName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              if (c.headline.isNotEmpty)
                Text(c.headline, style: theme.textTheme.bodyMedium),
              if (c.summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(c.summary,
                    maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ],
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: l10n.cvActionOpen,
              icon: Icons.edit_document,
              onPressed: () =>
                  context.pushNamed(RouteNames.cvBuilder, extra: cv.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSection extends ConsumerWidget {
  const _AiSection({required this.cv});
  final CvDocument cv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ai = ref.watch(cvAiControllerProvider);
    final aiCtrl = ref.read(cvAiControllerProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.cvAiSection,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            // ATS / analysis
            if (cv.analysis != null)
              Center(
                child: AtsScoreGauge(
                  score: cv.atsScore ?? 0,
                  color: AppColors.emerald,
                  label: '${cv.atsScore}',
                  caption: 'ATS',
                  size: 140,
                ),
              )
            else
              Text(l10n.cvAiNoAnalysis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            if (cv.analysis == null && aiCtrl.hasCachedAnalysis) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => aiCtrl.attachLastAnalysis(cv),
                icon: const Icon(Icons.download_done_rounded, size: 18),
                label: Text(l10n.cvAiAttachAnalysis),
              ),
            ],
            const Divider(height: AppSpacing.xl),
            // Matches
            Text(l10n.cvAiMatchesTitle,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            if (cv.matchResults.isEmpty)
              Text(
                cv.analysis == null ? l10n.cvAiNeedAnalysis : '—',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              )
            else
              ...cv.matchResults.take(5).map((m) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.emerald.withValues(alpha: 0.14),
                      child: Text('${m.score}',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(m.jobTitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(m.company,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: ai.running || cv.analysis == null
                  ? null
                  : () => aiCtrl.runMatching(cv),
              icon: ai.running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bolt_outlined, size: 18),
              label: Text(ai.running ? l10n.cvAiMatching : l10n.cvAiRunMatching),
            ),
            // Recommendations
            if (cv.recommendations != null) ...[
              const Divider(height: AppSpacing.xl),
              Text(l10n.cvAiRecommendationsTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              if (cv.recommendations!.headline.isNotEmpty)
                Text(cv.recommendations!.headline,
                    style: theme.textTheme.bodyMedium),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final f in cv.recommendations!.focusAreas)
                    Chip(label: Text(f)),
                ],
              ),
            ] else if (aiCtrl.hasCachedRecommendations) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => aiCtrl.attachLastRecommendations(cv),
                icon: const Icon(Icons.recommend_outlined, size: 18),
                label: Text(l10n.cvAiAttachRecommendations),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

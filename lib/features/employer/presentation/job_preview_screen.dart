import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/job_posting.dart';
import '../../../shared/widgets/job_detail_view.dart';
import '../application/employer_jobs_controller.dart';
import 'employer_jobs_l10n.dart';

/// Renders a posting exactly as a job seeker will see it (via the shared
/// [JobDetailView] over [JobPosting.toJob]), with a "Preview" banner and — when
/// the posting can be published — a Publish CTA behind a confirmation dialog.
/// Reached from the editor's Publish flow and from Preview actions.
class JobPreviewScreen extends ConsumerWidget {
  const JobPreviewScreen({required this.posting, super.key});

  final JobPosting posting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    ref.listen(employerJobsControllerProvider, (prev, next) {
      final failure = next.failure;
      if (failure != null && failure != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(jobsActionFailureMessage(l10n, failure)),
          ));
        ref.read(employerJobsControllerProvider.notifier).clearFailure();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.jobPreview)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _PreviewBanner(text: l10n.jobPreviewBanner),
            Expanded(
              child: ResponsiveCenter(
                maxWidth: 640,
                child: JobDetailView(job: posting.toJob()),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: posting.isPublishable
          ? _PublishBar(
              onPublish: () => _confirmAndPublish(context, ref),
            )
          : null,
    );
  }

  Future<void> _confirmAndPublish(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.jobPublishConfirmTitle),
        content: Text(l10n.jobPublishConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.jobUnsavedCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.jobPublishConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(employerJobsControllerProvider.notifier).publish(posting);
    if (!context.mounted) return;
    if (ref.read(employerJobsControllerProvider).failure != null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.jobPublished),
      ));
    // Reset to the My Jobs list (back returns to the employer dashboard).
    context.goNamed(RouteNames.employerJobs);
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PublishBar extends StatelessWidget {
  const _PublishBar({required this.onPublish});
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.sm,
          context.horizontalGutter, AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPublish,
            icon: const Icon(Icons.publish_rounded, size: 20),
            label: Text(l10n.jobPublish),
          ),
        ),
      ),
    );
  }
}

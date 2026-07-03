import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/applications/in_memory_applications_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/application.dart';
import '../application/applications_controller.dart';
import 'widgets/status_chip.dart';
import 'widgets/status_timeline.dart';

/// One application: current status, a status-history timeline, mock status
/// controls, and links to the job and the Career Coach (for interview prep).
class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({required this.applicationId, super.key});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(applicationByIdProvider(applicationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appsDetailTitle),
        actions: [
          if (app != null)
            IconButton(
              tooltip: l10n.appsWithdraw,
              onPressed: () => _confirmWithdraw(context, ref, app),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: app == null
            ? Center(
                child: Text(l10n.appsNotFound,
                    style: Theme.of(context).textTheme.bodyLarge))
            : _Body(app: app),
      ),
    );
  }

  Future<void> _confirmWithdraw(
      BuildContext context, WidgetRef ref, Application app) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.appsWithdraw),
        content: Text(l10n.appsWithdrawConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.appsWithdraw)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(applicationsRepositoryProvider).withdraw(app.id);
    if (context.mounted) context.pop();
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.app});
  final Application app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ResponsiveCenter(
      maxWidth: 640,
      child: ListView(
        padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.lg,
            context.horizontalGutter, AppSpacing.xl),
        children: [
          Text(app.jobTitle,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${app.company} · ${app.location}',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusChip(status: app.status)),
          const SizedBox(height: AppSpacing.lg),

          // Mock status controls
          _SectionTitle(l10n.appsUpdateStatus),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final status in ApplicationStatus.values)
                ChoiceChip(
                  label: Text(applicationStatusLabel(l10n, status)),
                  selected: app.status == status,
                  onSelected: (_) => ref
                      .read(applicationsRepositoryProvider)
                      .updateStatus(app.id, status),
                  selectedColor:
                      applicationStatusColor(status).withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: app.status == status
                        ? AppColors.emeraldDark
                        : theme.colorScheme.onSurface,
                  ),
                ),
            ],
          ),

          if (app.status == ApplicationStatus.interview) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => context.pushNamed(
                  RouteNames.careerCoach,
                  extra: l10n.appsInterviewCoachSeed(app.jobTitle, app.company),
                ),
                icon: const Icon(Icons.psychology_outlined, size: 20),
                label: Text(l10n.appsPrepareInterview),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.appsHistory),
          const SizedBox(height: AppSpacing.md),
          StatusTimeline(history: app.history),

          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(RouteNames.jobDetail,
                pathParameters: {'id': app.jobId}),
            icon: const Icon(Icons.work_outline_rounded, size: 20),
            label: Text(l10n.appsViewJob),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      );
}

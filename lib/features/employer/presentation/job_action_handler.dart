import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/models/job_posting.dart';
import '../application/employer_jobs_controller.dart';
import 'job_actions.dart';

/// Runs a [JobAction] for [job] — navigation for edit/preview/publish,
/// confirmation dialogs for the destructive/lifecycle actions, then delegates to
/// the optimistic [EmployerJobsController]. Shared by the My Jobs list tiles and
/// the job detail screen so both behave identically. Lifecycle failures surface
/// via the controller's `failure` (each screen listens); success shows a
/// localized snackbar here.
Future<void> runJobAction(
  BuildContext context,
  WidgetRef ref,
  JobPosting job,
  JobAction action,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(employerJobsControllerProvider.notifier);

  switch (action) {
    case JobAction.edit:
      context.pushNamed(RouteNames.editJob, pathParameters: {'id': job.id});
    case JobAction.preview:
    case JobAction.publish:
      // Publishing is confirmed on the preview screen (how seekers see it).
      context.pushNamed(RouteNames.jobPreview, extra: job);
    case JobAction.reopen:
      if (await _confirm(context, l10n.jobActionReopen,
          l10n.jobPublishConfirmBody, l10n.jobPublishConfirmCta)) {
        await controller.reopen(job);
        if (!context.mounted) return;
        _reportSuccess(context, ref, l10n.jobReopenedMsg);
      }
    case JobAction.close:
      // Closing is reversible (Reopen), so no confirmation is needed.
      await controller.close(job);
      if (!context.mounted) return;
      _reportSuccess(context, ref, l10n.jobClosedMsg);
    case JobAction.archive:
      final reason = await _archiveDialog(context, l10n);
      if (reason != null) {
        await controller.archive(job, reason: reason.isEmpty ? null : reason);
        if (!context.mounted) return;
        _reportSuccess(context, ref, l10n.jobArchivedMsg);
      }
    case JobAction.duplicate:
      await controller.duplicate(job);
      if (!context.mounted) return;
      _reportSuccess(context, ref, l10n.jobDuplicated);
    case JobAction.delete:
      if (await _confirm(context, l10n.jobDeleteConfirmTitle,
          l10n.jobDeleteConfirmBody, l10n.jobActionDelete,
          destructive: true)) {
        await controller.softDelete(job);
        if (!context.mounted) return;
        _reportSuccess(context, ref, l10n.jobDeletedMsg);
      }
  }
}

/// Shows the success message only when the optimistic action did not roll back
/// (a failure is surfaced by each screen's `ref.listen`).
void _reportSuccess(BuildContext context, WidgetRef ref, String message) {
  if (ref.read(employerJobsControllerProvider).failure != null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(message),
    ));
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String body,
  String confirmLabel, {
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: theme.colorScheme.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Archive dialog with an optional reason. Returns the reason (possibly empty)
/// when confirmed, or null when cancelled.
Future<String?> _archiveDialog(BuildContext context, AppLocalizations l10n) =>
    showDialog<String>(
      context: context,
      builder: (context) => const _ArchiveReasonDialog(),
    );

/// A stateful dialog that owns its [TextEditingController] so the controller is
/// disposed only after the route is fully removed (via [State.dispose]) — not
/// synchronously after `showDialog` returns, which would let the exit animation
/// touch a disposed controller.
class _ArchiveReasonDialog extends StatefulWidget {
  const _ArchiveReasonDialog();

  @override
  State<_ArchiveReasonDialog> createState() => _ArchiveReasonDialogState();
}

class _ArchiveReasonDialogState extends State<_ArchiveReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.jobArchiveTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.jobArchiveReasonHint),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.jobUnsavedCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.jobActionArchive),
        ),
      ],
    );
  }
}

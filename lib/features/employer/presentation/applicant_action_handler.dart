import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/application.dart';
import '../application/employer_applicants_controller.dart';
import 'applicant_actions.dart';

/// Runs an [ApplicantAction] for [app] — confirmation / reject-reason dialogs,
/// then the optimistic [EmployerApplicantsController]. Shared by the applicants
/// list and the detail screen. Failures surface via each screen's `ref.listen`;
/// success shows a localized snackbar here. Mirrors `runJobAction`.
Future<void> runApplicantAction(
  BuildContext context,
  WidgetRef ref,
  Application app,
  ApplicantAction action,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(employerApplicantsControllerProvider.notifier);

  switch (action) {
    case ApplicantAction.review:
      await controller.moveToReview(app);
      if (!context.mounted) return;
      _report(context, ref, l10n.applicantMovedReview);
    case ApplicantAction.interview:
      await controller.moveToInterview(app);
      if (!context.mounted) return;
      _report(context, ref, l10n.applicantMovedInterview);
    case ApplicantAction.accept:
      if (await _confirm(context, l10n.applicantAcceptTitle,
          l10n.applicantAcceptBody, l10n.applicantActionAccept)) {
        await controller.accept(app);
        if (!context.mounted) return;
        _report(context, ref, l10n.applicantAccepted);
      }
    case ApplicantAction.reject:
      final reason = await _rejectDialog(context, l10n);
      if (reason != null) {
        await controller.reject(app, reason: reason.isEmpty ? null : reason);
        if (!context.mounted) return;
        _report(context, ref, l10n.applicantRejected);
      }
    case ApplicantAction.reopen:
      if (await _confirm(context, l10n.applicantReopenTitle,
          l10n.applicantReopenBody, l10n.applicantActionReopen)) {
        await controller.reopen(app);
        if (!context.mounted) return;
        _report(context, ref, l10n.applicantReopened);
      }
  }
}

void _report(BuildContext context, WidgetRef ref, String message) {
  if (ref.read(employerApplicantsControllerProvider).failure != null) return;
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
  String confirmLabel,
) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.jobUnsavedCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Reject dialog with an optional private reason. Returns the reason (possibly
/// empty) when confirmed, or null when cancelled.
Future<String?> _rejectDialog(BuildContext context, AppLocalizations l10n) =>
    showDialog<String>(
      context: context,
      builder: (context) => const _RejectReasonDialog(),
    );

/// The controller is owned by a [StatefulWidget] so it is disposed only after the
/// route unmounts (never during the exit animation) — the M2 dialog bug.
class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
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
      title: Text(l10n.applicantRejectTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 2,
        decoration: InputDecoration(hintText: l10n.applicantRejectReasonHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.jobUnsavedCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.applicantActionReject),
        ),
      ],
    );
  }
}

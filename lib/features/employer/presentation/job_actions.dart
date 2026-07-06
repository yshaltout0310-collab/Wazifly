import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/job_posting.dart';
import '../domain/job_status.dart';

/// The owner actions offered for a posting (drives both the list-tile overflow
/// menu and the detail screen's action buttons).
enum JobAction { edit, preview, publish, reopen, archive, close, duplicate, delete }

extension JobActionL10n on JobAction {
  String label(AppLocalizations l10n) => switch (this) {
        JobAction.edit => l10n.jobActionEdit,
        JobAction.preview => l10n.jobActionPreview,
        JobAction.publish => l10n.jobActionPublish,
        JobAction.reopen => l10n.jobActionReopen,
        JobAction.archive => l10n.jobActionArchive,
        JobAction.close => l10n.jobActionClose,
        JobAction.duplicate => l10n.jobActionDuplicate,
        JobAction.delete => l10n.jobActionDelete,
      };

  IconData get icon => switch (this) {
        JobAction.edit => Icons.edit_outlined,
        JobAction.preview => Icons.visibility_outlined,
        JobAction.publish => Icons.publish_rounded,
        JobAction.reopen => Icons.restart_alt_rounded,
        JobAction.archive => Icons.archive_outlined,
        JobAction.close => Icons.lock_outline_rounded,
        JobAction.duplicate => Icons.copy_all_outlined,
        JobAction.delete => Icons.delete_outline_rounded,
      };

  bool get isDestructive => this == JobAction.delete;
}

/// The ordered, status-aware set of actions available for [job]. Publish vs.
/// Reopen is chosen by current status (both transition to `published`, but read
/// differently to the user). Delete is always last.
List<JobAction> availableJobActions(JobPosting job) {
  final actions = <JobAction>[JobAction.edit, JobAction.preview];

  // A published transition reads as "Publish" from a draft, "Reopen" otherwise.
  if (job.status.canTransitionTo(JobStatus.published)) {
    actions.add(
        job.status == JobStatus.draft ? JobAction.publish : JobAction.reopen);
  }
  if (job.status.canTransitionTo(JobStatus.archived)) {
    actions.add(JobAction.archive);
  }
  if (job.status.canTransitionTo(JobStatus.closed)) {
    actions.add(JobAction.close);
  }
  actions.add(JobAction.duplicate);
  actions.add(JobAction.delete);
  return actions;
}

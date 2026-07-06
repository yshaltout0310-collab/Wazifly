import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/application.dart';
import '../domain/applicant_status_flow.dart';

/// The pipeline actions an employer can take on an applicant. Drives the detail
/// action bar and the tile overflow menu (mirrors `job_actions.dart`).
enum ApplicantAction { review, interview, accept, reject, reopen }

extension ApplicantActionL10n on ApplicantAction {
  String label(AppLocalizations l10n) => switch (this) {
        ApplicantAction.review => l10n.applicantActionReview,
        ApplicantAction.interview => l10n.applicantActionInterview,
        ApplicantAction.accept => l10n.applicantActionAccept,
        ApplicantAction.reject => l10n.applicantActionReject,
        ApplicantAction.reopen => l10n.applicantActionReopen,
      };

  IconData get icon => switch (this) {
        ApplicantAction.review => Icons.visibility_outlined,
        ApplicantAction.interview => Icons.event_available_outlined,
        ApplicantAction.accept => Icons.check_circle_outline_rounded,
        ApplicantAction.reject => Icons.cancel_outlined,
        ApplicantAction.reopen => Icons.restart_alt_rounded,
      };

  bool get isPrimary => this == ApplicantAction.accept;
  bool get isDestructive => this == ApplicantAction.reject;
}

/// The status-aware set of actions available for [status], derived from the pure
/// [ApplicantStatusFlow]. A `→ reviewed` transition reads as **Reopen** from a
/// terminal status, **Move to Review** otherwise.
List<ApplicantAction> availableApplicantActions(ApplicationStatus status) {
  final next = status.allowedNext;
  final actions = <ApplicantAction>[];
  if (next.contains(ApplicationStatus.reviewed)) {
    actions.add(status.isTerminal ? ApplicantAction.reopen : ApplicantAction.review);
  }
  if (next.contains(ApplicationStatus.interview)) {
    actions.add(ApplicantAction.interview);
  }
  if (next.contains(ApplicationStatus.accepted)) {
    actions.add(ApplicantAction.accept);
  }
  if (next.contains(ApplicationStatus.rejected)) {
    actions.add(ApplicantAction.reject);
  }
  return actions;
}

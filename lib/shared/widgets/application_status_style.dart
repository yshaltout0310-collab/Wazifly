import 'package:flutter/material.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../models/application.dart';

/// Shared visual language for [ApplicationStatus] — label, color, and icon —
/// used by both the seeker Applications Center and the employer Applicants
/// Management (promoted from the applications feature so neither imports the
/// other).

/// Localized display name for an application status.
String applicationStatusLabel(AppLocalizations l10n, ApplicationStatus s) =>
    switch (s) {
      ApplicationStatus.pending => l10n.statusPending,
      ApplicationStatus.reviewed => l10n.statusReviewed,
      ApplicationStatus.interview => l10n.statusInterview,
      ApplicationStatus.accepted => l10n.statusAccepted,
      ApplicationStatus.rejected => l10n.statusRejected,
    };

/// Brand-aligned color per status.
Color applicationStatusColor(ApplicationStatus s) => switch (s) {
      ApplicationStatus.pending => const Color(0xFF6B7280), // slate
      ApplicationStatus.reviewed => AppColors.teal,
      ApplicationStatus.interview => AppColors.warning,
      ApplicationStatus.accepted => AppColors.emerald,
      ApplicationStatus.rejected => AppColors.error,
    };

IconData applicationStatusIcon(ApplicationStatus s) => switch (s) {
      ApplicationStatus.pending => Icons.hourglass_empty_rounded,
      ApplicationStatus.reviewed => Icons.visibility_outlined,
      ApplicationStatus.interview => Icons.event_available_outlined,
      ApplicationStatus.accepted => Icons.check_circle_rounded,
      ApplicationStatus.rejected => Icons.cancel_outlined,
    };

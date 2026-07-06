import '../../../shared/models/application.dart';

/// Pure, Flutter-free transition rules for the employer applicant pipeline —
/// mirrors `JobStatus.allowedNext`. The employer moves an applicant forward
/// (Review → Interview → Accept/Reject) and may reopen a terminal decision back
/// to Review. Every move **appends** to the application history (never replaces).
extension ApplicantStatusFlow on ApplicationStatus {
  /// Statuses this one may transition to via an employer action.
  Set<ApplicationStatus> get allowedNext => switch (this) {
        ApplicationStatus.pending => const {
            ApplicationStatus.reviewed,
            ApplicationStatus.interview,
            ApplicationStatus.accepted,
            ApplicationStatus.rejected,
          },
        ApplicationStatus.reviewed => const {
            ApplicationStatus.interview,
            ApplicationStatus.accepted,
            ApplicationStatus.rejected,
          },
        ApplicationStatus.interview => const {
            ApplicationStatus.accepted,
            ApplicationStatus.rejected,
          },
        // Terminal decisions can be reopened to Review.
        ApplicationStatus.accepted => const {ApplicationStatus.reviewed},
        ApplicationStatus.rejected => const {ApplicationStatus.reviewed},
      };

  bool canMoveTo(ApplicationStatus next) => allowedNext.contains(next);

  bool get isTerminal =>
      this == ApplicationStatus.accepted || this == ApplicationStatus.rejected;
}

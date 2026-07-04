/// Whether a company has been reviewed/verified by the platform.
///
/// Firestore-ready now (round-trips on the [Company] model) but intentionally has
/// **no UI in Milestone 1** — a future admin/verification flow flips it. Defaults
/// to [pending] for missing/unknown values.
enum CompanyVerificationStatus {
  pending,
  verified,
  rejected;

  static CompanyVerificationStatus fromName(Object? value) {
    if (value is! String) return CompanyVerificationStatus.pending;
    final normalized = value.trim().toLowerCase();
    for (final status in CompanyVerificationStatus.values) {
      if (status.name == normalized) return status;
    }
    return CompanyVerificationStatus.pending;
  }
}

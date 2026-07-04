/// Stable, backend-agnostic failure reasons for company edits, mapped to a
/// localized message in the presentation layer.
enum CompanyFailure {
  notSignedIn,
  saveFailed,
  logoUploadFailed,
  unknown,
}

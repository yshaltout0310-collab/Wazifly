/// Stable, backend-agnostic failure reasons for profile edits, mapped to a
/// localized message in the presentation layer.
enum ProfileFailure {
  notSignedIn,
  saveFailed,
  photoUploadFailed,
  photoPickCancelled,
  unknown,
}

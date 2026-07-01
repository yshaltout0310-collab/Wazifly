/// Errors from the job-matching pipeline that are *not* AI errors (AI failures
/// use `AiException`). Carries a stable, localizable [code].
enum JobMatchErrorCode {
  /// No jobs were available to match against.
  noJobs,
}

class JobMatchingException implements Exception {
  const JobMatchingException(this.code, [this.rawMessage]);

  final JobMatchErrorCode code;
  final String? rawMessage;

  @override
  String toString() => 'JobMatchingException(${code.name}): $rawMessage';
}

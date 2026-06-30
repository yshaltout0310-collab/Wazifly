/// The two roles a user can take in Career Bridge.
enum UserType {
  jobSeeker,
  employer;

  static UserType? fromName(String? value) {
    for (final t in UserType.values) {
      if (t.name == value) return t;
    }
    return null;
  }
}

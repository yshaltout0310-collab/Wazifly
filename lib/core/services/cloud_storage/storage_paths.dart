/// Canonical Cloud Storage object paths, in one place to avoid stringly-typed
/// drift (mirrors `RouteNames`). These paths are authorized by `storage.rules`
/// (`users/{uid}/**` owner-only; `companies/{companyId}/**` owner-write).
abstract final class StoragePaths {
  StoragePaths._();

  static String profilePhoto(String uid) => 'users/$uid/profile.jpg';
  static String resume(String uid, String fileName) =>
      'users/$uid/resumes/$fileName';
  static String companyLogo(String companyId) =>
      'companies/$companyId/logo.jpg';
}

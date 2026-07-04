import 'package:careerbridge/features/auth/application/auth_providers.dart';
import 'package:careerbridge/features/auth/domain/auth_repository.dart';
import 'package:careerbridge/shared/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory [AuthRepository] for widget tests.
///
/// The real [FirebaseAuthRepository] touches `FirebaseAuth.instance`, which
/// throws without a live Firebase app, so every test overrides
/// [authRepositoryProvider] with this fake.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.changePasswordError});

  /// The "signed-in" user surfaced by [currentUser] / [authStateChanges].
  final AppUser? user;

  /// When set, [changePassword] throws this (used to exercise failure paths).
  final Object? changePasswordError;

  /// Records the last [changePassword] arguments for assertions.
  ({String current, String next})? lastPasswordChange;

  /// Records the last [updateProfile] arguments for assertions.
  ({String? displayName, String? photoUrl})? lastProfileUpdate;

  static const _fakeUser = AppUser(
    uid: 'test-uid',
    method: AuthMethod.email,
    email: 'test@careerbridge.app',
    displayName: 'Test User',
  );

  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.value(user);

  @override
  AppUser? get currentUser => user;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _fakeUser;

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      _fakeUser;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AppUser> signInWithGoogle() async => _fakeUser;

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneCodeSent onCodeSent,
    required PhoneVerificationFailed onFailed,
    PhoneAutoVerified? onAutoVerified,
  }) async =>
      onCodeSent('test-verification-id');

  @override
  Future<AppUser> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async =>
      _fakeUser.copyWithPhone(phoneNumber: '+97412345678');

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastPasswordChange = (current: currentPassword, next: newPassword);
    if (changePasswordError != null) throw changePasswordError!;
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    lastProfileUpdate = (displayName: displayName, photoUrl: photoUrl);
  }

  @override
  Future<void> signOut() async {}
}

extension on AppUser {
  AppUser copyWithPhone({required String phoneNumber}) => AppUser(
        uid: uid,
        method: AuthMethod.phone,
        email: email,
        phoneNumber: phoneNumber,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}

/// Riverpod override that swaps in the fake auth repository.
Override fakeAuthOverride({AppUser? user}) =>
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(user: user));

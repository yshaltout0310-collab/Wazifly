import 'package:equatable/equatable.dart';

/// How a user authenticated. Useful for UI hints and analytics.
enum AuthMethod { email, phone }

/// App-level user model, decoupled from Firebase's `User` so the rest of the
/// app never imports the SDK directly.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.method,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  final String uid;
  final AuthMethod method;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;

  /// Whether the account's email address has been verified. Email/password
  /// sign-in is gated on this: the app blocks access until it is true.
  final bool emailVerified;

  /// Best label to greet the user with.
  String get label =>
      displayName?.trim().isNotEmpty == true
          ? displayName!
          : email ?? phoneNumber ?? 'there';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'method': method.name,
        'email': email,
        'phoneNumber': phoneNumber,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'emailVerified': emailVerified,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        method: AuthMethod.values.firstWhere(
          (m) => m.name == json['method'],
          orElse: () => AuthMethod.email,
        ),
        email: json['email'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        emailVerified: json['emailVerified'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [uid, method, email, phoneNumber, displayName, emailVerified];
}

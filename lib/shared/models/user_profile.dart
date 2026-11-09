import 'package:equatable/equatable.dart';

import '../../features/profile/domain/experience_level.dart';
import '../../features/user_type/domain/user_type.dart';

/// The set of profile attributes tracked by the completion indicator. The UI
/// maps each entry to a localized label when nudging the user to fill gaps.
enum ProfileField {
  displayName,
  photo,
  headline,
  location,
  bio,
  role,
  skills,
  experienceLevel,
  preferredJobTitles,
  links,
}

/// Extended, app-owned user profile persisted at `users/{uid}` in Firestore.
///
/// This is intentionally decoupled from [AppUser] (the auth identity): identity
/// comes from Firebase Auth, while this holds the richer, user-editable data.
/// All fields beyond [uid] are optional and feed the completion indicator, and
/// the résumé-adjacent fields ([skills], [experienceLevel], [preferredJobTitles])
/// are shaped to be reused by AI features and a future Employer Dashboard.
class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.headline,
    this.location,
    this.bio,
    this.userType,
    this.skills = const [],
    this.experienceLevel,
    this.preferredJobTitles = const [],
    this.portfolioUrl,
    this.githubUrl,
    this.linkedinUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String? displayName;

  /// Self-declared contact number in E.164 form, collected at sign-up.
  ///
  /// NOT the same thing as [AppUser.phoneNumber], which Firebase Auth only sets
  /// for a number that has been **verified** by SMS and linked to the account.
  /// This one is contact information the user typed; it is deliberately not
  /// promoted to the auth identity.
  ///
  /// Not part of [missingFields]/[completion]: adding an eleventh tracked field
  /// would move every existing user's completion percentage, which is a
  /// separate decision from collecting the number.
  final String? phoneNumber;

  final String? photoUrl;
  final String? headline;
  final String? location;
  final String? bio;
  final UserType? userType;

  /// Skills the seeker claims (reused by Job Matching / recommendations).
  final List<String> skills;

  /// Declared seniority band.
  final ExperienceLevel? experienceLevel;

  /// Roles the seeker is targeting (reused by recommendations / employer search).
  final List<String> preferredJobTitles;

  final String? portfolioUrl;
  final String? githubUrl;
  final String? linkedinUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// An empty profile carrying only the identity key.
  factory UserProfile.empty(String uid) => UserProfile(uid: uid);

  bool get hasAnyLink =>
      _isFilled(portfolioUrl) || _isFilled(githubUrl) || _isFilled(linkedinUrl);

  /// Fields the user still hasn't filled, in display order.
  List<ProfileField> get missingFields => [
        if (!_isFilled(displayName)) ProfileField.displayName,
        if (!_isFilled(photoUrl)) ProfileField.photo,
        if (!_isFilled(headline)) ProfileField.headline,
        if (!_isFilled(location)) ProfileField.location,
        if (!_isFilled(bio)) ProfileField.bio,
        if (userType == null) ProfileField.role,
        if (skills.isEmpty) ProfileField.skills,
        if (experienceLevel == null) ProfileField.experienceLevel,
        if (preferredJobTitles.isEmpty) ProfileField.preferredJobTitles,
        if (!hasAnyLink) ProfileField.links,
      ];

  /// Completion ratio in `[0, 1]` across all tracked [ProfileField]s.
  double get completion {
    const total = 10; // must match the count in [missingFields]
    final filled = total - missingFields.length;
    return filled / total;
  }

  /// Completion as a rounded percentage `[0, 100]`.
  int get completionPercent => (completion * 100).round();

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? headline,
    String? location,
    String? bio,
    UserType? userType,
    List<String>? skills,
    ExperienceLevel? experienceLevel,
    List<String>? preferredJobTitles,
    String? portfolioUrl,
    String? githubUrl,
    String? linkedinUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      userType: userType ?? this.userType,
      skills: skills ?? this.skills,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      preferredJobTitles: preferredJobTitles ?? this.preferredJobTitles,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes the user-editable fields (identity/timestamps are managed by
  /// the repository, so `createdAt`/`updatedAt` are written there via server
  /// timestamps and omitted here).
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoUrl': photoUrl,
        'headline': headline,
        'location': location,
        'bio': bio,
        'userType': userType?.name,
        'skills': skills,
        'experienceLevel': experienceLevel?.name,
        'preferredJobTitles': preferredJobTitles,
        'portfolioUrl': portfolioUrl,
        'githubUrl': githubUrl,
        'linkedinUrl': linkedinUrl,
      };

  /// Defensive parse: tolerates snake_case keys, missing/mistyped fields, and
  /// list-or-comma-string encodings so partial Firestore docs never throw.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String? str(String camel, [String? snake]) {
      final v = json[camel] ?? (snake != null ? json[snake] : null);
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return UserProfile(
      uid: str('uid') ?? '',
      displayName: str('displayName', 'display_name'),
      phoneNumber: str('phoneNumber', 'phone_number'),
      photoUrl: str('photoUrl', 'photo_url'),
      headline: str('headline'),
      location: str('location'),
      bio: str('bio'),
      userType: UserType.fromName(str('userType', 'user_type')),
      skills: _stringList(json['skills']),
      experienceLevel:
          ExperienceLevel.fromName(json['experienceLevel'] ?? json['experience_level']),
      preferredJobTitles: _stringList(
          json['preferredJobTitles'] ?? json['preferred_job_titles']),
      portfolioUrl: str('portfolioUrl', 'portfolio_url'),
      githubUrl: str('githubUrl', 'github_url'),
      linkedinUrl: str('linkedinUrl', 'linkedin_url'),
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      updatedAt: _date(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static bool _isFilled(String? value) => value != null && value.trim().isNotEmpty;

  /// Accepts a `List`, a comma-separated `String`, or null; trims, drops blanks,
  /// and de-duplicates while preserving order.
  static List<String> _stringList(Object? value) {
    Iterable<String> raw;
    if (value is List) {
      raw = value.map((e) => e.toString());
    } else if (value is String) {
      raw = value.split(',');
    } else {
      return const [];
    }
    final seen = <String>{};
    final out = <String>[];
    for (final item in raw) {
      final t = item.trim();
      if (t.isEmpty) continue;
      if (seen.add(t.toLowerCase())) out.add(t);
    }
    return List.unmodifiable(out);
  }

  /// Tolerates ISO strings, epoch millis, and Firestore `Timestamp`-like objects
  /// (which expose `toDate()`), returning null for anything unrecognized.
  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic dynamicValue = value;
      final result = dynamicValue.toDate();
      if (result is DateTime) return result;
    } catch (_) {/* not a Timestamp */}
    return null;
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        phoneNumber,
        photoUrl,
        headline,
        location,
        bio,
        userType,
        skills,
        experienceLevel,
        preferredJobTitles,
        portfolioUrl,
        githubUrl,
        linkedinUrl,
      ];
}

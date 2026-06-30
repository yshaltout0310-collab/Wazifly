import 'package:equatable/equatable.dart';

/// Immutable description of a country for the picker.
class CountryModel extends Equatable {
  const CountryModel({
    required this.isoCode,
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  /// ISO 3166-1 alpha-2 code, e.g. `QA`.
  final String isoCode;

  /// English display name, e.g. "Qatar".
  final String name;

  /// International dialing code including `+`, e.g. "+974".
  final String dialCode;

  /// Emoji flag, e.g. 🇶🇦. Emoji avoids bundling image assets per country.
  final String flag;

  /// Serializes for persistence (SharedPreferences / Firestore later).
  Map<String, dynamic> toJson() => {
        'isoCode': isoCode,
        'name': name,
        'dialCode': dialCode,
        'flag': flag,
      };

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        isoCode: json['isoCode'] as String,
        name: json['name'] as String,
        dialCode: json['dialCode'] as String,
        flag: json['flag'] as String,
      );

  @override
  List<Object?> get props => [isoCode];
}

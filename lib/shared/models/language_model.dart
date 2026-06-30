import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Immutable description of a supported (or future) UI language.
///
/// [textDirection] drives RTL/LTR layout. Adding a new language is just adding
/// a new [LanguageModel] entry plus its `app_<code>.arb` file — no architecture
/// change required.
class LanguageModel extends Equatable {
  const LanguageModel({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.textDirection,
    this.isSupported = true,
  });

  /// ISO 639-1 language code, e.g. `en`, `ar`.
  final String code;

  /// Name in English, e.g. "Arabic".
  final String englishName;

  /// Name in its own script, e.g. "العربية".
  final String nativeName;

  /// Reading direction for this language.
  final TextDirection textDirection;

  /// Whether translations currently ship for this language. Unsupported
  /// languages can still be listed under "More Languages".
  final bool isSupported;

  Locale get locale => Locale(code);

  @override
  List<Object?> get props => [code];
}
